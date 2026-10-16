class_name RadialMenu
extends Control

@export var menu: Control

var menu_visible: bool = false

signal activated
signal deactivated

func activate() -> void:
	_set_active(true);
	
func deactivate() -> void:
	_set_active(false);

func _set_active(enabled: bool) -> void:
	menu.set_process(enabled)
	menu.set_process_input(enabled)
	menu_visible = enabled
	if enabled:
		show()
		activated.emit()
	else:
		hide()
		deactivated.emit()


func _ready() -> void:
	_set_active(false)


func _on_radial_menu_advanced_slot_selected(_slot: Control, index: int) -> void:
	EventBus.emit_limb_selected(index)
	_set_active(false)


#func _unhandled_input(event: InputEvent) -> void:
	#var radial_menu_pressed = event.is_action_pressed("Player_RadialMenu")
	#if radial_menu_pressed and not menu_visible:
		#_set_active(true)
	#elif radial_menu_pressed and menu_visible:
		#_set_active(false)
