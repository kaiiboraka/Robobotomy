extends Node
class_name Main


func _ready() -> void:
	# Load main into LevelManager so it knows where to load
	# new levels
	LevelManager.main_scene = self
