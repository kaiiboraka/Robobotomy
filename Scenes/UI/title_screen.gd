extends Control
class_name TitleScreen


func _on_button_pressed() -> void:
	var level_to_load = %SceneToLoad.text
	if level_to_load == "":
		level_to_load = "res://Scenes/sandbox_levels/sb_1.tscn"
	LevelManager.load_level(level_to_load)
	self.hide()
	%Button.disabled = true
