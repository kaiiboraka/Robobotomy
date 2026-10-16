#extends Node3D
#extends MeshInstance3D
extends GeometryInstance3D

var shader: Shader = preload("res://Assets/Materials/Shaders/procShader.tres")
var baseColor := preload("res://Assets/Materials/Shaders/Metal/Metal_basecolor.png")
var height := preload("res://Assets/Materials/Shaders/Metal/Metal_height.png")
var metallic := preload("res://Assets/Materials/Shaders/Metal/Metal_metallic.png")
var normal := preload("res://Assets/Materials/Shaders/Metal/Metal_normal.png")
var roughness := preload("res://Assets/Materials/Shaders/Metal/Metal_roughness.png")
#var params := FileAccess.open("res://Assets/Materials/Shaders/Wood/woodParams.txt", FileAccess.READ)

func populateShader(dir: String) -> ShaderMaterial:
	var path := "res://Assets/Materials/Shaders/" + dir
	var folder := DirAccess.open(path)
	
	#var params = load("res://Assets/Materials/Shaders/Wood/woodParams.txt")
	var params := FileAccess.open("res://Assets/Materials/Shaders/Wood/woodParams.txt", FileAccess.READ)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	#var baseColor
	#var height
	#var metallic
	#var normal
	#var roughness
	
	#var i = 0
	#
	#for file in folder.get_files():
		#if i == 0: params = FileAccess.open(path + "/" + file, FileAccess.READ)
		#elif i == 1: mat.shader = load(path + "/" + file)
		#elif i == 2: baseColor = load(path + "/" + file)
		#elif i == 3: height = load(path + "/" + file)
		#elif i == 4: metallic = load(path + "/" + file)
		#elif i == 5: normal = load(path + "/" + file)
		#elif i == 6: roughness = load(path + "/" + file)
		#i += 1
		
	mat.set_shader_parameter("Base_Color", baseColor)
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var mesh_instance: GeometryInstance3D = $MeshInstance3D

	#var mesh = self.mesh
	
	var mat = populateShader("Wood")
	
	self.material_override = mat
	
	print(mat.shader)
	
	#self.set_surface_override_material(0, mat)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
