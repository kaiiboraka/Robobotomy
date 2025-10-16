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
