@tool
class_name LightGrid extends Node3D

const PADDING : int = 1
const LIGHT_SPACING : int = 2
const BASE_LIGHT_POS = Vector3(PADDING, PADDING, 0)

const light_scene := preload("uid://dx8q4j1vvqxrn")

@export_group("Light", "light")
@export var light_width : int = 3
@export var light_height : int = 4
@export_tool_button("Generate Grid") var generate_grid_action = generate_grid
@export var activated_count: int

var light_count: int:
	get:
		return light_width * light_height

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body


func generate_grid() -> void:
	get_children().map(func(child) : child.queue_free())
	for i in range(light_count):
		var light : LightGridLight = light_scene.instantiate()
		add_child(light)
		@warning_ignore("integer_division")
		light.position = BASE_LIGHT_POS + Vector3(
			(i % light_width) * LIGHT_SPACING,
			(i / light_width) * LIGHT_SPACING,
			0
		)
	print("Grid Generated with {0} lights".format([light_count]))
	
