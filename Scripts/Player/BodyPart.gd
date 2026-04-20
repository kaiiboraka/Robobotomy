@abstract class_name BodyPart extends RigidBody3D

signal hit_ground;

@export var retract_speed: float = 10.0;
@export var throw_force: float = 40.0;
@export var speed: float = 5.0;
@export var acceleration: float = 20.0;
@export var jump_velocity: float = 5.0;
@export_range(0, 3, 1) var weight: int = 1;

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D;

var is_part_enabled: bool = true;
## When false, this part ignores player move/jump (still simulates if enabled and unfrozen).
var accepts_player_input: bool = true;
var is_detached: bool = false;
var is_retracting: bool = false;
var starting_position: Vector3;
var starting_rotation: Vector3;
var starting_transform: Transform3D;
var core: Node3D;


func _ready() -> void:
	starting_position = position;
	starting_rotation = rotation;
	starting_transform = transform;
	# Ensure we can detect collisions for the hit_ground signal
	contact_monitor = true;
	max_contacts_reported = 4;
	
	if is_part_enabled:
		enable_part();
	else:
		disable_part();


func _physics_process(_delta: float) -> void:
	if is_detached and not is_part_enabled:
		if is_grounded():
			hit_ground.emit();


func on_select() -> void:
	pass;


func deselect() -> void:
	pass;


func enable_part() -> void:
	is_part_enabled = true;
	top_level = true;
	freeze = false;
	can_sleep = true;
	set_process(true);
	set_physics_process(true);
	set_accepts_player_input(true);


func disable_part() -> void:
	is_part_enabled = false;
	# During retract, stay top_level until the tween finishes (caller keeps global_position valid).
	if not is_retracting:
		top_level = is_detached; # Keep world space if detached
	
	freeze = true if not is_detached else false; # don't move if attached
	set_process(false);
	set_physics_process(true); # Keep physics for gravity/collision if detached
	set_accepts_player_input(false);


func throw(impulse: Vector3) -> void:
	is_detached = true;
	freeze = false;
	top_level = true;
	# Sleeping bodies often stop populating get_colliding_bodies(); stay awake until we land.
	can_sleep = false;
	set_physics_process(true);
	apply_central_impulse(impulse);


func drop() -> void:
	is_detached = true;
	freeze = false;
	top_level = true;
	can_sleep = false;
	set_physics_process(true);


func retract() -> Tween:
	is_retracting = true;
	var initial_global_pos = global_position;
	var initial_quat = global_transform.basis.get_rotation_quaternion();
	var original_scale = global_transform.basis.get_scale();

	# Mark attached before disable_part so freeze stays on during the tween.
	is_detached = false;
	disable_part();
	top_level = true; # Keep in world space during flight

	var target_world_pos = core.global_transform * starting_position;
	var dist = initial_global_pos.distance_to(target_world_pos);
	var duration = dist / retract_speed;
	if duration <= 0: duration = 0.01;

	var move_tween = create_tween();
	move_tween.set_parallel(true);
	move_tween.set_ease(Tween.EASE_OUT);
	move_tween.set_trans(Tween.TRANS_SPRING);
	move_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS);

	# Position tween (dynamic tracking of moving core)
	move_tween.tween_method(
		func(t): 
			if not is_instance_valid(core): return;
			var current_target = core.global_transform * starting_position;
			global_position = initial_global_pos.lerp(current_target, t), 
		0.0, 1.0, duration
	);

	# Rotation tween (dynamic tracking of core rotation)
	move_tween.tween_method(
		func(t):
			if not is_instance_valid(core): return;
			var parent_quat = core.global_transform.basis.get_rotation_quaternion();
			var target_quat = parent_quat * Quaternion.from_euler(starting_rotation);
			global_transform.basis = Basis(initial_quat.slerp(target_quat, t)).scaled(original_scale), 
		0.0, 1.0, duration
	);

	move_tween.finished.connect(
		func():
			top_level = false;
			linear_velocity = Vector3.ZERO;
			angular_velocity = Vector3.ZERO;
			position = starting_position;
			rotation = starting_rotation;
			freeze = true;
			set_physics_process(false);
			is_retracting = false;
	);
	
	return move_tween;


func handle_movement(state: PhysicsDirectBodyState3D) -> void:
	var input_dir := Input.get_axis("Player_Move_Left", "Player_Move_Right");
	if input_dir != 0:
		wake_up();
	
	var target_vel := input_dir * speed;
	state.linear_velocity.x = lerp(state.linear_velocity.x, target_vel, state.step * acceleration);


func handle_jump() -> void:
	if Input.is_action_just_pressed("Player_Jump") and is_grounded():
		wake_up();
		apply_central_impulse(Vector3.UP * jump_velocity);


func wake_up() -> void:
	sleeping = false;


func is_grounded() -> bool:
	for body in get_colliding_bodies():
		if counts_as_ground_for_limb(body):
			return true;
	
	var ray := get_node_or_null("RayCast3D") as RayCast3D;
	if ray and ray.is_colliding():
		if counts_as_ground_for_limb(ray.get_collider()):
			return true;
			
	return false;


func set_accepts_player_input(enabled: bool) -> void:
	accepts_player_input = enabled;
	set_process_input(enabled);
	if enabled:
		wake_up();


func counts_as_ground_for_limb(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false;
	if body is StaticBody3D or body is AnimatableBody3D or body is GridMap:
		return true;
	if body is RigidBody3D:
		return (body as RigidBody3D).freeze;
	return false;
