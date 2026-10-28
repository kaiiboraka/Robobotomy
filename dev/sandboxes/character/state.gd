class_name State
extends Node
## Base Class for all states - functions like an abstract class

@warning_ignore("unused_signal")
signal finished(next_state_path: String, data: Dictionary)

func enter(_previous_state_path: String, _data := {}) -> void:
	pass

func exit() -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
