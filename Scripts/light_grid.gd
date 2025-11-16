@tool
class_name LightGrid extends MeshInstance3D

const PADDING : float = 1
const LIGHT_SPACING : float = 2
const BASE_LIGHT_POS = Vector3(PADDING, PADDING, 0)

const MIN_LIGHT_WIDTH_OR_HEIGHT : int = 1
const MAX_LIGHT_WIDTH_OR_HEIGHT : int = 10

const BOX_MESH_THICKNESS : float = .1

const light_scene := preload("uid://dx8q4j1vvqxrn")

@export_group("Light", "light")
@export var light_width : int = 3:
	get:
		return light_width
	set(value):
		light_width = clamp(value,MIN_LIGHT_WIDTH_OR_HEIGHT,MAX_LIGHT_WIDTH_OR_HEIGHT)
		_generate_grid()
@export var light_height : int = 4:
	get:
		return light_height
	set(value):
		light_height = clamp(value,MIN_LIGHT_WIDTH_OR_HEIGHT,MAX_LIGHT_WIDTH_OR_HEIGHT)
		_generate_grid()
#@export_tool_button("Generate Grid") var generate_grid_action = _generate_grid
@export var activated_count: int = 0:
	get:
		return activated_count
	set(value):
		activated_count = clamp(value,0,light_count)
		_generate_grid()
var light_count: int:
	get:
		return light_width * light_height

func _ready() -> void:
	_generate_grid()


func _generate_grid() -> void:
	
	# Generate bounding box
	var boxMesh := BoxMesh.new()
	boxMesh.size = Vector3(
		(2 * PADDING) + (light_width - 1) * LIGHT_SPACING,
		(2 * PADDING) + (light_height - 1) * LIGHT_SPACING,
		BOX_MESH_THICKNESS
	)
	self.mesh = boxMesh
	
	# Generate lights
	for child in get_children():
		if child is LightGridLight:
			child.queue_free()
	for i in range(light_count):
		var light : LightGridLight = light_scene.instantiate()
		add_child(light)
		light.set_state(LightGridLight.LightStates.LIGHT_ON if i < activated_count else LightGridLight.LightStates.LIGHT_OFF)
		@warning_ignore("integer_division")
		light.position = BASE_LIGHT_POS + Vector3(
			((i % light_width) * LIGHT_SPACING) - boxMesh.size.x / 2,
			((i / light_width) * LIGHT_SPACING) - boxMesh.size.y / 2,
			0
		)
	

	
	print("Grid Generated with {0} lights".format([light_count]))
	
