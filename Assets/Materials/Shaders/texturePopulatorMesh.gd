#extends Node
extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Grab all the right shader and params files to populate
	var parentDir := "res://Assets/Materials/Shaders/"
	#var dirs = ["Wood", "Metal", "Concrete"]
	#var dirs = ["Wood"]
	#for dir in dirs:
	var path = parentDir + "Wood"
	var folder := DirAccess.open(path)
	var mesh = self.mesh
	var i := 0
	var params
	var mat := ShaderMaterial.new()
	var baseColor
	var height
	var metallic
	var normal
	var roughness
	for file in folder.get_files():
		if i == 0: params = FileAccess.open(path + "/" + file, FileAccess.READ)
		elif i == 1: mat.shader = load(path + "/" + file)
		elif i == 2: baseColor = load(path + "/" + file)
		elif i == 3: height = load(path + "/" + file)
		elif i == 4: metallic = load(path + "/" + file)
		elif i == 5: normal = load(path + "/" + file)
		elif i == 6: roughness = load(path + "/" + file)
		i += 1
	# Populate the shader with the needed params and textures
	var hue
	var sat
	var val
	i = 0
	while not params.eof_reached():
		var line = params.get_line()
		if i == 0: hue = float(line)
		elif i == 1: sat = float(line)
		elif i == 2: val = float(line)
		elif i > 2: break
		i += 1
		
	mat.set_shader_parameter("Hue", hue)
	mat.set_shader_parameter("Saturation", sat)
	mat.set_shader_parameter("Value", val)
	
	mat.set_shader_parameter("Base_color", baseColor)
	mat.set_shader_parameter("Metallic", metallic)
	mat.set_shader_parameter("Edge_Map", normal)
	mat.set_shader_parameter("Roughness", roughness)
	
	self.set_surface_override_material(0, mat)
		
	#var dir := DirAccess.open(parentDir)
	#var shaders := []
	#var shaderRegex = RegEx.new()
	#shaderRegex.compile("\b(?:wood|metal|concrete)Shader.tres\b")
	#var params := []
	#var paramsRegex = RegEx.new()
	#paramsRegex.compile("")
	#for file in dir.get_files():
		#if shaderRegex.search(file):
			#shaders.append(load(parentDir + "/" + file))
		#elif paramsRegex.search(file):
			#params.append(load(parentDir + "/" + file))
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
