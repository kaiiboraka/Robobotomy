@tool
extends Node3D
class_name Link

var head
var feet
var idx: int

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func setup(p_head, p_feet, p_idx):
	head = p_head
	feet = p_feet
	idx = p_idx

func update_link():
	if head == null or feet == null:
		return
	position = (head.position + feet.position) * 0.5
	rotation.y = deg_to_rad(90) if idx % 2 == 1 else 0.0
