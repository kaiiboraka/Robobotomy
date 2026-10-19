class_name WoodPopulator
extends GeometryInstance3D
## Makes the wood texture work across the game, populates a mesh with the texture

var shader: Shader = preload("res://shared/materials/proc_shader.tres")
var base_color := preload("res://shared/materials/wood/wood_basecolor.png")
var height := preload("res://shared/materials/wood/wood_height.png")
var metallic := preload("res://shared/materials/wood/wood_metallic.png")
var normal := preload("res://shared/materials/wood/wood_normal.png")
var roughness := preload("res://shared/materials/wood/wood_roughness.png")
#var params := FileAccess.open("res://Assets/Materials/Shaders/Wood/woodParams.txt", FileAccess.READ)


func populate_shader(dir: String) -> ShaderMaterial:
	var path := "res://shared/materials" + dir
	var _folder := DirAccess.open(path)
	
	#var params = load("res://Assets/Materials/Shaders/Wood/woodParams.txt")
	var params := FileAccess.open("res://shared/materials/wood/wood_parameters.txt", FileAccess.READ)
	var mat := ShaderMaterial.new()
	mat.shader = shader
		
	mat.set_shader_parameter("Base_Color", base_color)
	mat.set_shader_parameter("Metallic", metallic)
	mat.set_shader_parameter("Edge_Map", normal)
	mat.set_shader_parameter("Roughness", roughness)
	
	var hue
	var sat
	var val
	var hueMin
	var hueMax
	var satMin
	var satMax
	var valMin
	var valMax
	var i = 0
	
	while not params.eof_reached():
		var line = params.get_line()
		if i == 0: hue = float(line)
		elif i == 1: sat = float(line)
		elif i == 2: val = float(line)
		elif i == 3: hueMin = float(line)
		elif i == 4: hueMax = float(line)
		elif i == 5: satMin = float(line)
		elif i == 6: satMax = float(line)
		elif i == 7: valMin = float(line)
		elif i == 8: valMax = float(line)
		elif i > 8: break
		i += 1
	
	# Jitter the values a bit for variety in the objects
	randomize()
	var jitterH = randf_range(hueMin, hueMax)
	var jitterS = randf_range(satMin, satMax)
	var jitterV = randf_range(valMin, valMax)
	#if dir == "Wood":
	hue += jitterH
	sat += jitterS
	val += jitterV
	
	print(hue, sat, val)
	
	mat.set_shader_parameter("Hue", hue)
	mat.set_shader_parameter("Saturation", sat)
	mat.set_shader_parameter("Value", val)
	
	return mat


func _ready() -> void:
	#var mesh_instance: GeometryInstance3D = $MeshInstance3D

	#var mesh = self.mesh
	
	var mat = populate_shader("Wood")
	
	self.material_override = mat
	
	print(mat.shader)
	
	#self.set_surface_override_material(0, mat)
