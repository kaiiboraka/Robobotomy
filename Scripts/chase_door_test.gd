extends Node3D

@export var door: Door


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	print("here!")
	door.motor_reversed = not Input.is_action_pressed("Player_Jump")
