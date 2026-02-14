extends Node
class_name PlayerStateMachine

@export var initial_state: State

@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()

var active_state: State
var previous_state: State




func _physics_process(delta: float) -> void:
	state.physics_process(delta)
