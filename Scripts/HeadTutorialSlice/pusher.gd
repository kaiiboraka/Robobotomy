extends CharacterBody3D

var started := false
var extending := true
var move_speed := 4
var push_force := 0.5

func _on_area_3d_body_entered(_body: Node3D) -> void:
	if $Timer.is_stopped():
		$Timer.start()
	started = true
	extending = true

func _on_timer_timeout() -> void:
	started = false

func _physics_process(_delta: float) -> void:
	if started:
		if extending:
			velocity.x = move_speed
		else:
			velocity.x = -move_speed
	else:
		velocity.x = 0
	push_head_only()
	move_and_slide()

func _on_area_3d_body_exited(_body: Node3D) -> void:
	if $Timer.is_stopped():
		$Timer.start()
	started = true
	extending = false


func push_head_only() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var collider := c.get_collider()
		if collider is RigidBody3D and collider.name == "Head":
			var push_dir := -c.get_normal()
			push_dir.y = 0.0
			collider.apply_central_impulse(push_dir * push_force)
