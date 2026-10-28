class_name InterfaceType
extends CanvasLayer
## Shows and hides the radial menu scene

## Radial Menu scene path
const RADIAL_MENU_SCENE: PackedScene = preload("uid://b2lsnrmivu4ky")
## Radial Menu instance/node
var radial_menu : RadialMenu : get = _get_radial_menu

## Get a new RadialMenu scene if none exists
func _get_radial_menu() -> RadialMenu:
	if not radial_menu:
		var new_menu: Node = RADIAL_MENU_SCENE.instantiate()
		add_child(new_menu)
		radial_menu = new_menu
	return radial_menu

## Make the radial menu visible (and functional)
func show_radial_menu() -> void:
	radial_menu.activate()

## Hide the radial menu
func hide_radial_menu() -> void:
	radial_menu.deactivate()
