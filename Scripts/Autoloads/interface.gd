extends CanvasLayer;

@onready var title_screen: TitleScreen = $TitleScreen;

var radial_menu : RadialMenu : get = _get_radial_menu;

const RADIAL_MENU_SCENE = preload("uid://b2lsnrmivu4ky");

func _get_radial_menu() -> RadialMenu:
	if not radial_menu:
		var new_menu = RADIAL_MENU_SCENE.instantiate();
		add_child(new_menu);
		radial_menu = new_menu;
	return radial_menu;
	pass;


func show_radial_menu() -> void:
	radial_menu.activate();
	pass;

func hide_radial_menu() -> void:
	radial_menu.deactivate();
	pass;
