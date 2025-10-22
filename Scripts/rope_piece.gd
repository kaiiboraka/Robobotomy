class_name RopePiece
extends RigidBody3D

@onready var ropeMesh: MeshInstance3D = $"Rope Mesh"
@onready var ropeShape: CollisionShape3D = $"Rope Shape"


func _set_piece_geometry(length: float, width: float) -> void:
	var mesh = ropeMesh.mesh as CylinderMesh
	mesh.height = length
	mesh.bottom_radius = width / 2
	mesh.top_radius = width / 2
	
	var shape = ropeShape.shape as BoxShape3D
	shape.size = Vector3(width, length, width)
