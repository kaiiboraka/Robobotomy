class_name TitleScreen
extends Control
## Object for the title screen

const TUTORIAL = "uid://07360tmuyddg"

@export_file("*.tscn") var default_scene = "uid://07360tmuyddg"


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

## Disables the loading game buttons
func disable_buttons() -> void:
	%NewGameButton.disabled = true
	%LoadGameButton.disabled = true
