class_name Arm 
extends BodyPart
## Object for the arm


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_part_enabled or not accepts_player_input:
		return

	# Unified movement and jumping
	handle_movement(state)
	handle_jump(state)
