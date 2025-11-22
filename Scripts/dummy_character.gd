# NOTE: This script is just to help translate GDScript code into eventual C#. It doesn't carry any 
# actual implementation that is useful.

extends CharacterBody3D

var interactables: Array[Interactable]
var currInteraction: Interactable
var onRope: bool = false

func add_interactable(object: Interactable) -> void:
	if !is_instance_valid(object):
		return
	interactables.append(object)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Player_Interact"):
		if currInteraction == null:
			interact()
		else:
			stop_interaction()
func remove_interactable(object: Interactable) -> void:
	interactables.erase(object)
	if currInteraction == object:
		stop_interaction()
func _physics_process(delta: float) -> void:
	if onRope and currInteraction is Rope:
		var rope: Rope = currInteraction as Rope
		global_position = rope.get_rope_point()
		if Input.is_action_just_pressed("Player_Jump"):
			stop_interaction()
func interact() -> void:
	var interactableCount: int = interactables.size()
	if interactableCount == 0:
		return
	currInteraction = interactables[interactableCount]
	if currInteraction is Rope:
		onRope = true
		currInteraction.interact_with(self)
func stop_interaction() -> void:
	if onRope:
		onRope = false
		if currInteraction is Rope:
			var rope: Rope = currInteraction as Rope
			velocity = rope.get_tangental_velocity()
	currInteraction = null


func enter_pipe() -> void:
	var inPipe = true
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
func exit_pipe() -> void:
	var inPipe = false
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
func standard_movement(inputDir: Vector2) -> Vector3:
	var speed = 1 #NOT IN ACTUAL SCRIPT
	var _velocity: Vector3 = velocity
	var direction: Vector3 = Vector3(inputDir.x, 0, 0) * transform.basis
	if direction != Vector3.ZERO:
		_velocity.x = direction.x * speed
	else:
		_velocity.x = move_toward(_velocity.x, 0, speed)
	return _velocity
func pipe_movement(inputDir: Vector2) -> Vector3:
	var speed = 1 #NOT IN ACTUAL SCRIPT
	var _velocity: Vector3 = velocity
	var direction: Vector3 = Vector3(inputDir.x, inputDir.y, 0) * transform.basis
	if direction != Vector3.ZERO:
		_velocity.x = direction.x * speed
		_velocity.y = direction.y * speed
	else:
		_velocity.x = move_toward(_velocity.x, 0, speed)
		_velocity.y = move_toward(_velocity.y, 0, speed)
	return _velocity
	
