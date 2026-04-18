@abstract class_name BodyPart
extends RigidBody3D

signal hit_ground

@export var retract_speed = 5.0

var is_part_enabled: bool = true
var is_detached: bool = false
var starting_position : Vector3
var core : Node3D

func _ready():
	starting_position = position
	# Ensure we can detect collisions for the hit_ground signal
	contact_monitor = true
	max_contacts_reported = 4
	
	if is_part_enabled:
		enable_part()
	else:
		disable_part()

func _physics_process(_delta):
	if is_detached and not is_part_enabled:
		# If we are thrown but not yet enabled, check if we've hit the ground
		var bodies = get_colliding_bodies()
		if bodies.size() > 0:
			for body in bodies:
				# Simple check for ground - can be refined with layers or groups
				if body is StaticBody3D or body is GridMap:
					hit_ground.emit()
					break

func enable_part():
	is_part_enabled = true
	freeze = false
	top_level = true
	set_process(true)
	set_physics_process(true)
	set_process_input(true)

func disable_part():
	is_part_enabled = false
	freeze = true
	top_level = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)

func throw(impulse: Vector3):
	is_detached = true
	# We enable physics but not necessarily controls yet
	freeze = false
	top_level = true
	apply_central_impulse(impulse)

func retract():
	var initial_global_pos = global_position
	disable_part()
	top_level = true # Keep in world space during flight
	is_detached = false
	
	var target_start = core.global_transform * starting_position
	var dist = initial_global_pos.distance_to(target_start)
	var duration = dist / retract_speed
	if duration <= 0: duration = 0.01
	
	var move_tween = create_tween()
	# Tween a factor from 0 to 1 and lerp global_position to track the moving core
	move_tween.tween_method(
		func(t): global_position = initial_global_pos.lerp(core.global_transform * starting_position, t)
		, 0.0, 1.0, duration
	)
	
	move_tween.finished.connect(
		func():
			top_level = false
			position = starting_position
	)
	return move_tween
