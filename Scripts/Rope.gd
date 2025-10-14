@tool
class_name Rope
extends Interactable

## The length of the rope, with a minimum of 0 length.
@export_range(0.1, 10.0, 0.1, "or_greater") var ropeLength: float = 10.0:
	set(value):
		ropeLength = max(value, 0.1)
		_update_rope_geometry()
## Gravity of the rope. NOTE: THIS VARIABLE MAY BE CHANGED BY A GLOBAL GRAVITY VARIABLE LATER
@export var gravity: float = -100.0
# Variables used to manage the rope's geometry when it is changed in the editor
@onready var ropeMesh: MeshInstance3D = $"Rope Mesh"
@onready var grabArea: Area3D = $"Grabable Area"
@onready var grabShape: CollisionShape3D = $"Grabable Area/Grabable Shape"
# Variables used for physics manipulation
const ANGULAR_DAMPENING: float = 0.5
var angle: float = 0.0
@export var angularVelocity: float = 5.0 # NOTE: @export is meant for testing and debugging purposes only
@export var weightPosition: float = 0 # NOTE: @export is meant for testing and debugging purposes only
var weightValue: float = 0.0


func _ready() -> void:
	_update_rope_geometry()


func _physics_process(delta: float) -> void:
	if weightPosition < 0.001: 
		return
	
	var angularAccel: float = (gravity / weightPosition) * sin(angle)
	angularVelocity += angularAccel * delta
	angle += angularVelocity * delta
	_update_rope_angle()
	angularVelocity *= 1 - ANGULAR_DAMPENING * delta
	#print("Angular Velocity: ", angularVelocity, ", Angle: ", angle)


## This function updates the length of the rope to match the ropeLength variable, and can be set in the editor
func _update_rope_geometry() -> void: 
	#Update the mesh length
	var mesh = ropeMesh.mesh as CylinderMesh
	mesh.height = ropeLength
	#Update the area length
	var shape = grabShape.shape as BoxShape3D
	shape.size.y = ropeLength + 0.5
	#Reposition mesh and area
	ropeMesh.position = Vector3(0, -(ropeLength / 2), 0)
	grabArea.position = Vector3(0, -((ropeLength + 0.5) / 2), 0)


## This function updates the angle of the rope
func _update_rope_angle() -> void:
	rotation.z = angle
	

## This function calculates a starting angle to get the rope moving, and puts a weight point on the rope
func interact_with(grabber: CharacterBody3D, transferMomentum: bool = true) -> void:
	if !is_instance_valid(grabber):
		return
	
	var distToRope = global_position - grabber.global_position
	distToRope.z = 0
	weightPosition = distToRope.length()
	if (grabber.has_method("get_weight")):
		weightValue = grabber.get_weight()
	else:
		weightValue = 10
	
	if (transferMomentum):
		var ropeDir: Vector3 = distToRope.normalized()
		var tangentDir: Vector3 = Vector3(ropeDir.y, -ropeDir.x, 0)
		var tangentSpeed: float = grabber.velocity.dot(tangentDir)
		angularVelocity += tangentSpeed / weightPosition


func get_tangental_velocity() -> Vector3:
	var tangent = Vector3(cos(angle), -sin(angle), 0)
	var tangentSpeed = angularVelocity * weightPosition
	return tangent * tangentSpeed


func get_rope_point() -> Vector3:
	return Vector3(weightPosition * sin(angle), -weightPosition * cos(angle), 0)
