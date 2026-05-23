extends Node

const time_scale_steps_MIN = -10;
var time_scale_steps = 0;
const time_scale_steps_MAX = 10;

#var debugManager : DebugManager;
#
#func _ready() -> void:
	#debugManager = DebugManager;
	#pass

func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(_event: InputEvent) -> void:
	if (Input.is_action_just_pressed(&"Game_Quit")):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST);
		get_tree().quit(0);
	
	if (Input.is_action_just_pressed(&"Window_Fullscreen")):
		if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	#if (Input.is_action_just_released(&"Debug_HUD")):
		#DebugManager.ToggleVisibility();
	
	#if (Input.is_action_just_pressed(&"Debug_Collisions")):
		#toggle_collision_shape_visibility();
	
	#if (Input.is_action_just_pressed(&"Debug_Camera_Lock")):
		#get_tree().call_group(&"Camera", &"ToggleCameraLock");
	
	#if (Input.is_action_just_pressed(&"Debug_Camera_Visibility")):
		#toggle_camera_influence_visibility();
	
	if Input.is_action_just_pressed(&"Game_speed_up"): 
		time_scale_steps = clampi(time_scale_steps + 1, time_scale_steps_MIN, time_scale_steps_MAX);
		_update_time_scale();
	
	if Input.is_action_just_pressed(&"Game_slow_down"): 
		time_scale_steps = clampi(time_scale_steps - 1, time_scale_steps_MIN, time_scale_steps_MAX);
		_update_time_scale();

	if Input.is_action_just_pressed(&"Game_speed_reset"): 
		time_scale_steps = 0;
		_update_time_scale();
	
	#if Input.is_action_just_pressed(&"Game_switch_player"): 
		#GameWorldManager.SwitchPlayers();
	
	if Input.is_action_just_pressed(&"Debug_Mouse_Toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		elif Input.mouse_mode == Input.MOUSE_MODE_CONFINED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _update_time_scale():
	if time_scale_steps > 0:
		Engine.time_scale = 1 + (.5 * time_scale_steps);
	elif time_scale_steps < 0:
		Engine.time_scale = (pow(.8, -time_scale_steps));
	else: 
		Engine.time_scale = 1;


#func toggle_camera_influence_visibility() -> void:
	#Globals_GD.toggle_show_debug();


func toggle_collision_shape_visibility() -> void:
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
		
