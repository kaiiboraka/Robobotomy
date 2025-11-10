@tool
class_name LightGrid extends Node3D

const PADDING : int = 200
const LIGHT_SPACING : int = 500

@export_group("Light", "light")
@export var light_width : int = 3
@export var light_height : int = 4
@export_tool_button("Generate Grid") var generate_grid_action = generate_grid
@export var activated_count: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func generate_grid() -> void:
	print("test")
	
