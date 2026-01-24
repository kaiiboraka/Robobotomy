extends Camera3D

@export var moveSpeed : float = 2;
@export var wheelSpeed : float = .25;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_left")):
		position = position + Vector3(-moveSpeed, 0, 0);
	if (event.is_action_pressed("ui_right")):
		position = position + Vector3(moveSpeed, 0, 0);
		
	if (event.is_action_pressed("ui_scroll_up")):
		moveSpeed += wheelSpeed;
	if (event.is_action_pressed("ui_scroll_down")):
		moveSpeed -= wheelSpeed;
	moveSpeed = clamp(moveSpeed, 0, 100)
