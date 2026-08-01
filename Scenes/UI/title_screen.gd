extends Control

class_name TitleScreen

@export_file("*.tscn") var default_scene = "uid://07360tmuyddg"

const TUTORIAL = "uid://07360tmuyddg"

func _on_button_pressed() -> void:
	var level_to_load = %SceneToLoad.text
	if level_to_load == "":
		level_to_load = default_scene
	LevelManager.load_level(level_to_load)
	self.hide()
	disable_buttons()


func _on_new_game_button_pressed() -> void:
	LevelManager.load_level(TUTORIAL)
	self.hide()
	disable_buttons()


func disable_buttons() -> void:
	%NewGame_Button.disabled = true
	%LoadGame_Button.disabled = true
