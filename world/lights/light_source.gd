@tool
class_name LightSource
extends MeshInstance3D

#invisible by default 
#MeshInstance3D has a location, so dont change it to anything else

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		update_material_color()
	
func _ready() -> void:
	if Engine.is_editor_hint():
		# primitive capsule shape in the editor with default dimensions
		var capsule = CapsuleMesh.new()
		capsule.radius = .5  
		capsule.height = 1.0 
		mesh = capsule
		
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.wireframe_enabled = true
		material_override = mat
		update_material_color()
		
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		# game runs, make it completely invisible
		visible = false

func _process(_delta: float) -> void:
	pass

func update_material_color() -> void:
	if material_override:
		material_override.albedo_color = color
