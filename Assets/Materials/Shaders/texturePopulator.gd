extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Grab all the right shader and params files to populate
	var parentDir := "res://Assets/Materials/Shaders/"
	var dirs = ["Wood", "Metal", "Concrete"]
	for dir in dirs:
		var path = parentDir + dir
		var folder := DirAccess.open(path)
		var i := 0
		for file in folder.get_files():
			if i == 0: var param := load(path + "/" + file)
			elif i == 1: var shader := load(path + "/" + file)
			elif i == 2: var baseColor := load(path + "/" + file)
			elif i == 3: var height := load(path + "/" + file)
			elif i == 4: var metallic := load(path + "/" + file)
			elif i == 5: var normal := load(path + "/" + file)
			elif i == 6: var roughness := load(path + "/" + file)
			i += 1
		# Populate the shader with the needed params and textures
	
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
