class_name Arm extends BodyPart

@export var speed: float = 5.0;
@export var acceleration: float = 20.0;
@export var jump_velocity: float = 5.0;


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_part_enabled or not accepts_player_input:
		return;

	var input_dir := Input.get_axis("Player_Move_Left", "Player_Move_Right");
	var target_vel := input_dir * speed;
	state.linear_velocity.x = lerp(state.linear_velocity.x, target_vel, state.step * acceleration);

	# Jumping
	if Input.is_action_just_pressed("Player_Jump"):
		var landed := false;
		for body in get_colliding_bodies():
			if counts_as_ground_for_limb(body):
				landed = true;
				break;
		
		if landed:
			apply_central_impulse(Vector3.UP * jump_velocity);
