extends CharacterBody3D
class_name Crane

var started := false
var extending := true
var push_force := 0.5

@export var move_speed: float = 4.0
@export var total_time: float

func _ready() -> void:
	$Timer.wait_time = total_time

func _physics_process(_delta: float) -> void:
	if started:
		if extending:
			velocity.y = -move_speed
		else:
			velocity.y = move_speed
	else:
		velocity.y = 0
	move_and_slide()
	
func _on_timer_timeout() -> void:
	$Timer.wait_time = total_time
	started = false

func _on_area_3d_body_entered(_body: Node3D) -> void:
	var elapsed_time = total_time - $Timer.time_left
	$Timer.stop()
	$Timer.wait_time = elapsed_time
	$Timer.start()
	started = true
	extending = true

func _on_area_3d_body_exited(_body: Node3D) -> void:
	var elapsed_time = total_time - $Timer.time_left
	$Timer.stop()
	$Timer.wait_time = elapsed_time
	$Timer.start()
	started = true
	extending = false
