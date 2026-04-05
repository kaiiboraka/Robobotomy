extends Path3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var activated: bool = false;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(activated and $PathFollow3D.progress < self.curve.get_baked_length()-0.01):
		$PathFollow3D.progress += delta;
	elif($PathFollow3D.progress > 0.01):
		$PathFollow3D.progress -= delta;
	pass


func _on_activated(body: Node3D) -> void:
	activated = true;


func _on_deactivated(body: Node3D) -> void:
	activated = false;
