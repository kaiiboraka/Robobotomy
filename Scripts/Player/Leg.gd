class_name Leg extends BodyPart

@export var speed: float = 5.0;
@export var acceleration: float = 20.0;


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_part_enabled or not accepts_player_input:
		return;

	# Horizontal movement
	var input_dir := Input.get_axis("Player_Move_Left", "Player_Move_Right");
	if input_dir != 0:
		wake_up();
		
	var target_vel := input_dir * speed;
	state.linear_velocity.x = lerp(state.linear_velocity.x, target_vel, state.step * acceleration);

	# Unified jumping
	handle_jump();
