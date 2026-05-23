extends Control

class_name TitleScreen

@export_file("*.tscn") var default_scene = "uid://bmn7bmff4lgix"


func _on_button_pressed() -> void:
	var level_to_load = %SceneToLoad.text
	if level_to_load == "":
		level_to_load = default_scene
	LevelManager.load_level(level_to_load)
	self.hide()
	%Button.disabled = true
