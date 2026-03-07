@tool
extends StaticBody3D

@export_range(0.1, 100) var length: float = 1.0:
	set(value):
		length = value
		_sync_children()

# Internal references
var mesh_node: MeshInstance3D
var shape_node: CollisionShape3D

func _ready():
	# Hard-coded node names
	mesh_node = get_node_or_null("BoxMesh")
	shape_node = get_node_or_null("BoxShape")
	
	if not Engine.is_editor_hint(): 
		_sync_children() # Ensure physics matches visual on game start
		return
	
	# Connect to Resource signals for the 'reverse' update in editor
	if mesh_node and mesh_node.mesh:
		if not mesh_node.mesh.changed.is_connected(_on_resource_changed):
			mesh_node.mesh.changed.connect(_on_resource_changed)
			
	if shape_node and shape_node.shape:
		if not shape_node.shape.changed.is_connected(_on_resource_changed):
			shape_node.shape.changed.connect(_on_resource_changed)

func _on_resource_changed():
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
