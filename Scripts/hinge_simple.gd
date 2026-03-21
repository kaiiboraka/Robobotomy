@tool
class_name hingeSimple extends Node3D;

@export_group("Hinge Parameters")
@export var lower_angle: float = 0;
@export var upper_angle: float = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hinge: HingeJoint3D = get_node("%HingeJoint3D")
	hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_UPPER, upper_angle)
	hinge.set_param(HingeJoint3D.Param.PARAM_LIMIT_LOWER, lower_angle)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
