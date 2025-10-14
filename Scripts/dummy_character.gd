extends CharacterBody3D

var interactables: Array[Interactable]
var currInteraction: Interactable
var onRope: bool = false
func add_interactable(object: Interactable) -> void:
	if !is_instance_valid(object):
		return
	interactables.append(object)
func remove_interactable(object: Interactable) -> void:
	interactables.erase(object)
	if currInteraction == object:
		stop_interaction()
func _physics_process(delta: float) -> void:
	if onRope and currInteraction is Rope:
		
func interact() -> void:
	var interactableCount: int = interactables.size()
	if interactableCount == 0:
		return
	currInteraction = interactables[interactableCount]
	if currInteraction is Rope:
		onRope = true
		currInteraction.interact_with(self)
func stop_interaction() -> void:
	currInteraction = null
	onRope = false
