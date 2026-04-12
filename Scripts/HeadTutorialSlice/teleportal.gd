extends Area3D

@export var output_location: Node


func _on_body_entered(body: Node3D) -> void:
	body.position = output_location.position
