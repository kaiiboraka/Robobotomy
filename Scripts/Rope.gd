@tool
class_name Rope
extends Interactable

const MAX_CLIMB_HEIGHT: float = 0.5
const ROPE_PIECE = preload("uid://yvtcuq6ss8uf")

@export_group("Rope Shape")
## The length of the rope, with a minimum of 0.1 length.
@export_range(0.1, 10.0, 0.1, "or_greater") var ropeLength: float = 10.0:
	set(value):
		ropeLength = max(value, 0.1)
		_update_rope_geometry()
## The number of segments that the rope will be separated into. The higher the value, the more smooth (and computationally demanding) the rope.
@export_range(1, 64, 1, "or_greater") var segmentCount: int = 8:
	set(value):
		segmentCount = max(value, 1)
		_update_rope_geometry()
## The radius of the rope's mesh.
@export_range(0.01, 1.0, 0.01, "or_greater") var ropeRadius: float = 0.1:
	set(value):
		ropeRadius = max(value, 0.01)
		_update_rope_geometry()
## The radius of the grabbable area that the Player can grab the rope.
@export_range(0.01, 3.0, 0.01, "or_greater") var grabRadius: float = 0.8:
	set(value):
		grabRadius = max(value, 0.01)
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
# Variables used to manage the rope's geometry when it is changed in the editor
@onready var ropeMesh: MeshInstance3D = $"Rope Mesh"
@onready var grabArea: Area3D = $"Grabable Area"
@onready var grabShape: CollisionShape3D = $"Grabable Area/Grabable Shape"
@onready var ropeJoints: Node3D = $"Rope Joints"

# Variables used for physics manipulation
const ANGULAR_DAMPENING: float = 0.5
var angle: float = 0.0
@export_group("Physics Debugging")
@export var angularVelocity: float = 0.0 # NOTE: @export is meant for testing and debugging purposes only
@export var weightPosition: float = 0.0 # NOTE: @export is meant for testing and debugging purposes only
var weightValue: float = 0.0
var pieceList: Array[RopePiece] = []
var jointList: Array[PinJoint3D] = []
var segmentLength: float = 1.0

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
	if segmentCount != pieceList.size():
		segmentLength = ropeLength / segmentCount
		if !Engine.is_editor_hint():
			for piece: RopePiece in pieceList:
				piece.queue_free()
			for joint: PinJoint3D in jointList:
				joint.queue_free()
			
			for i in range(segmentCount):
				var newPiece: RopePiece = ROPE_PIECE.instantiate() as RopePiece
				ropeJoints.add_child(newPiece)
				newPiece._set_piece_geometry(segmentLength, ropeRadius * 2)
				newPiece.position = Vector3(0, -segmentLength * i, 0)
				pieceList.append(newPiece)
			for i in range(segmentCount - 1):
				var newJoint: PinJoint3D = PinJoint3D.new()
				ropeJoints.add_child(newJoint)
				newJoint.node_a = pieceList[i].get_path()
				newJoint.node_b = pieceList[i + 1].get_path()
		else:
			for i in range(segmentCount):
				var newPiece: MeshInstance3D = MeshInstance3D.new()
				var mesh: CylinderMesh = CylinderMesh.new()
				mesh.height = segmentLength
				mesh.cap_bottom = ropeRadius
				mesh.cap_bottom = ropeRadius
				newPiece.mesh = mesh
				newPiece.position = Vector3(0 ,-segmentLength * i, 0)
				ropeJoints.add_child(newPiece)
	
	#Update the mesh length
	var mesh = ropeMesh.mesh as CylinderMesh
	mesh.height = ropeLength
	mesh.top_radius = ropeRadius
	mesh.bottom_radius = ropeRadius
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
