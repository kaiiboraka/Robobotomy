extends Control
class_name TitleScreen


func _on_button_pressed() -> void:
	LevelManager.load_level("res://Scenes/sandbox_levels/sb_1.tscn")
	self.hide()
	%Button.disabled = true
