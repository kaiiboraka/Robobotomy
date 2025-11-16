@tool
class_name Handle
extends Interactable

@export var isVertical: bool = false
@onready var grabJoint: Generic6DOFJoint3D = $"Grab Joint"
@onready var box: Box = get_parent().get_parent() as Box
@onready var meshInstance: MeshInstance3D = $"Handle Mesh"
@onready var grabShape: CollisionShape3D = $"Grabbable Area/Grabbable Shape"

func _ready() -> void:
	grabJoint.global_rotation = Vector3.ZERO

func interact_with(interactor: Node3D) -> void:
	var player: CharacterBody3D = interactor as CharacterBody3D
	if !is_instance_valid(player):
		return
	
	grabJoint.node_a = box.get_path()
	grabJoint.node_b = player.get_path()
	box.grab(interactor)


func stop_interaction(interactor: Node3D) -> void:
	var player: CharacterBody3D = interactor as CharacterBody3D
	if !is_instance_valid(player):
		return
	
	grabJoint.node_a = ""
	grabJoint.node_b = ""
	box.stop_grab(interactor)


func _set_geometry(size: Vector3) -> void:
	var mesh: BoxMesh = meshInstance.mesh.duplicate() as BoxMesh
	mesh.size = size
	meshInstance.mesh = mesh


func _set_grab_shape(size: Vector3) -> void:
	var shape: BoxShape3D = grabShape.shape.duplicate() as BoxShape3D
	shape.size = size
	grabShape.shape = shape
