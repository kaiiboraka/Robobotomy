# NOTE: This script is just to help translate GDScript code into eventual C#. It doesn't carry any 
# actual implementation that is useful.

extends CharacterBody3D


func enter_pipe() -> void:
	var inPipe = true
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
func exit_pipe() -> void:
	var inPipe = false
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
func standard_movement(inputDir: Vector2) -> Vector3:
	var speed = 1 #NOT IN ACTUAL SCRIPT
	var _velocity: Vector3 = velocity
	var direction: Vector3 = Vector3(inputDir.x, 0, 0) * transform.basis
	if direction != Vector3.ZERO:
		_velocity.x = direction.x * speed
	else:
		_velocity.x = move_toward(_velocity.x, 0, speed)
	return _velocity
func pipe_movement(inputDir: Vector2) -> Vector3:
	var speed = 1 #NOT IN ACTUAL SCRIPT
	var _velocity: Vector3 = velocity
	var direction: Vector3 = Vector3(inputDir.x, inputDir.y, 0) * transform.basis
	if direction != Vector3.ZERO:
		_velocity.x = direction.x * speed
		_velocity.y = direction.y * speed
	else:
		_velocity.x = move_toward(_velocity.x, 0, speed)
		_velocity.y = move_toward(_velocity.y, 0, speed)
	return _velocity
	
