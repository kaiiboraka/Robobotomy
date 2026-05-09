@tool
class_name Killzone
extends Area3D

@export var size : Vector3 = Vector3(1, 1, 1) :
	set(val):
		size = val;
		_sync_size();
@export var checkpoint : Marker3D;

@onready var shape_node : CollisionShape3D = $CollisionShape3D;


func _ready() -> void:
	shape_node = get_node_or_null("CollisionShape3D");

	_sync_size();
	body_entered.connect(_on_body_entered);
	
	# Connect to Resource signals for the 'reverse' update in editor
	if shape_node and shape_node.shape:
		if not shape_node.shape.changed.is_connected(_on_resource_changed):
			shape_node.shape.changed.connect(_on_resource_changed);


func _on_body_entered(body : Node3D) -> void:
	if checkpoint and body.has_method("spawn_at"):
		body.spawn_at(checkpoint.global_position);


func _on_resource_changed() -> void:
	# If you change the collision size in the inspector, this updates the parent 'size'
	var new_size := size;
	if shape_node and shape_node.shape:
		new_size = shape_node.shape.size;
	
	if size != new_size:
		size = new_size; # Triggers setter to update the other child

@export_tool_button("Sync Size", "3D")
var sync = _sync_size
func _sync_size() -> void:
	if shape_node and shape_node.shape:
		shape_node.shape.size = size;
