@tool
extends Node3D;
class_name Link

## Emitted when a body enters this link's grabbable area.
signal body_entered_grabbable(body: Node3D);

var head;
var feet;
var idx: int;
var link_height: float;
var parent_chain: Chain;

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D;
@onready var grabbable_area: Area3D = $GrabbableArea;


func _ready() -> void:
	if grabbable_area:
		grabbable_area.body_entered.connect(_on_grabbable_body_entered);


## Forward the area's body_entered as our own signal (call down, signal up).
## Skips emitting when the parent chain is already occupied to avoid
## redundant re-grab attempts during climbing.
func _on_grabbable_body_entered(body: Node3D) -> void:
	if parent_chain and parent_chain.is_occupied:
		return;
	body_entered_grabbable.emit(body);

## Store references to the two ChainPoints this link connects,
## its index in the chain, and the target segment length.
func setup(p_head, p_feet, p_idx, p_height):
	head = p_head;
	feet = p_feet;
	idx = p_idx;
	link_height = p_height;

## Push head and feet to exactly link_height apart along their current axis.
## Called repeatedly during constraint iterations to maintain rigid segment length.
func apply_constraint():
	if head == null or feet == null:
		return;

	var link_center = (head.position + feet.position) * 0.5;
	var link_dir = (head.position - feet.position).normalized();

	if not head.locked:
		head.position = link_center + link_dir * link_height * 0.5;
	if not feet.locked:
		feet.position = link_center - link_dir * link_height * 0.5;

## Position this node at the midpoint between head and feet, then orient the
## Y axis along the head→feet direction. Odd-indexed links get a 90° rotation
## around Y so alternating links form a visually continuous chain.
func update_visual():
	if head == null or feet == null:
		return;

	var link_center = (head.position + feet.position) * 0.5;
	var link_dir = (head.position - feet.position).normalized();

	position = link_center;

	var up_ref = Vector3.UP;
	if abs(link_dir.dot(up_ref)) > 0.99:
		up_ref = Vector3.RIGHT;
	var x_axis = up_ref.cross(link_dir).normalized();
	var z_axis = x_axis.cross(link_dir).normalized();
	basis = Basis(x_axis, link_dir, z_axis);

	if idx % 2 == 1:
		rotate_object_local(Vector3.UP, deg_to_rad(90));
