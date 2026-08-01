@tool
extends StaticBody3D;

@export var size: Vector3 = Vector3(1, 1, 1):
	set(val):
		size = val;
		_sync_sizes();

var mesh_node: MeshInstance3D;
var shape_node: CollisionShape3D;

@export_tool_button("Sync Sizes", "3D")
var sync_button: Callable = _sync_sizes;

@export_tool_button("Fix Scale", "3D")
var fix_scale_button: Callable = _fix_scale;

@export_tool_button("Swap X Y", "3D")
var swap_xy_button: Callable = _swap_xy;

@export_tool_button("Swap Y Z", "3D")
var swap_yz_button: Callable = _swap_yz;

@export_tool_button("Swap X Z", "3D")
var swap_xz_button: Callable = _swap_xz;


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
		size = new_size;
		# Triggers setter to update the other child;


func _sync_sizes() -> void:
	if mesh_node and mesh_node.mesh:
		mesh_node.mesh.size = size;
	if shape_node and shape_node.shape:
		shape_node.shape.size = size;


func _fix_scale() -> void:
	size.x *= scale.x;
	size.y *= scale.y;
	size.z *= scale.z;
	scale = Vector3.ONE;


func _swap_xy() -> void:
	var tmp = size.x;
	size.x = size.y;
	size.y = tmp;
	_sync_sizes();


func _swap_yz() -> void:
	var tmp = size.y;
	size.y = size.z;
	size.z = tmp;
	_sync_sizes();


func _swap_xz() -> void:
	var tmp = size.x;
	size.x = size.z;
	size.z = tmp;
	_sync_sizes();
