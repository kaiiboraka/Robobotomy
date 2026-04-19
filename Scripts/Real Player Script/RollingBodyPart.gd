@abstract
class_name RollingBodyPart extends BodyPart

@export var roll_speed = 7.0;
@export var jump_force = 10.0;
@export var max_angular_velocity = 12.0;
@export var stabilize_threshold = 5.0;

@onready var ray_cast_3d: RayCast3D = $RayCast3D;
@onready var stable_collider: CollisionShape3D = %StableCollider;

var is_stabilizing: bool = false;
var is_stabilized: bool = false;
var _stabilize_timer: float = 0.0;

func _ready():
	super._ready();
	# Constrain movement and rotation for 2.5D gameplay.
	axis_lock_linear_z = true;
	axis_lock_angular_x = true;
	axis_lock_angular_y = true;
	
	stable_collider.disabled = true;

func _physics_process(delta: float):
	if not is_part_enabled:
		return;

	# Enable/disable rotation based on children or state.
	if should_roll():
		lock_rotation = false;
		# Enable/disable rotation based on attached limbs.
		if ray_cast_3d:
			ray_cast_3d.rotation = -rotation;

		# Auto-stabilize when no movement input is given
		if not Input.is_action_pressed("Player_Move_Right") and not Input.is_action_pressed("Player_Move_Left"):
			stabilize_upright(delta, stabilize_threshold);
	else:
		lock_rotation = true;

func should_roll() -> bool:
	return true;

func _input(event: InputEvent) -> void:
	if not is_part_enabled:
		return;
		
	if event.is_action("Player_Jump") or event.is_action("Player_Move_Right") or event.is_action("Player_Move_Left"):
		wake_up();

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if not is_part_enabled or lock_rotation:
		return;
		
	var torque = Vector3.ZERO;
	var current_ang_vel = state.angular_velocity.z;
	
	if Input.is_action_just_pressed("Player_Jump") and ray_cast_3d and ray_cast_3d.is_colliding():
		wake_up();
		apply_central_force(Vector3.UP * jump_force);
	
	# Apply torque for moving right, respecting the velocity cap.
	if Input.is_action_pressed("Player_Move_Right") and current_ang_vel > -max_angular_velocity:
		wake_up();
		torque.z -= roll_speed;
			
	# Apply torque for moving left, respecting the velocity cap.
	if Input.is_action_pressed("Player_Move_Left") and current_ang_vel < max_angular_velocity:
		wake_up();
		torque.z += roll_speed;
	
	state.apply_torque(torque);

func stabilize_upright(delta: float, velocity_threshold: float = 0.5):
	if not is_part_enabled or is_stabilizing or is_stabilized:
		_stabilize_timer = 0.0;
		return;

	# Check if we are moving slowly enough to start the timer
	if linear_velocity.length() < velocity_threshold and abs(angular_velocity.z) < velocity_threshold:
		_stabilize_timer += delta;
		if _stabilize_timer < stabilize_delay:
			return;

		# Check if we are already mostly upright
		if abs(rotation.z) < 0.05:
			rotation.z = 0;
			angular_velocity.z = 0;
			_stabilize_timer = 0.0;
			if stable_collider: stable_collider.disabled = false;
			return;

		is_stabilizing = true;
		lock_rotation = true;
		
		# Calculate vertical offset to prevent clipping for oblong shapes
		var initial_rot = rotation.z;
		var initial_y = global_position.y;
		
		var upright_tween = create_tween();
		upright_tween.set_parallel(true);
		upright_tween.set_ease(Tween.EASE_IN_OUT);
		upright_tween.set_trans(Tween.TRANS_ELASTIC);
		
		# Tween rotation
		upright_tween.tween_property(self, "rotation:z", 0.0, 0.65);
		
		# Simultaneously lift the body to clear the ground based on rotation
		upright_tween.tween_method(
			func(t: float):
				if not is_instance_valid(self): return;
				var current_rot = lerp(initial_rot, 0.0, t);
				var lift = (abs(sin(initial_rot)) - abs(sin(current_rot))) * 0.5;
				if lift > 0: 
					global_position.y = initial_y + lift,
			 0.0, 1.0, 0.5
		);

		upright_tween.finished.connect(
			func():
				angular_velocity.z = 0;
				lock_rotation = false;
				is_stabilizing = false;
				is_stabilized = true;
				_stabilize_timer = 0.0;
				if stable_collider: stable_collider.disabled = false;
		);
	else:
		is_stabilized = false;
		_stabilize_timer = 0.0;
		stable_collider.disabled = true;

func wake_up():
	sleeping = false;	
	is_stabilized = false;
	stable_collider.disabled = true;

func disable_part():
	super.disable_part();
	stable_collider.disabled = true;
