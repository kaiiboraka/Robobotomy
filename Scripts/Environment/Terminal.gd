extends Node

@export var activation_targets: Array[Node] = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func activate():
	pass

func deactivate():
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
