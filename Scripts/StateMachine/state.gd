extends Node
class_name State
## Base Class for all states

signal finished

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass
