extends Node
class_name State
## Base Class for all states

signal finished(next_state_path: String, data: Dictionary)

func enter(_previous_state_path: String, _data := {}) -> void:
	pass

func exit() -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
