extends Node
## A scene manager to load and unload level scenes
##
## Loads new level scenes and unloads old level scenes
## on separate threads to manage smooth, seamless gameplay
## between each puzzle.
## @experimental: This class is still in development

#region Procedures and thought process
# My thought process for this script is to include
# functions that can be called at any time to
# 1. load the next level
# 2. unload the previous level
#
# For the sake of having seamless transitions
# between the puzzles and backgrounds and anything else
# the loading of new scenes will happen on a separate
# thread, and its loading function should be called
# before the scene enters camera visibility.
# 
# To accomplish this, a separate scene will be created
# with an Area3D Collision shape that can be added
# to any level scene to trigger the loading function
#
# To prevent slowing down the game with too many objects
# or scenes, another unloading function will be supplied
# which will unload the oldest loaded scene (the oldest
# level/previous level). 
#
# Similar to the loading function, an Area3D unloading
# trigger scene will also be made to trigger the unloading
# process when the player is in a specific region
# in a level (ideally when the previous level is outside
# of the view of the player)
#
# I'm still considering how to indicate which level
# should be loaded or unloaded. Should we pass in the
# scene name when the function is called, or keep a 
# tally and a list of all scenes to know which one we
# should be on. I'm not sure yet, though I will try
# to implement the first method so each trigger can be
# set to load/unload the adjacent levels in the game.
#endregion

# Currently undefined, but should be the root
# node in the main scene
var main_scene: Main
# Currently undefined, but is a level scene
var loaded_levels: Array[Node3D] = []

## Loads the given level [br]
##
## [b]Warning:[/b] Will likely cause pauses
## in the game to load the level
## @deprecated: Use load_threaded_level instead
func load_level(scene_path: String) -> void:
	var new_level: Node3D = load(scene_path).instantiate()
	loaded_levels.append(new_level)
	main_scene.add_child(new_level)


func queue_threaded_load(scene_path: String) -> void:
	ResourceLoader.load_threaded_request(scene_path)


## Returns the status of a threaded loading scene at the given path
## [br][br]
## Returns [code]bool[/code] true or false based on whether
## or not the scene has completed loading. If for some reason
## the scene_path is not being loaded at all, it will commence
## the loading process and return false.
func get_threaded_status(scene_path: String) -> bool:
	## An integer value representing the status of the thread
	var status: int = ResourceLoader.load_threaded_get_status(scene_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return true
	elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
	# Indicates that the level wants to be loaded but hasn't 
	# started the process yet, call queue_threaded_load() method
	# WARNING: This may indicate that the scene_path is invalid
		queue_threaded_load(scene_path)
		return false
	else:
		return false


## Returns a floating-point number of the progress of a scene
## being loaded in a separate thread. 
##
## Useful for UI progress bars to display the progress of loading
## a scene/level 
func get_threaded_progress(scene_path: String) -> float:
	var progress: Array = []
	ResourceLoader.load_threaded_get_status(scene_path, progress)
	return progress[0]


func load_threaded_level(scene_path: String) -> void:
	var new_level: Node3D = ResourceLoader.load_threaded_get(scene_path).instantiate()
	loaded_levels.append(new_level)
	main_scene.add_child(new_level)


func unload_level() -> void:
	# To avoid errors, check if a previous level exists/is loaded
	if len(loaded_levels) > 1:
		loaded_levels[0].queue_free()
		loaded_levels.pop_front()
