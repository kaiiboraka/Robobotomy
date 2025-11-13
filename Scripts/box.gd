@tool
class_name Box
extends RigidBody3D

enum SIZE_PRESET {SMALL, MEDIUM, LARGE}
const SMALL_PRESET: Vector4 = Vector4(1.0, 1.0, 1.0, 1.0)
const MEDIUM_PRESET: Vector4 = Vector4(2.0, 2.0, 2.0, 2.0)
const LARGE_PRESET: Vector4 = Vector4(3.0, 3.0, 3.0, 3.0)
const PRESETS: Dictionary = {
	SIZE_PRESET.SMALL: SMALL_PRESET,
	SIZE_PRESET.MEDIUM: MEDIUM_PRESET,
	SIZE_PRESET.LARGE: LARGE_PRESET
}
@export_group("Physics Attributes")
## Determines the size and weight preset of the box. NOTE: These values can still be modified manually if desired,
## but will overwrite any manual changes to the size and weight of the box if selected.
@export var sizePreset: SIZE_PRESET = SIZE_PRESET.SMALL:
	set(value):
		sizePreset = value
		if Engine.is_editor_hint():
			_set_preset()
## Determines the size of the box. NOTE: Box size has no effect on the weight, so weight must be manually adjusted
## if a heavier or lighter box is desired.
@export var boxSize: Vector3 = Vector3(1, 1, 1):
	set(value):
		boxSize = value
		if Engine.is_editor_hint():
			_set_geometry()
## Determines the weight of the box. NOTE: Weight has no effect on the size of the box, more so increasing or 
## decreasing the density of the box.
@export var weight: float = 1.0:
	set(value):
		weight = value
		if Engine.is_editor_hint():
			_set_weight()
## Determines if the box is static in its rotation and velocity. If set to true, the box cannot be rotated on axis,
## nor pushed without interacting with a handle. If set to false, the box can rotate on the X and Y axis, but not 
## the Z axis, and can also likewise be pushed on the X and Y axis.
@export var staticBox: bool = false:
	set(value):
		staticBox = value
		if Engine.is_editor_hint():
			_set_static()
@export_group("Handles")
## Set true to include a handle on the left side of the box.
@export var leftHandle: bool = false:
	set(value): 
		leftHandle = value
		if Engine.is_editor_hint():
			_set_handles()
## Set true to include a handle on the right side of the box.
@export var rightHandle: bool = false:
	set(value): 
		rightHandle = value
		if Engine.is_editor_hint():
			_set_handles()
## Set true to include a handle on top of the box.
@export var topHandle: bool = false:
	set(value): 
		topHandle = value
		if Engine.is_editor_hint():
			_set_handles()
## Set true to include a handle on the bottom of the box.
@export var bottomHandle: bool = false:
	set(value): 
		bottomHandle = value
		if Engine.is_editor_hint():
			_set_handles()
@export_group("Read Only")
## Holds the handles for the box. NOTE: SHOULD NOT BE CHANGED. IF YOU WANT TO ADD/REMOVE HANDLES,
## GO TO THE HANDLES VARIABLE GROUP.
@onready var handleArray: Array[BoxHandle] = [$"Handles/Left Handle", $"Handles/Right Handle", $"Handles/Top Handle", $"Handles/Bottom Handle"]
@onready var meshInstance: MeshInstance3D = $MeshInstance3D
@onready var collisionShape: CollisionShape3D = $"Collision Shape"
@onready var grabJoint: Generic6DOFJoint3D = $"Grab Joint"
var grabber: CharacterBody3D = null
var grabberOffset: Vector3 = Vector3.ZERO
var verticalGrab: bool = false


func grab(interactor: Node3D) -> void:
	var player: CharacterBody3D = interactor as CharacterBody3D
	if !is_instance_valid(player):
		return
	player.SetCarryWeight(weight)
	
	grabJoint.node_a = self.get_path()
	grabJoint.node_b = player.get_path()
	
	axis_lock_linear_x = false


func stop_grab(interactor: Node3D) -> void:
	var player: CharacterBody3D = interactor as CharacterBody3D
	if !is_instance_valid(player):
		return
	
	player.SetCarryWeight(0.0)
	
	grabJoint.node_a = ""
	grabJoint.node_b = ""
	_set_static()


func _ready() -> void:
	_set_geometry()
	_set_weight()
	_set_static()
	_set_handles()


#func _physics_process(_delta: float) -> void:
	#if grabber != null:
		#if !verticalGrab:
			#var dir: Vector3 = (grabber.global_position - global_position).normalized()
			#var pushStrength: float = grabber.velocity.x * 100
			#apply_central_force(-dir * pushStrength)
		#else:
			#global_position.y = grabber.global_position.y + grabberOffset.y


func _set_preset() -> void:
	boxSize = Vector3(PRESETS[sizePreset].x, PRESETS[sizePreset].y, PRESETS[sizePreset].z)
	weight = PRESETS[sizePreset].w
	_set_geometry()
	_set_weight()


func _set_geometry() -> void:
	if meshInstance == null or collisionShape == null:
		return
	var mesh: BoxMesh = meshInstance.mesh.duplicate() as BoxMesh
	mesh.size = boxSize
	meshInstance.mesh = mesh
	var shape: BoxShape3D = collisionShape.shape.duplicate() as BoxShape3D
	shape.size = boxSize
	collisionShape.shape = shape
	_set_handles()


func _set_weight() -> void:
	mass = weight


func _set_static() -> void:
	axis_lock_linear_x = staticBox
	axis_lock_linear_y = false
	axis_lock_linear_z = true
	axis_lock_angular_x = staticBox
	axis_lock_angular_y = staticBox
	axis_lock_angular_z = true


func _set_handles() -> void:
	if handleArray.size() <= 0:
		return
	for i in range(4):
		var handle: BoxHandle = handleArray[i]
		var active: bool = leftHandle if i == 0 else rightHandle if i == 1 else topHandle if i == 2 else bottomHandle
		if active:
			handle.process_mode = Node.PROCESS_MODE_INHERIT
			handle.visible = true
			if i == 0:
				handle._set_geometry(Vector3(max(boxSize.y - 0.5, 0.1), 0.1, 0.1))
				handle._set_grab_shape(Vector3(max(boxSize.y - 0.2, 0.1), 0.8, 0.8))
				handle.position.x = -(boxSize.x / 2 + 0.25)
			elif i == 1:
				handle._set_geometry(Vector3(max(boxSize.y - 0.5, 0.1), 0.1, 0.1))
				handle._set_grab_shape(Vector3(max(boxSize.y - 0.2, 0.1), 0.8, 0.8))
				handle.position.x = boxSize.x / 2 + 0.25
			elif i == 2:
				handle._set_geometry(Vector3(max(boxSize.x - 0.5, 0.1), 0.1, 0.1))
				handle._set_grab_shape(Vector3(max(boxSize.x - 0.2, 0.1), 0.8, 0.8))
				handle.position.y = boxSize.y / 2 + 0.25
			else:
				handle._set_geometry(Vector3(max(boxSize.x - 0.5, 0.1), 0.1, 0.1))
				handle._set_grab_shape(Vector3(max(boxSize.x - 0.2, 0.1), 0.8, 0.8))
				handle.position.y = -(boxSize.y / 2 + 0.25)
		else:
			handle.process_mode = Node.PROCESS_MODE_DISABLED
			handle.visible = false
