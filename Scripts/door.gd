@tool
class_name Door
extends Node3D

## Movement extent. For example, a door with a movement extent of 90° can move 90° total.[br][br]
## [b]NOTE:[/b] This value is stored internally in radians.
## Mmmotor rotation speed is stored internally in degrees / second.
@export_range(0, 180, 0.1, "radians_as_degrees") var movement_extent: float = PI / 2:
	get:
		return movement_extent
	set(value):
		movement_extent = value
		_update_door()
## Marks door as "flipped" or not. A flipped door rotates the other direction.
@export var flipped: bool = false:
	get:
		return flipped
	set(value):
		flipped = value
		_update_door()

@export_group("Motor", "motor_")
## Rotation speed in degrees per second.[br][br]
## [b]NOTE:[/b] This value is stored internally in degrees.
## Movmement extent is stored internally in radians.
@export_range(0.0, 500.0, 1.0, "suffix:°/s") var motor_velocity: float = 15.0:
	get:
		return motor_velocity
	set(value):
		motor_velocity = value
		_update_door()

# @export_range(0, 360, 0.1, "radians_as_degrees") var starting_angle: float = 0:
# 	get:
# 		return starting_angle
# 	set(value):
# 		starting_angle = value
# 		_update_door()
@export var motor_enabled: bool = false:
	get:
		return motor_enabled
	set(value):
		motor_enabled = value
		_update_door()
@export var motor_reversed: bool = false:
	get:
		return motor_reversed
	set(value):
		motor_reversed = value
		_update_door()
# @export var internal_hinge: StaticBody3D
# @export var internal_door: RigidBody3D
@export_group("🔒 Internal Nodes", "internal_")
@export var internal_hinge: HingeJoint3D


func _update_door() -> void:
	if (not internal_hinge):
		push_warning("No internal hinge selected")
		return
	if flipped:
		internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_LOWER, -movement_extent)
		internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_UPPER, 0)
	else:
		internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_LOWER, 0)
		internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_UPPER, movement_extent)

	internal_hinge.set_param(
		HingeJoint3D.Param.PARAM_MOTOR_TARGET_VELOCITY,
		(-1 if motor_reversed else 1) * (-1 if flipped else 1) * deg_to_rad(motor_velocity),
	)
	internal_hinge.set_flag(HingeJoint3D.Flag.FLAG_ENABLE_MOTOR, motor_enabled)
	# hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_LOWER, lower_angle)
	# assert(internal_hinge, "Door: No internal hinge node selected.")
	# internal_hinge.rotation.z = starting_angle
	# assert(internal_door, "Door: No internal door node selected.")
	# internal_door.rotation.z = lerp(0.0, movement_extent, progress)

	# Called when the node enters the scene tree for the first time.
	# func _ready() -> void:
	# 	pass # Replace with function body.

	# # Called every frame. 'delta' is the elapsed time since the previous frame.
	# func _process(delta: float) -> void:
	# 	pass
