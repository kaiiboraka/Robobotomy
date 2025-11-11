@tool
class_name BoxHandle
extends Interactable

@export var isVertical: bool = false
@onready var box: Box = get_parent().get_parent() as Box
@onready var meshInstance: MeshInstance3D = $"Handle Mesh"
@onready var grabShape: CollisionShape3D = $"Grabbable Area/Grabbable Shape"


func interact_with(interactor: Node3D) -> void:
	box.grab(interactor)


func stop_interaction(interactor: Node3D) -> void:
	box.stop_grab(interactor)


func _set_geometry(size: Vector3) -> void:
	var mesh: BoxMesh = meshInstance.mesh.duplicate() as BoxMesh
	mesh.size = size
	meshInstance.mesh = mesh


func _set_grab_shape(size: Vector3) -> void:
	var shape: BoxShape3D = grabShape.shape.duplicate() as BoxShape3D
	shape.size = size
	grabShape.shape = shape
