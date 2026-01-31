@tool
extends SpotLight3D

@export var cameraOrSource: bool
@export var camera : Camera3D#
@export var source_array : Array[Node3D] = []
@export var orbitTarget : Node3D #torus
@export var orbitDistance : float #how far the light should be
@export var towardsSource: bool
#rim light: towards source is off. camera or source is camera
#main cell light: towards source is on, source is array

func _process(_delta):
	var obj_pos = orbitTarget.global_position
	#if not camera or not orbitTarget:
	#	return
	if not camera:
		if cameraOrSource:
			return #if there is no camera but theres supposed to be nothing will happen
	var closest_node
	if not source_array:
		if not cameraOrSource:
			return #if there is no source array but its not on camera nothing will happen 
	else: #iterate through all the array
		closest_node = source_array[0]
		for node in source_array:
			if node:
				if abs(closest_node-obj_pos) > abs(node-obj_pos):
					closest_node = node
	
	# 1. Get the direction from the cameraor source  to the object
	var source_pos
	if cameraOrSource:
		source_pos = camera.global_position
	else:
		if closest_node:
			source_pos = closest_node.global_position
		else:
			print("there has been an error")
	var direction = (obj_pos - source_pos).normalized()
	if towardsSource :
		global_position = obj_pos - (direction * orbitDistance)
	else:
	# 2. Set the light's position on the opposite side
	# It is the target's position + the same vector direction
		global_position = obj_pos + (direction * orbitDistance)
	
	# 3. Ensure the light actually faces the object (if it's a Spot/Directional light)
	look_at(obj_pos)
