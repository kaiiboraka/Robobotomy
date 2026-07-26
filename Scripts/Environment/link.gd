@tool
extends Node3D
class_name Link

var head
var feet
var idx: int
var link_height: float

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func setup(p_head, p_feet, p_idx, p_height):
	head = p_head
	feet = p_feet
	idx = p_idx
	link_height = p_height

func update_link():
	if head == null or feet == null:
		return

	var link_center = (head.position + feet.position) * 0.5
	var link_dir = (head.position - feet.position).normalized()

	position = link_center

	var up_ref = Vector3.UP
	if abs(link_dir.dot(up_ref)) > 0.99:
		up_ref = Vector3.RIGHT
	var x_axis = up_ref.cross(link_dir).normalized()
	var z_axis = link_dir.cross(x_axis).normalized()
	basis = Basis(x_axis, link_dir, z_axis)

	if idx % 2 == 1:
		rotate_object_local(Vector3.UP, deg_to_rad(90))

	if not head.locked:
		head.position = link_center + link_dir * link_height * 0.5
	if not feet.locked:
		feet.position = link_center - link_dir * link_height * 0.5
