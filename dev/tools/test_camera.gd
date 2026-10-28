class_name TestCamera
extends Camera3D
## Camera for viewing and navigating the vertical
## slice test scene.

## Movement speed for the camera
@export var move_speed : float = .1
## Mouse scroll wheel speed modifier
@export var wheel_speed : float = .01


func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_left"):
		position += Vector3(-move_speed, 0, 0)
		
	if Input.is_action_pressed("ui_right"):
		position += Vector3(move_speed, 0, 0)
	
	if Input.is_action_pressed("ui_up"):
		position += Vector3(0, move_speed, 0)
		
	if Input.is_action_pressed("ui_down"):
		position += Vector3(0, -move_speed, 0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_scroll_up"):
		move_speed += wheel_speed
		
	if event.is_action_pressed("ui_scroll_down"):
		move_speed -= wheel_speed
	
	# Clamp player to the ground
	if event.is_action_pressed("Player_Recall"):
		position.y = 1.697
		
	move_speed = clamp(move_speed, 0.01, 100)
