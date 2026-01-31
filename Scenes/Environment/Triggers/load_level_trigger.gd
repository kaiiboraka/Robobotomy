extends Area3D
class_name LoadLevelTrigger
## An Area3D trigger to start loading new levels
##
## When the player passes through this trigger
## and activates the [signal Area3D.body_entered]
## signal the level_manager autoload's 
## [method LevelManager.queue_threaded_load]
## method will be called.
## @experimental: Still in development

## A file path for the next level scene
@export var level_to_load: String
var loading_queued := false
var loading_finished := true
var triggered := false
@onready var collision: CollisionShape3D = $CollisionShape3D

## If loading has been queued but not finished
## then, each process will check if loading has
## finished. This way the level loads when it is 
## ready.
func _process(_delta: float) -> void:
	if loading_queued and loading_finished:
		LevelManager.load_threaded_level(level_to_load)
		loading_queued = false
	elif loading_queued and not loading_finished:
		loading_finished = LevelManager.get_threaded_status(level_to_load)


## Loads the next level on a separate thread
func _on_player_entered(_body: Node3D) -> void:
	if not triggered:
		loading_finished = LevelManager.get_threaded_status(level_to_load)
		if loading_finished:
			LevelManager.load_threaded_level(level_to_load)
		else:
			loading_queued = true
		triggered = true
