@tool
class_name Rope
extends Interactable


const MAX_CLIMB_HEIGHT: float = 0.5
@export_group("Rope Shape")
## The length of the rope, with a minimum of 0.1 length.
@export_range(0.1, 10.0, 0.1, "or_greater") var ropeLength: float = 10.0:
	set(value):
		ropeLength = max(value, 0.1)
		if Engine.is_editor_hint():
			_update_rope_geometry()
@export_group("Physics Parameters")
## Gravity of the rope. NOTE: THIS VARIABLE MAY BE CHANGED BY A GLOBAL GRAVITY VARIABLE LATER
@export var gravity: float = -100.0
## Launch force increases the force the Player is launched from jumping off of the rope
@export var launchForce: float = 4.0
## Climbing speed determines how fast the Player can climb the rope. This is a multiplier to their normal speed.
@export var climbSpeed: float = 0.2
## Slide speed determines how fast the Player slides down the rope. This is a mutliplier to their normal speed.
@export var slideSpeed: float = 1.0
## Angular dampening determines how quickly the rope slows down its angular velocity over time (like angular friction).
@export var angularDampening: float = 0.5
# Variables used to manage the rope's geometry when it is changed in the editor
@onready var ropeMesh: MeshInstance3D = $"Rope Mesh"
@onready var grabArea: Area3D = $"Grabable Area"
@onready var grabShape: CollisionShape3D = $"Grabable Area/Grabable Shape"
# Variables used for physics manipulation
@export_group("Physics Debugging")
@export var angularVelocity: float = 0.0 # NOTE: @export is meant for testing and debugging purposes only
@export var weightPosition: float = 0.0 # NOTE: @export is meant for testing and debugging purposes only
var weightValue: float = 0.0
var angle: float = 0.0

func _ready() -> void:
	_update_rope_geometry()


func _physics_process(delta: float) -> void:
	var pivotPoint: float = weightPosition if weightPosition > 0.001 else ropeLength
	var angularAccel: float = (gravity / pivotPoint) * sin(angle)
	angularVelocity += angularAccel * delta
	angle += angularVelocity * delta
	_update_rope_angle()
	angularVelocity *= 1 - angularDampening * delta
	#print("Angular Velocity: ", angularVelocity, ", Angular Acceleration: ", angularAccel, ", Angle: ", angle)


## This function updates the length of the rope to match the ropeLength variable, and can be set in the editor
func _update_rope_geometry() -> void: 
	if ropeMesh == null or grabShape == null:
		return
	#Update the mesh length
	var mesh = ropeMesh.mesh.duplicate() as CylinderMesh
	mesh.height = ropeLength
	#Update the area length
	var shape = grabShape.shape.duplicate() as BoxShape3D
	shape.size.y = ropeLength + 0.5
	#Reposition mesh and area
	ropeMesh.position = Vector3(0, -(ropeLength / 2), 0)
	grabArea.position = Vector3(0, -((ropeLength + 0.5) / 2), 0)
	#Set the mesh and area
	ropeMesh.mesh = mesh
	grabShape.shape = shape


## This function updates the angle of the rope
func _update_rope_angle() -> void:
	rotation.z = angle
	

## This function calculates a starting angle to get the rope moving, and puts a weight point on the rope
func interact_with(interactor: Node3D, transferMomentum: bool = true) -> void:
	var grabber: CharacterBody3D = interactor as CharacterBody3D
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


func stop_interaction(_interactor: Node3D) -> void:
	weightPosition = 0.0


func get_tangental_velocity() -> Vector3:
	var tangent = Vector3(cos(angle), sin(angle), 0)
	var tangentSpeed = angularVelocity * weightPosition
	return tangent * tangentSpeed * launchForce


func get_rope_point() -> Vector3:
	#print("Weight Position: ", weightPosition, "\nX: ", weightPosition * sin(angle), "\nY: ", -weightPosition * cos(angle))
	return Vector3(weightPosition * sin(angle), -weightPosition * cos(angle), 0) + global_position


func push_rope(dir: Vector3, force: float) -> void:
	if weightPosition < 0.001:
		return
	var tangentDir = Vector3(cos(angle), -sin(angle), 0)
	var tangentalForce = dir.dot(tangentDir) * force
	var angularAccel = tangentalForce / weightPosition
	angularVelocity += angularAccel


func climb_rope(dir: Vector3, speed: float) -> void:
	#print("Direction: ", dir, ", Speed: ", speed)
	var dirSpeed: float = climbSpeed if dir.y < 0.0 else (slideSpeed if dir.y > 0.0 else 0.0)
	weightPosition += dir.y * speed * dirSpeed
	weightPosition = clampf(weightPosition, MAX_CLIMB_HEIGHT, ropeLength)
