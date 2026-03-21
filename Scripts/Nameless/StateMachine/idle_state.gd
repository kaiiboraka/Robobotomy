extends PlayerState
class_name IdleState

func enter(previous_state_path: String, data := {}) -> void:
	player.velocity.x = 0.0
	#player.animation_player.play("idle")

func physics_process(_delta: float) -> void:
	player.velocity.z = 0;
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_just_pressed("Player_Jump"):
		finished.emit(JUMPING)
	elif Input.is_action_pressed("Player_Move_Left") or Input.is_action_pressed("Player_Move_Right"):
		finished.emit(WALKING)
		
func exit() -> void:
	pass
