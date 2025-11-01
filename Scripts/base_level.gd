class_name BaseLevel
extends Node3D
## A basic level node to serve as the root node of a level scene

@export var start_marker: Marker3D
@export var end_marker: Marker3D

var end_location: Vector3
var _start_location: Vector3
## The location [code]_start_location[/code] should be at.
##[br][br]
## Determined by finding the previous level's ending location
var _target_location: Vector3


func _ready() -> void:
	_start_location = start_marker.global_position
	_target_location = LevelManager.get_previous_end()
	# Translate the scene (this should be the root node)
	self.global_position  += _target_location - _start_location
	# Update our own ending location for future use
	end_location = end_marker.global_position
