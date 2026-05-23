@tool
extends StaticBody3D

@export var size: Vector3 = Vector3(1, 1, 1):
	set(val):
		size = val;
		_sync_sizes();

var mesh_node: MeshInstance3D;
var shape_node: CollisionShape3D;


func _enter_tree() -> void:
	if (is_node_ready() or Engine.is_editor_hint()):
		_sync_sizes();


func _ready() -> void:
	# Hard-coded node names
	mesh_node = get_node_or_null("BoxMesh");
	shape_node = get_node_or_null("BoxShape");
	
	_sync_sizes();
	
	# Connect to Resource signals for the 'reverse' update in editor
	if mesh_node and mesh_node.mesh:
		if not mesh_node.mesh.changed.is_connected(_on_resource_changed):
			mesh_node.mesh.changed.connect(_on_resource_changed);
			
	if shape_node and shape_node.shape:
		if not shape_node.shape.changed.is_connected(_on_resource_changed):
			shape_node.shape.changed.connect(_on_resource_changed);


func _on_resource_changed() -> void:
	# If you change the BoxMesh size in the inspector, this updates the parent 'size'
	var new_size := size;
	if mesh_node and mesh_node.mesh:
		new_size = mesh_node.mesh.size;
	elif shape_node and shape_node.shape:
		new_size = shape_node.shape.size;
	
	if size != new_size:
		size = new_size; # Triggers setter to update the other child

@export_tool_button("Sync Sizes", "3D")
var sync = _sync_sizes
func _sync_sizes() -> void:
	if mesh_node and mesh_node.mesh:
		mesh_node.mesh.size = size;
	if shape_node and shape_node.shape:
		shape_node.shape.size = size;
