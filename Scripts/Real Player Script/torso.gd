extends RigidBody3D

@export var roll_speed = 7.0
@export var jump_force = 10.0
@export var max_angular_velocity = 12.0

var limbs_attached = 0

@onready var ray_cast_3d: RayCast3D = $RayCast3D

func _ready():
	# Constrain movement and rotation for 2.5D gameplay.
	# The body should not move along the Z axis.
	axis_lock_linear_z = true
	# The body should only be able to rotate around the Z axis (for rolling).
	axis_lock_angular_x = true
	axis_lock_angular_y = true

func _physics_process(_delta):
	# Enable/disable rotation based on attached limbs.
	ray_cast_3d.rotation = -rotation;
	if limbs_attached == 0:
		lock_rotation = false
	else:
		lock_rotation = true

func _input(event: InputEvent) -> void:
	if event.is_action("Player_Jump"):
		sleeping = false;
	if event.is_action("Player_Move_Right"):
		sleeping = false;
	if event.is_action("Player_Move_Left"):
		sleeping = false;

func _integrate_forces(state):
	# Only apply torque if rotation is not locked.
	if lock_rotation:
		return

	var torque = Vector3.ZERO
	var current_ang_vel = state.angular_velocity.z
	
	if Input.is_action_just_pressed("Player_Jump") and ray_cast_3d.is_colliding():
		sleeping = false;
		apply_central_force(Vector3.UP * jump_force)
	
	# Apply torque for moving right, respecting the velocity cap.
	if Input.is_action_pressed("Player_Move_Right") and current_ang_vel > -max_angular_velocity:
		sleeping = false;
		torque.z -= roll_speed
			
	# Apply torque for moving left, respecting the velocity cap.
	if Input.is_action_pressed("Player_Move_Left") and current_ang_vel < max_angular_velocity:
		sleeping = false;
		torque.z += roll_speed
	
	state.apply_torque(torque)
