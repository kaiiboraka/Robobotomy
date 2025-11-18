@tool
class_name Ladder
extends Climbable

const RUNG = preload("uid://3l8c2up5trrm")

@export_group("Shape Properties")
@export_range(0.1, 10.0, 0.1, "or_greater") var length: float = 10.0:
	set(value):
		length = maxf(0.1, value)
		if is_inside_tree():
			_set_length()
@export_range(0.1, 2.0, 0.05, "or_greater") var width: float = 1.0:
	set(value):
		width = maxf(0.1, value)
		if is_inside_tree():
			_set_width()
@export_range(0.001, 0.5, 0.001, "or_greater") var poleWidth: float = 0.1:
	set(value):
		poleWidth = maxf(0.01, value)
		if is_inside_tree():
			_set_pole_width()
@export_subgroup("Rung Parameters")
@export_range(0, 99, 1, "or_greater") var rungCount: int = 10:
	set(value):
		rungCount = maxi(0, value)
		if is_inside_tree():
			_calculate_density()
@export_range(0.001, 0.4, 0.001, "or_greater") var rungWidth: float = 0.05:
	set(value):
		rungWidth = maxf(0.01, value)
		if is_inside_tree():
			_set_rung_geometry()
@export_range(0.0, 1.0, 0.05, "or_greater") var topRungGap: float = 0.1:
	set(value):
		topRungGap = maxf(0.0, value)
		if is_inside_tree():
			_calculate_density()
@export_range(0.0, 1.0, 0.05, "or_greater") var bottomRungGap: float = 0.1:
	set(value):
		bottomRungGap = maxf(0.0, value)
		if is_inside_tree():
			_calculate_density()
@onready var leftPole: MeshInstance3D = $"Ladder Pole Left"
@onready var rightPole: MeshInstance3D = $"Ladder Pole Right"
@onready var leftPoleMesh: CylinderMesh = leftPole.mesh.duplicate() as CylinderMesh
@onready var rightPoleMesh: CylinderMesh = rightPole.mesh.duplicate() as CylinderMesh
@onready var grabAreaShape: CollisionShape3D = $"Grabable Area/Grabable Shape"
@onready var grabShape: BoxShape3D = grabAreaShape.shape.duplicate() as BoxShape3D
@onready var rungContainer: Node3D = $Rungs
var rungArray: Array[LadderRung]
var rungDensity: float = 1.0

func _ready() -> void:
	leftPole.mesh = leftPoleMesh
	rightPole.mesh = rightPoleMesh
	grabAreaShape.shape = grabShape
	
	if !Engine.is_editor_hint():
		_set_length()
		_set_width()
		_set_pole_width()


func interact_with(interactor: Node3D) -> void:
	var grabber: CharacterBody3D = interactor as CharacterBody3D
	if !is_instance_valid(grabber):
		return
	
	var distToLadder = global_position - grabber.global_position
	distToLadder.z = 0
	grabPosition = distToLadder.length()
	

func stop_interaction(_interactor: Node3D) -> void:
	grabPosition = 0.0


func get_grab_point() -> Vector3:
	return Vector3(global_position.x, global_position.y + clampf(grabPosition, lowerClimbLimit, length - upperClimbLimit), 0)


func climb(dir: Vector3, speed: float) -> void:
	var dirSpeed: float = climbSpeed if dir.y < 0.0 else (slideSpeed if dir.y > 0.0 else 0.0)
	grabPosition -= dir.y * speed * dirSpeed
	grabPosition = clampf(grabPosition, lowerClimbLimit, length - upperClimbLimit)


func jump_off() -> Vector3:
	return Vector3.ZERO

# NOTE: Ladders cannot be pushed, but perhaps later functionality could be added to do something else while pushing the ladder
func push(_dir: Vector3, _force: float) -> void:
	pass
	

func _set_length() -> void:
	leftPoleMesh.height = length
	rightPoleMesh.height = length
	leftPole.position.y = length / 2.0
	rightPole.position.y = length / 2.0
	grabShape.size = Vector3(width, length + 0.5, 1.0)
	grabAreaShape.position.y = (length + 0.5) / 2.0
	_calculate_density()


func _set_width() -> void:
	leftPole.position.x = -(width / 2)
	rightPole.position.x = width / 2
	grabShape.size = Vector3(width, length + 0.5, 1.0)
	_set_rung_geometry()


func _set_pole_width() -> void:
	leftPoleMesh.bottom_radius = poleWidth
	leftPoleMesh.top_radius = poleWidth
	rightPoleMesh.bottom_radius = poleWidth
	rightPoleMesh.top_radius = poleWidth
	_set_rung_geometry()


func _calculate_density() -> void:
	
	rungDensity = (length - topRungGap - bottomRungGap) / (maxf(rungCount, 2.0) - 1.0)
	_set_rungs()


func _set_rungs() -> void:
	for i in range(rungArray.size()):
		var rung: LadderRung = rungArray[i]
		rung.queue_free()
	rungArray.clear()
	for i in range(rungCount):
		var newRung: LadderRung = RUNG.instantiate() as LadderRung
		rungContainer.add_child(newRung)
		if Engine.is_editor_hint():
			newRung.owner = get_tree().edited_scene_root
		rungArray.append(newRung)
	_set_rung_spacing()


func _set_rung_spacing() -> void:
	for i in range(rungArray.size()):
		var rung: LadderRung = rungArray[i]
		rung.position.y = bottomRungGap + (rungDensity * i)


func _set_rung_geometry() -> void:
	for rung: LadderRung in rungArray:
		rung._update_geometry(width - (poleWidth / 2.0), rungWidth)
