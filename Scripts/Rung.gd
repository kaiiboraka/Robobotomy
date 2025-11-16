@tool
class_name LadderRung
extends Node3D

@onready var meshInstance: MeshInstance3D = $Mesh

func _update_geometry(length: float, width: float) -> void:
	var mesh: CylinderMesh = meshInstance.mesh as CylinderMesh
	mesh.height = length
	mesh.bottom_radius = width
	mesh.top_radius = width
