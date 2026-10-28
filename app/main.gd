class_name Main
extends Node
## Defines the main scene for the game to run


func _ready() -> void:
	LevelManager.main_scene = self
