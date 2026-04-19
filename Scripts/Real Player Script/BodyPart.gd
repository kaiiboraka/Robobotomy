@abstract class_name BodyPart extends RigidBody3D

signal hit_ground

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

@export var retract_speed = 5.0
@export_range(0,3,1) var weight: int = 1;

var is_part_enabled: bool = true
## When false, this part ignores player move/jump (still simulates if enabled and unfrozen).
var accepts_player_input: bool = true
var is_detached: bool = false
var is_retracting: bool = false
var starting_position: Vector3
var starting_rotation: Vector3
var core : Node3D


func _ready():
	starting_position = position;
	starting_rotation = rotation;
	# Ensure we can detect collisions for the hit_ground signal
	contact_monitor = true;
	max_contacts_reported = 4;
	
	if is_part_enabled:
		enable_part();
	else:
		disable_part();


func _physics_process(_delta):
	if is_detached and not is_part_enabled:
		# Rigid contact list can be empty while sleeping or for a frame; RayCast3D is the reliable fallback.
		var landed := false;
		for body in get_colliding_bodies():
			if counts_as_ground_for_limb(body):
				landed = true;
				break;
		if not landed:
			var ray := get_node_or_null("RayCast3D") as RayCast3D;
			if ray != null and ray.enabled:
				ray.force_raycast_update();
				if ray.is_colliding():
					var col := ray.get_collider();
					if counts_as_ground_for_limb(col):
						landed = true;
		if landed:
			hit_ground.emit();


func on_select():
	pass;


func deselect():
	pass;


func set_accepts_player_input(enabled: bool) -> void:
	accepts_player_input = enabled;
	set_process_input(enabled);


func counts_as_ground_for_limb(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false;
	if body is StaticBody3D or body is AnimatableBody3D or body is GridMap:
		return true;
	if body is RigidBody3D:
		return (body as RigidBody3D).freeze;
	return false;


func enable_part():
	is_part_enabled = true;
	top_level = true;
	freeze = false;
	can_sleep = true;
	set_process(true);
	set_physics_process(true);
	set_accepts_player_input(true);


func disable_part():
	is_part_enabled = false;
	# During retract, stay top_level until the tween finishes (caller keeps global_position valid).
	if not is_retracting:
		top_level = is_detached; # Keep world space if detached
	freeze = true if not is_detached else false; # don't move if attached
	set_process(false);
	set_physics_process(true); # Keep physics for gravity/collision if detached
	set_accepts_player_input(false);


func throw(impulse: Vector3):
	is_detached = true;
	freeze = false;
	top_level = true;
	# Sleeping bodies often stop populating get_colliding_bodies(); stay awake until we land.
	can_sleep = false;
	set_physics_process(true);
	apply_central_impulse(impulse);


func retract():
	is_retracting = true;
	var initial_global_pos = global_position;
	# Mark attached before disable_part so freeze stays on during the tween (was still detached).
	is_detached = false;
	disable_part();
	top_level = true; # Keep in world space during flight
	
	var target_start = core.global_transform * starting_position;
	var dist = initial_global_pos.distance_to(target_start);
	var duration = dist / retract_speed;
	if duration <= 0: duration = 0.01;
	
	var initial_rot = rotation;
	var move_tween = create_tween();
	move_tween.set_parallel(true);
	
	# Tween position
	move_tween.tween_method(
		func(t): global_position = initial_global_pos.lerp(core.global_transform * starting_position, t)
		, 0.0, 1.0, duration
	);
	
	# Tween rotation
	move_tween.tween_property(self, "rotation", starting_rotation, duration / 2);
	
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
