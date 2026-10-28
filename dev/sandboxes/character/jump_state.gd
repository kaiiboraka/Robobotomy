class_name JumpState
extends PlayerState
## Jump state for the player

## Called by PlayerStateMachine each physics frame
func physics_process(delta: float) -> void:
	var input_direction_x := Input.get_axis( 
		"Player_Move_Left", "Player_Move_Right" 
	)
	player.velocity.x = player.speed * input_direction_x
	player.velocity.y -= player.gravity * delta
	player.velocity.z = 0
	player.move_and_slide()

	if player.velocity.y <= 0:
		finished.emit(FALLING)

## Called by PlayerStateMachine when Jump State enters the state machine
func enter(_previous_state_path: String, _data := {}) -> void:
	player.velocity.y = player.jump_impulse
