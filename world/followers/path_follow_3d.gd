class_name PathFollow3DType
extends PathFollow3D
## Helper class for the head moving through a pipe

@export var move_speed := 0.5

var player: RigidBody3D
var previous_parent: Node
var inside_pipe := false


func _physics_process(_delta):
	if !inside_pipe:
		return
	var input = Input.get_axis("Player_Move_Left", "Player_Move_Right")
	progress += input * move_speed #* delta
	player.global_position = global_position
	player.global_rotation = global_rotation
	print(progress)
	
## Called when the head enters the pipe entrance
func _on_pipe_enter_body_entered(body: Node3D) -> void:
	if body.name != "Head":
		return

	if inside_pipe:
		player.global_position = global_position
		inside_pipe = false
		player = null
	else:
		if body.name != "Head":
			print("Not Head")
			return
		print("Head In")
		inside_pipe = true	
		player = body
		progress = get_parent().curve.get_closest_offset(player.global_position)
		print("Pipe length:", get_parent().curve.get_baked_length())
		print("Starting progress:", progress)

## Called when the head enters the pipe exit
func _on_pipe_exit_body_entered(body: Node3D) -> void:
	if body.name != "Head":
		return
	if inside_pipe:
		player.global_position = global_position
		inside_pipe = false
		player = null
	else:
		if body.name != "Head":
			print("Not Head")
			return
		print("Head In")
		inside_pipe = true	
		player = body
		progress = get_parent().curve.get_closest_offset(player.global_position)
