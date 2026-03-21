extends Camera3D

@export var moveSpeed : float = .1;
@export var wheelSpeed : float = .01;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_scroll_up")):
		moveSpeed += wheelSpeed;
	if (event.is_action_pressed("ui_scroll_down")):
		moveSpeed -= wheelSpeed;
	# Reset height to 0
	if event.is_action_pressed("Player_Recall"):
		position.y = 1.697
	moveSpeed = clamp(moveSpeed, 0.01, 100)
	pass

func _process(delta: float) -> void:
	if (Input.is_action_pressed("ui_left")):
		position = position + Vector3(-moveSpeed, 0, 0);
	if (Input.is_action_pressed("ui_right")):
		position = position + Vector3(moveSpeed, 0, 0);
	# Up / Down (NEW)
	if Input.is_action_pressed("ui_up"):
		position += Vector3(0, moveSpeed, 0)
	if Input.is_action_pressed("ui_down"):
		position += Vector3(0, -moveSpeed, 0)
