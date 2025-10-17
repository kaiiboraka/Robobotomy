extends Node3D

#Mostly useless enum because I couldn't figure out how to convert enum to string
#You'll notice that int and enum are interchangable
enum LimbTypes {Head, LeftArm, RightArm, Torso, LeftLeg, RightLeg}

var selectedLimb:LimbTypes = LimbTypes.Torso #Which limb is selected?
var cameraLimb:LimbTypes = LimbTypes.Torso #Which limb has the camera attached?

@export var throwSpeed:float

var cam:Camera3D

var enum_to_node:Dictionary = {}

#Mostly useless dictionary but I'm too scared to delete it
var limbs_dict = {
	0:false, #Head
	1:false, #LeftArm
	2:false, #RightArm
	3:true, #Torso
	4:false, #LeftLeg
	5:false, #RightLeg
}

var bodyObjects = {
	0:null, #Head
	1:null, #LeftArm
	2:null, #RightArm
	3:null, #Torso
	4:null, #LeftLeg
	5:null #RightLeg
}

#Controls:
#Numbers = select limb
#X = recall (right now just teleports)
#Right Click = Throw Limb

func _ready() -> void:
	enum_to_node[0] = (load("res://Scenes/Characters/Head.tscn"))
	enum_to_node[1] = (load("res://Scenes/Characters/Arm.tscn"))
	enum_to_node[2] = (load("res://Scenes/Characters/Arm.tscn"))
	enum_to_node[4] = (load("res://Scenes/Characters/Leg.tscn"))
	enum_to_node[5] = (load("res://Scenes/Characters/Leg.tscn"))
	bodyObjects[3] = get_node("Player")
	cam = get_viewport().get_camera_3d()
	pass

var hasSwapped:bool = false

func _process(_delta: float) -> void:
	#Get the button pressed
	if(Input.is_action_just_pressed("Number1")):
		selectedLimb = LimbTypes.Head
		hasSwapped = true
	if(Input.is_action_just_pressed("Number2")):
		selectedLimb = LimbTypes.LeftArm
		hasSwapped = true
	if(Input.is_action_just_pressed("Number3")):
		selectedLimb = LimbTypes.Torso
		hasSwapped = true
	if(Input.is_action_just_pressed("Number4")):
		selectedLimb = LimbTypes.RightArm
		hasSwapped = true
	if(Input.is_action_just_pressed("Number5")):
		selectedLimb = LimbTypes.LeftLeg
		hasSwapped = true
	if(Input.is_action_just_pressed("Number6")):
		selectedLimb = LimbTypes.RightLeg
		hasSwapped = true

	#if recall, find what has been recalled and destroy instatiated scene
	if(Input.is_action_just_pressed("Player_Recall")):
		if(bodyObjects[selectedLimb] != null && selectedLimb != 3):
			limbs_dict[selectedLimb] = false
			bodyObjects[selectedLimb].queue_free()
			_findLimb(selectedLimb).visible = true
			bodyObjects[selectedLimb] = null
			bodyObjects[3].bodyParts[selectedLimb] = true
			selectedLimb = LimbTypes.Torso
			hasSwapped = true
		#if recalled on torso, recall all
		elif(selectedLimb == 3):
			for i in range(6):
				if(i == 3): continue
				if(bodyObjects[i] != null):
					limbs_dict[i] = false
					bodyObjects[i].queue_free()
					_findLimb(i).visible = true
					bodyObjects[i] = null
					bodyObjects[3].bodyParts[i] = true

	#If a button has been pressed, make the camera pan to it and make it move
	if(hasSwapped):
		_swapCamera(selectedLimb)
		hasSwapped = false

	
	#If I decide to throw...
	if Input.is_action_just_pressed("Player_Throw_Limb"):
		if limbs_dict[selectedLimb] == false: #If the limb isn't seperated from torso
			if(cameraLimb == 3): #If we're actually looking at the torso when throwing
				var scene = enum_to_node[selectedLimb]
				var current_target = scene.instantiate()
				add_child(current_target)
				current_target.position = bodyObjects[3].position
				for i in range(6):
					if(i == selectedLimb):
						current_target.bodyParts[i] = true
					else:
						current_target.bodyParts[i] = false
				bodyObjects[selectedLimb] = current_target  #Dictionary nonsense
				limbs_dict[selectedLimb] = true
				bodyObjects[3].bodyParts[selectedLimb] = false
				_throwLimb(current_target)
				_findLimb(selectedLimb).visible = false
	
	

	

#Camera swapping shenanigans
func _swapCamera(targetLimb):
	if(bodyObjects[targetLimb] == null): targetLimb = 3
	for i in range(6):
			if(bodyObjects[i] == null): continue
			if(i != targetLimb):
				bodyObjects[i].isSelected = false
				bodyObjects[i].get_node("PhantomCamera3D").set_priority(0)
			else:
				cameraLimb = targetLimb
				bodyObjects[i].isSelected = true
				bodyObjects[i].get_node("PhantomCamera3D").set_priority(1)
			

#In hindsight this should've been a dictionary
func _findLimb(hiddenLimb):
	if(hiddenLimb == 0):
		return get_node("Player/Head")
	elif(hiddenLimb == 1):
		return get_node("Player/Left Arm")
	elif(hiddenLimb == 2):
		return get_node("Player/Right Arm")
	elif(hiddenLimb == 3):
		return get_node("Player/Torso")
	elif(hiddenLimb == 4):
		return get_node("Player/Left Leg")
	elif(hiddenLimb == 5):
		return get_node("Player/Right Leg")

#Find cursor and apply velocity to player script 
func _throwLimb(currentNode):

	var mouse_position = cam.project_position(get_viewport().get_mouse_position(), abs(cam.position.z - bodyObjects[3].position.z))
	var direction = bodyObjects[3].position.direction_to(Vector3(mouse_position.x,mouse_position.y,0))
	currentNode.velocity = direction * throwSpeed
