@tool
## Basic door class.
##
## Can be triggered by any trigger, such as a [WeightedButton]
## or [TriggerPredicate].
class_name Door
extends Node3D

## Movement extent. For example, a door with a movement extent of 90° can move 90° total.[br][br]
## [b]NOTE:[/b] This value is stored internally in radians.
## Motor rotation speed is stored internally in degrees / second.
@export_range(0, 180, 0.1, "radians_as_degrees") var movement_extent: float = PI / 2:
	get:
		return movement_extent
	set(value):
		movement_extent = value
		_update_door()
## Marks door as "flipped" or not. A flipped door rotates the other direction.
## If making double doors, set one of the doors to "flipped".
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
## Boolean for whether the motor is enabled or not.[br][br]
## Use this if you want to freeze any movement of the door.
@export var motor_enabled: bool = false:
	get:
		return motor_enabled
	set(value):
		motor_enabled = value
		_update_door()
## Internal boolean for whether the motor is reversed or not.[br][br]
## If the motor is reversed, the door will try to move towards
## its original state. otherwise, the door will try to move
## towards the state marked by [param movement_extent].
var motor_reversed: bool = true:
	get:
		return motor_reversed
	set(value):
		motor_reversed = value
		_update_door()
@onready var _internal_hinge: HingeJoint3D = %Joint

func _ready() -> void:
	_update_door()

func _update_door() -> void:
	if (not is_node_ready()):
		return
	if (not _internal_hinge):
		push_warning("No internal hinge selected")
		return
	if flipped:
		_internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_LOWER, -movement_extent)
		_internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_UPPER, 0)
	else:
		_internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_LOWER, 0)
		_internal_hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_UPPER, movement_extent)

	_internal_hinge.set_param(
		HingeJoint3D.Param.PARAM_MOTOR_TARGET_VELOCITY,
		(-1 if motor_reversed else 1) * (-1 if flipped else 1) * deg_to_rad(motor_velocity),
	)
	_internal_hinge.set_flag(HingeJoint3D.Flag.FLAG_ENABLE_MOTOR, motor_enabled)

## Causes this door to start to open, provided that
## [param motor_enabled] is set.
func on_button_activated() -> void:
	print("I was activated!")
	motor_reversed = false

## Causes this door to start to close, provided that
## [param motor_enabled] is set.
func on_button_deactivated() -> void:
	print("I was activated!")
	motor_reversed = true
