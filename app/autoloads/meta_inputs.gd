class_name MetaInputsType
extends Node

## Minimum speed the game can process
const TIME_SCALE_STEPS_MIN: int = -10
## Maximum speed the game can process
const TIME_SCALE_STEPS_MAX: int = 10
## The game's current processing speed
var _time_scale_steps: int = 0


func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"Game_Quit"):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit(0)
	
	if Input.is_action_just_pressed(&"Window_Fullscreen"):
		if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if Input.is_action_just_pressed(&"Game_speed_up"): 
		_time_scale_steps = clampi(_time_scale_steps + 1, TIME_SCALE_STEPS_MIN, TIME_SCALE_STEPS_MAX)
		_update_time_scale()
	
	if Input.is_action_just_pressed(&"Game_slow_down"): 
		_time_scale_steps = clampi(_time_scale_steps - 1, TIME_SCALE_STEPS_MIN, TIME_SCALE_STEPS_MAX)
		_update_time_scale()

	if Input.is_action_just_pressed(&"Game_speed_reset"): 
		_time_scale_steps = 0
		_update_time_scale()
	
	if Input.is_action_just_pressed(&"Debug_Mouse_Toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		elif Input.mouse_mode == Input.MOUSE_MODE_CONFINED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Updates the game's processing speed
func _update_time_scale() -> void:
	if _time_scale_steps > 0:
		Engine.time_scale = 1 + (.5 * _time_scale_steps)
	elif _time_scale_steps < 0:
		Engine.time_scale = (pow(.8, -_time_scale_steps))
	else: 
		Engine.time_scale = 1

## Toggles collision shape visibility (in game)
func _toggle_collision_shape_visibility() -> void:
	var tree := get_tree()
	tree.debug_collisions_hint = not tree.debug_collisions_hint

	# Traverse tree to call queue_redraw on instances of
	# CollisionShape2D and CollisionPolygon2D.
	var node_stack: Array[Node] = [tree.get_root()]
	while not node_stack.is_empty():
		var node: Node = node_stack.pop_back()
		if is_instance_valid(node):
			if node is CollisionShape2D or node is CollisionPolygon2D:
				node.queue_redraw()
			node_stack.append_array(node.get_children())
		
