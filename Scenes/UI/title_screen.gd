extends Control

class_name TitleScreen

@export_file("*.tscn") var default_scene = "uid://bmn7bmff4lgix"

const TUTORIAL = "uid://t48dk4ejgiod"

func _on_button_pressed() -> void:
	var level_to_load = %SceneToLoad.text
	if level_to_load == "":
		level_to_load = default_scene
	LevelManager.load_level(level_to_load)
	self.hide()
	%Button.disabled = true


func _on_new_game_button_pressed() -> void:
	LevelManager.load_level(TUTORIAL)
	pass
