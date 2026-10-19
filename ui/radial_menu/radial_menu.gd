class_name RadialMenu
extends Control
# Radial menu for selecting a limb

signal activated
signal deactivated

@export var menu: Control

var menu_visible: bool = false


func _ready() -> void:
	_set_active(false)

## Called to activate or reveal the radial menu
func activate() -> void:
	_set_active(true)

## Called to deactivate or hide the radial menu 
func deactivate() -> void:
	_set_active(false)

## Makes the radial menu visible
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

## Called when a radial menu slot is selected
func _on_radial_menu_advanced_slot_selected(_slot: Control, index: int) -> void:
	EventBus.emit_limb_selected(index)
	_set_active(false)
