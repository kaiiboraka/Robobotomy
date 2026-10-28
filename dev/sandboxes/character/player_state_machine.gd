class_name PlayerStateMachine
extends Node
## State Machine controller for the player

@export var initial_state: State
## The current, active state
var active_state: State
## The last state to be active
var previous_state: State
@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()


func _ready():
	for s in find_children("*", "State"): 
		s.finished.connect(_transition_to_next_state)
	await owner.ready
	state.enter("")

# Function Deferrals
func _physics_process(delta: float) -> void:
	state.physics_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)

## Controls the transitions between states
func _transition_to_next_state(path: String, data:={}):
	if not has_node(path):
		printerr(owner.name + ": Trying to transition to state " + path + " but it does not exist.")
		return
	
	var previous_state_path := state.name
	state.exit()
	state = get_node(path)
	state.enter(previous_state_path, data)
