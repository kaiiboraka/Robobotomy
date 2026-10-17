class_name FallState
extends PlayerState
## Falling state for the player

func physics_process(delta: float) -> void:
	var input_direction_x := Input.get_axis("Player_Move_Left", "Player_Move_Right")
	player.velocity.x = player.speed * input_direction_x
	player.velocity.y -= player.gravity * delta
	player.velocity.z = 0
	player.move_and_slide()

	if player.is_on_floor():
		if is_equal_approx(input_direction_x, 0.0):
			finished.emit(IDLE)
		else:
			finished.emit(WALKING)
