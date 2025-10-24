@abstract class_name Interactable
extends Node3D

@abstract func interact_with(interactor: CharacterBody3D)

func _on_interaction_area_entered(area: Area3D) -> void:
	if area is InteractionArea:
		var player = area.get_parent()
		player.AddInteractable(self)

func _on_interaction_area_exited(area: Area3D) -> void:
	if area is InteractionArea:
		var player = area.get_parent()
		player.RemoveInteractable(self)
