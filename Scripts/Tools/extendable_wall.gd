@tool
extends StaticBody3D

@export_range(0.1, 100) var length: float = 1.0:
	set(value):
		length = value
		_sync_children()

@export_node_path("MeshInstance3D") var mesh_path
@export_node_path("CollisionShape3D") var shape_path

@onready var mesh_node: MeshInstance3D = get_node_or_null(mesh_path)
@onready var shape_node: CollisionShape3D = get_node_or_null(shape_path)

func _ready():
	if not Engine.is_editor_hint(): return
	
	# Connect to the Resource signals directly
	if mesh_node and mesh_node.mesh:
		mesh_node.mesh.changed.connect(_on_child_resource_changed)
	if shape_node and shape_node.shape:
		shape_node.shape.changed.connect(_on_child_resource_changed)

func _on_child_resource_changed():
	# If you change the BoxMesh size.x in the inspector, 
	# this updates the parent 'length'
	var new_length = length
	if mesh_node and mesh_node.mesh:
		new_length = mesh_node.mesh.size.x
	elif shape_node and shape_node.shape:
		new_length = shape_node.shape.size.x
	
	if length != new_length:
		length = new_length # Triggers setter to update the other child

func _sync_children():
	if mesh_node and mesh_node.mesh:
		mesh_node.mesh.size.x = length
	if shape_node and shape_node.shape:
		shape_node.shape.size.x = length
