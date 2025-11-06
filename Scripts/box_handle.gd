@tool
class_name BoxHandle
extends Interactable

@onready var meshInstance: MeshInstance3D = $"Handle Mesh"
@onready var grabShape: CollisionShape3D = $"Grabbable Area/Grabbable Shape"


func interact_with(interactor: CharacterBody3D):
	pass


func _set_geometry(size: Vector3) -> void:
	var mesh: BoxMesh = meshInstance.mesh as BoxMesh
	mesh.size = size


func _set_grab_shape(size: Vector3) -> void:
	var shape: BoxShape3D = grabShape.shape as BoxShape3D
	shape.size = size
