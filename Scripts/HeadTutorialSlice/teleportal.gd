extends Area3D

@export var output_location: Node

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	body.position = output_location.position
