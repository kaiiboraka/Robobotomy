@tool 
extends SpotLight3D 

@export var cameraOrSource: bool
@export var camera : Camera3D
@export var source_array : Array[Node3D] = []
@export var orbitTarget : Node3D 
@export var orbitDistance : float 
@export var towardsSource: bool

@export_range(0.1, 20.0) var smooth_speed: float = 5.0 

func _process(delta):
	if not orbitTarget:
		return
	
	var obj_pos = orbitTarget.global_position
	var source_pos: Vector3
	
#finding source
	if cameraOrSource:
		if not camera: return
		source_pos = camera.global_position
	else:
		if source_array.is_empty(): return
		var closest_node = source_array[0]
		for node in source_array:
			if node and node.global_position.distance_to(obj_pos) < closest_node.global_position.distance_to(obj_pos):
				closest_node = node
		source_pos = closest_node.global_position

	# (The vector from the object to where the light wants to be)
	var target_dir: Vector3
	if towardsSource:
		target_dir = (source_pos - obj_pos).normalized()
	else:
		target_dir = (obj_pos - source_pos).normalized()
	
	var current_dir = (global_position - obj_pos).normalized()
	
	if current_dir.is_zero_approx():
		current_dir = Vector3.BACK 

	# This moves the vector along an arc instead of a straight line
	var next_dir = current_dir.slerp(target_dir, delta * smooth_speed)
	
	global_position = obj_pos + (next_dir * orbitDistance)
	
	
	look_at(obj_pos)
