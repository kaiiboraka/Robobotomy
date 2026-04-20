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


func on_button_activated() -> void:
	activated = true;


func on_button_deactivated() -> void:
	activated = false;
