@tool
class_name LightGrid
extends MeshInstance3D
## @experimental: This class uses [annotation @tool] and may be unstable.
## A customizable grid of lights that emits a signal when all lights are activated.
##
## The [LightGrid] node is a 3D node designed as a diagetic UI element for Robotomy.
## It displays to the user a grid of lights. The number of total lights and the
## number of activated lights are set by the programmer. The [LightGrid] will immediately
## emit [signal all_lights_activated] when all the lights are activated.

const _PADDING : float = 1
const _LIGHT_SPACING : float = 2
const _BASE_LIGHT_POS = Vector3(_PADDING, _PADDING, 0)

const _MIN_LIGHT_WIDTH_OR_HEIGHT : int = 1
const _MAX_LIGHT_WIDTH_OR_HEIGHT : int = 10

const _BOX_MESH_THICKNESS : float = .1

const _LIGHT_SCENE := preload("uid://dx8q4j1vvqxrn")

@export_group("Light", "light")

## The width of the [LightGrid] grid of lights.
@export var light_width : int = 3:
	get:
		return light_width
	set(value):
		light_width = clamp(value,_MIN_LIGHT_WIDTH_OR_HEIGHT,_MAX_LIGHT_WIDTH_OR_HEIGHT)
		_generate_grid()

## The height of the [LightGrid] grid of lights.
@export var light_height : int = 4:
	get:
		return light_height
	set(value):
		light_height = clamp(value,_MIN_LIGHT_WIDTH_OR_HEIGHT,_MAX_LIGHT_WIDTH_OR_HEIGHT)
		_generate_grid()

## The count of activated lights.
@export var activated_count: int = 0:
	get:
		return activated_count
	set(value):
		activated_count = clamp(value,0,_light_count)
		_generate_grid()
		if (activated_count == _light_count):
			all_lights_activated.emit()
var _light_count: int:
	get:
		return light_width * light_height

## Signal emited when all lights are activated.
signal all_lights_activated

## Sets the percentage of activated lights with [code]0.0[/code] meaning no lights activated
## and [code]1.0[/code] meaning all lights activated. For example, calling this method
## on a [LightGrid] with 10 lights would cause 5 of its lights be to activated.
func set_activated_percentage(percent: float) -> void:
	activated_count = floor(_light_count * percent)

## Returns the current number of lights.[br][br]
## [b]Note:[/b] This method returns the total number of lights, not the number of activated lights.
## To get a count of activated lights, use [method get_activated_count].
func get_light_count() -> int:
	return _light_count

## Returns the current number of activated lights.
func get_activated_count() -> int:
	return activated_count

func _ready() -> void:
	_generate_grid()


func _generate_grid() -> void:
	
	# Generate bounding box
	var boxMesh := BoxMesh.new()
	boxMesh.size = Vector3(
		(2 * _PADDING) + (light_width - 1) * _LIGHT_SPACING,
		(2 * _PADDING) + (light_height - 1) * _LIGHT_SPACING,
		_BOX_MESH_THICKNESS
	)
	self.mesh = boxMesh
	
	# Generate lights
	for child in get_children():
		if child is LightGridLight:
			child.queue_free()
	for i in range(_light_count):
		var light : LightGridLight = _LIGHT_SCENE.instantiate()
		add_child(light)
		light.set_state(LightGridLight.LightStates.LIGHT_ON if i < activated_count else LightGridLight.LightStates.LIGHT_OFF)
		@warning_ignore("integer_division")
		light.position = _BASE_LIGHT_POS + Vector3(
			((i % light_width) * _LIGHT_SPACING) - boxMesh.size.x / 2,
			((i / light_width) * _LIGHT_SPACING) - boxMesh.size.y / 2,
			0
		)
	

	
	print("Grid Generated with {0} lights".format([_light_count]))
	
