class_name IdleState
extends PlayerState
## Idle state for the player

## Custom method override:[br]
## PlayerStateMachine calls this method on IdleState
## each physics frame
func physics_process(_delta: float) -> void:
	player.velocity.z = 0
	player.velocity += player.get_platform_velocity()
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_just_pressed("Player_Jump"):
		finished.emit(JUMPING)
	elif Input.is_action_pressed("Player_Move_Left") \
		 or Input.is_action_pressed("Player_Move_Right"):
		finished.emit(WALKING)

## PlayerStateMachine calls this method when IdleState
## enters the state machine
func enter(_previous_state_path: String, _data := {}) -> void:
	player.velocity.x = 0.0

## PlayerStateMachine calls this method when IdleState
## leaves the state machine
func exit() -> void:
	pass
