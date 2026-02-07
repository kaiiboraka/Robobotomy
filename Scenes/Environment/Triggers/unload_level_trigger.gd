extends Area3D
class_name UnloadLevelTrigger
## An Area3D trigger to unload old levels
##
## When the player passes through this trigger
## and activates the [signal Area3D.body_entered]
## signal the level_manager autoload's 
## [method LevelManager.unload_level]
## method will be called.
## @experimental: Still in development

## A file path for the next level scene
@export var level_to_load: String
var triggered := false
@onready var collision: CollisionShape3D = $CollisionShape3D

## Unloads the previous level and queues the loading
## of the next level. This should only activate for
## the player (its mask is for the player only)
func _on_player_entered(_body: Node3D) -> void:
	if not triggered:
		LevelManager.unload_level()
		LevelManager.queue_threaded_load(level_to_load)
		triggered = true
