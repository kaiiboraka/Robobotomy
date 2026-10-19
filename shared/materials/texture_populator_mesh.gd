class_name TexturePopulatorMesh
extends MeshInstance3D
## A mesh that is populated with various textures

func _ready() -> void:
	# Grab all the right shader and params files to populate
	var parentDir := "res://shared/materials/"
	#var dirs = ["Wood", "Metal", "Concrete"]
	#var dirs = ["Wood"]
	#for dir in dirs:
	var path = parentDir + "wood"
	var folder := DirAccess.open(path)
	var _mesh = self.mesh
	var i := 0
	var params
	var mat := ShaderMaterial.new()
	var baseColor
	var _height
	var metallic
	var normal
	var roughness
	for file in folder.get_files():
		if i == 0: params = FileAccess.open(path + "/" + file, FileAccess.READ)
		elif i == 1: mat.shader = load(path + "/" + file)
		elif i == 2: baseColor = load(path + "/" + file)
		elif i == 3: _height = load(path + "/" + file)
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
