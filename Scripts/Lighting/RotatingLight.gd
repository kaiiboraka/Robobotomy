@tool
extends SpotLight3D 

@export var cameraOrSource: bool 
@export var camera : Camera3D 
@export var source_array: Array[LightSource] = [] 
@export var orbitTarget : Player # the player
@export var orbitDistance : float = 5.0 # default can be changed if we have problems
@export var towardsSource: bool 
@export var isworking: String 
@export_range(0.01, 1.0) var speed: float = 0.1 

var _last_node_count: int = 0 

func _ready() -> void:
	if Engine.is_editor_hint():
		findLights()
	set_process(true)

func findByClass(node: Node, result: Array) -> void: 
	if not is_instance_valid(node):
		return
	if node is LightSource: 
		result.push_back(node) 
	for child in node.get_children(): 
		findByClass(child, result) 

func findLights() -> void: 
	if not is_inside_tree():
		return
		
	var res: Array = [] 
	var scene_root: Node = null
	
	if Engine.is_editor_hint():
		scene_root = get_tree().edited_scene_root
	else:
		scene_root = get_tree().current_scene

	if not scene_root:
		scene_root = get_node_or_null("/root") 

	if scene_root: 
		findByClass(scene_root, res) 
	
	source_array.clear()
	for light in res:
		if is_instance_valid(light):
			source_array.append(light)
			
	_last_node_count = get_tree().get_node_count()

func _process(_delta: float) -> void: 
	if not orbitTarget: 
		return 
		
	var obj_pos: Vector3 = orbitTarget.global_position 

	if "selected_limb" in orbitTarget: #this area only starts working once the game begins, thanks to a bug godot has where we cannot pull these variables in the editor
		if orbitTarget.selected_limb != null:
			obj_pos = orbitTarget.selected_limb.global_position
		else:
			obj_pos = orbitTarget.torso.global_position
	else:
		obj_pos.y += 3.0
		#print("target does not have property 'selected_limb', maybe you havent selected player?")
	var source_pos: Vector3 = Vector3.ZERO 
	
	if not cameraOrSource: 
		if not camera: 
			return 
		source_pos = camera.global_position 
		light_color = Color.WHITE 
	else: 
		var needs_refresh: bool = false
		
		# Checking for deleted lights
		for light in source_array:
			if not is_instance_valid(light):
				needs_refresh = true
				break
				
		# Checking for new lights 
		if get_tree().get_node_count() != _last_node_count:
			needs_refresh = true
			
		if source_array.is_empty() or needs_refresh: 
			findLights() 
			if source_array.is_empty():
				return 
			
		var closest_light: LightSource = null
		var closest_distance: float = -1.0
		
		# Find the closest light
		for light in source_array: 
			if not is_instance_valid(light): 
				continue 
			var distance: float = obj_pos.distance_to(light.global_position) 
			if closest_distance < 0.0 or distance < closest_distance: 
				closest_distance = distance 
				closest_light = light 
				
		# color and position
		if is_instance_valid(closest_light):
			# Use .get() to ask Godot for the color, bypassing the Nil cache error
			var c = closest_light.get("color")
			if c != null and typeof(c) != TYPE_NIL:
				light_color = c
			else:
				light_color = Color.WHITE
				
			source_pos = closest_light.global_position 
		else:
			return

	if obj_pos.is_equal_approx(source_pos):
		return
		
	var ideal_direction: Vector3 = (source_pos - obj_pos).normalized()
	if towardsSource:
		ideal_direction = (obj_pos - source_pos).normalized()
		
	var current_direction: Vector3 = (global_position - obj_pos).normalized()
	if current_direction.is_zero_approx():
		current_direction = ideal_direction # Fallback if perfectly overlapping
		
	var weight: float = clamp(speed * _delta * 60, 0.0, 1.0)
	var blended_direction: Vector3 = current_direction.slerp(ideal_direction, weight).normalized()
	
	var target_pos: Vector3 = obj_pos + (blended_direction * orbitDistance)
	
	global_position = target_pos
	

	var look_dir = (obj_pos - global_position).normalized()
	var safe_up = Vector3.UP
	if look_dir.abs().is_equal_approx(Vector3(0, 1, 0)):
		safe_up = Vector3.RIGHT 
		
	var target_transform = global_transform.looking_at(obj_pos, safe_up)
	global_transform = global_transform.interpolate_with(target_transform, weight)
