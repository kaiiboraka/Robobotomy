@tool
extends RigidBody3D;
class_name Link

signal body_entered_grabbable(body: Node3D);

var idx: int;
var parent_chain: Chain;

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D;
@onready var grabbable_area: Area3D = $GrabbableArea;


func _ready() -> void:
	if grabbable_area:
		grabbable_area.body_entered.connect(_on_grabbable_body_entered);


func _on_grabbable_body_entered(body: Node3D) -> void:
	if parent_chain and parent_chain.is_occupied:
		return;
	body_entered_grabbable.emit(body);
