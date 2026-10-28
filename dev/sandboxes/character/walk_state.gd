class_name WalkState
extends PlayerState
## Walking state for the player

## PlayerStateMachine calls physics_process each physics frame
func physics_process(delta: float) -> void:
	var input_direction_x := Input.get_axis("Player_Move_Left", "Player_Move_Right")
	player.velocity.x = player.speed * input_direction_x
	player.velocity.y -= player.gravity * delta
	player.velocity += player.get_platform_velocity()
	player.velocity.z = 0
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_just_pressed("Player_Jump"):
		finished.emit(JUMPING)
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
