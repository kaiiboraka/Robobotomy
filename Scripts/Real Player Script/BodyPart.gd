@abstract
class_name BodyPart
extends RigidBody3D

signal hit_ground

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

@export var retract_speed = 5.0
@export var stabilize_delay: float = 0.5

var is_stabilizing: bool = false
var is_stabilized: bool = false
var _stabilize_timer: float = 0.0
var is_part_enabled: bool = true
var is_detached: bool = false
var starting_position : Vector3
var core : Node3D

@onready var stable_collider: CollisionShape3D = %StableCollider if has_node("%StableCollider") else null

func _ready():
	starting_position = position
	# Ensure we can detect collisions for the hit_ground signal
	contact_monitor = true
	max_contacts_reported = 4
	
	if stable_collider:
		stable_collider.disabled = true
	
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
				# Simple check for ground
				if body is StaticBody3D or body is GridMap:
					hit_ground.emit()
					break

func on_select():
	pass

func deselect():
	pass

func stabilize_upright(delta: float, velocity_threshold: float = 0.5):
	if not is_part_enabled or is_stabilizing or is_stabilized:
		_stabilize_timer = 0.0
		return

	# Check if we are moving slowly enough to start the timer
	if linear_velocity.length() < velocity_threshold and abs(angular_velocity.z) < velocity_threshold:
		_stabilize_timer += delta
		if _stabilize_timer < stabilize_delay:
			return

		# Check if we are already mostly upright
		if abs(rotation.z) < 0.05:
			rotation.z = 0
			angular_velocity.z = 0
			_stabilize_timer = 0.0
			if stable_collider: stable_collider.disabled = false
			return

		is_stabilizing = true
		lock_rotation = true
		
		# Calculate vertical offset to prevent clipping for oblong shapes
		var initial_rot = rotation.z
		var initial_y = global_position.y
		
		var upright_tween = create_tween()
		upright_tween.set_parallel(true)
		upright_tween.set_ease(Tween.EASE_IN_OUT)
		upright_tween.set_trans(Tween.TRANS_ELASTIC)
		
		# Tween rotation
		upright_tween.tween_property(self, "rotation:z", 0.0, 0.65)
		
		# Simultaneously lift the body to clear the ground based on rotation
		# We use tween_method to calculate the 'lift' needed as we rotate
		upright_tween.tween_method(
			func(t: float):
				if not is_instance_valid(self): return
				# Use a simple capsule height approximation: 
				# as we move from sideways (PI/2) to upright (0), the height increases
				# This is a heuristic to push the body up as it rotates
				var current_rot = lerp(initial_rot, 0.0, t)
				# Push up slightly if we are rotating from a flat position
				var lift = (abs(sin(initial_rot)) - abs(sin(current_rot))) * 0.5;
				if lift > 0: 
					global_position.y = initial_y + lift,
			 0.0, 1.0, 0.5
		)

		upright_tween.finished.connect(
			func():
				angular_velocity.z = 0;
				lock_rotation = false;
				is_stabilizing = false;
				is_stabilized = true;
				_stabilize_timer = 0.0;
				if stable_collider: stable_collider.disabled = false
		)
	else:
		is_stabilized = false;
		_stabilize_timer = 0.0
		if stable_collider: stable_collider.disabled = true

func wake_up():
	sleeping = false;	
	is_stabilized = false;
	pass

func enable_part():
	is_part_enabled = true
	top_level = true
	freeze = false
	set_process(true)
	set_physics_process(true)
	set_process_input(true)

func disable_part():
	is_part_enabled = false
	top_level = is_detached # Keep world space if detached
	freeze = false if is_detached else true
	set_process(false)
	set_physics_process(true) # Keep physics for gravity/collision if detached
	set_process_input(false)
	if stable_collider: stable_collider.disabled = true

func throw(impulse: Vector3):
	is_detached = true
	freeze = false
	top_level = true
	set_physics_process(true)
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
			freeze = true
			set_physics_process(false)
	)
	return move_tween
