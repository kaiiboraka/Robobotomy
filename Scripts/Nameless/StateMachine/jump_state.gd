extends PlayerState
class_name JumpState

func enter(previous_state_path: String, data := {}) -> void:
	player.velocity.y = player.jump_impulse
	#player.animation_player.play("jump")

func physics_process(delta: float) -> void:
	var input_direction_x := Input.get_axis("Player_Move_Left", "Player_Move_Right")
	player.velocity.x = player.speed * input_direction_x
	player.velocity.y -= player.gravity * delta
	player.velocity.z = 0;
	player.move_and_slide()

	if player.velocity.y <= 0:
		finished.emit(FALLING)
