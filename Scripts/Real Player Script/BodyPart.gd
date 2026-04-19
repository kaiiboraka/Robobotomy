@abstract class_name BodyPart extends RigidBody3D

signal hit_ground

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

@export var retract_speed = 5.0
@export_range(0,3,1) var weight: int = 1;

var is_part_enabled: bool = true
var is_detached: bool = false
var starting_position : Vector3
var core : Node3D

func _ready():
	starting_position = position;
	# Ensure we can detect collisions for the hit_ground signal
	contact_monitor = true;
	max_contacts_reported = 4;
	
	if is_part_enabled:
		enable_part();
	else:
		disable_part();

func _physics_process(_delta):
	if is_detached and not is_part_enabled:
		# If we are thrown but not yet enabled, check if we've hit the ground
		var bodies = get_colliding_bodies();
		if bodies.size() > 0:
			for body in bodies:
				# Simple check for ground
				if body is StaticBody3D or body is GridMap:
					hit_ground.emit();
					break;

func on_select():
	pass;

func deselect():
	pass;

func enable_part():
	is_part_enabled = true;
	top_level = true;
	freeze = false;
	set_process(true);
	set_physics_process(true);
	set_process_input(true);

func disable_part():
	is_part_enabled = false;
	top_level = is_detached; # Keep world space if detached
	freeze = true if not is_detached else false; # don't move if attached
	set_process(false);
	set_physics_process(true); # Keep physics for gravity/collision if detached
	set_process_input(false);

func throw(impulse: Vector3):
	is_detached = true;
	freeze = false;
	top_level = true;
	set_physics_process(true);
	apply_central_impulse(impulse);

func retract():
	var initial_global_pos = global_position;
	disable_part();
	top_level = true; # Keep in world space during flight
	is_detached = false;
	
	var target_start = core.global_transform * starting_position;
	var dist = initial_global_pos.distance_to(target_start);
	var duration = dist / retract_speed;
	if duration <= 0: duration = 0.01;
	
	var move_tween = create_tween();
	# Tween a factor from 0 to 1 and lerp global_position to track the moving core
	move_tween.tween_method(
		func(t): global_position = initial_global_pos.lerp(core.global_transform * starting_position, t)
		, 0.0, 1.0, duration
	);
	
	move_tween.finished.connect(
		func():
			top_level = false;
			position = starting_position;
			freeze = true;
			set_physics_process(false);
	);
	return move_tween;
