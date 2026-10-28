@tool
class_name ButtonDoor
## A [Door] that is easily wired up to [InteractiveButton] objects.
##
## @deprecated: Use [Door] instead.
extends Door

enum TriggerMode { ANY_BUTTON, ALL_BUTTONS }

## Trigger mode of this door.[br][br]
## [b]Any Button:[/b] Any pressed button will open this door.[br][br]
## [b]All Buttons:[/b] All buttons must be pressed to open this door.
@export var trigger_mode: TriggerMode = TriggerMode.ALL_BUTTONS

## An array of [InteractiveButton] objects to wire up to this door.
@export var buttons: Array[InteractiveButton]
# get:
# 	return buttons
# set(value):
# 	_button_states = []
# 	buttons = value1
# 	for i in range(len(buttons)):
# 		_button_states.append(false)

var _button_states: Array[bool] = []


func _ready() -> void:
	for i in range(len(buttons)):
		var button := buttons[i]
		if button:
			button.body_entered.connect(
				_button_body_entered.bind(i),
			)
			button.body_exited.connect(
				_button_body_exited.bind(i),
			)
		_button_states.append(button.has_overlapping_bodies() if button else false)


func _button_body_entered(_body: Node3D, index: int) -> void:
	print("Button body entered!")
	_button_states[index] = true


func _button_body_exited(_body: Node3D, index: int) -> void:
	print(
		"Button body exited! Overlapping bodies: %s" %
		str(buttons[index].get_overlapping_bodies()),
	)
	_button_states[index] = buttons[index].has_overlapping_bodies()


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		#if Input.is_action_just_pressed("Player_Jump"):
			#for i in range(len(_button_states)):
				#_button_states[i] = true
		if _button_states.is_empty():
			motor_reversed = true
			return
		match trigger_mode:
			TriggerMode.ANY_BUTTON:
				motor_reversed = not (true in _button_states)
			TriggerMode.ALL_BUTTONS:
				motor_reversed = (false in _button_states)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	warnings.append("This node is deprecated. Use [Door] instead.")
	# Return the list of warnings (empty array means no warning icon)
	return PackedStringArray(warnings)
