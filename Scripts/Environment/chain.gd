@tool
class_name Chain extends Node3D

# --- Chain Shape ---
var _link_count: int = 10
@export_group("Chain Shape")
@export_range(0,100,1) var length: int = 0:
	get: return _link_count
	set(value):
		_link_count = max(value, 0)
		if Engine.is_editor_hint():
			update_chain_geometry()

@export var link_spacing: float = 0.225:
	set(value):
		link_spacing = max(value, 0.01)
		if Engine.is_editor_hint():
			update_chain_geometry()

# --- Physics Parameters ---
@export_group("Physics Parameters")
@export var gravity: float = -100.0
@export var launch_force: float = 10.0
@export var angular_dampening: float = 0.5
@export var constraint_iterations: int = 100:
	set(value):
		constraint_iterations = max(value, 1)
@export var damping: float = 0.99:
	set(value):
		damping = clamp(value, 0.0, 1.0)

# --- Debug ---
@export_group("Physics Debugging")
@export var angular_velocity: float = 0.0

# --- Chain Geometry ---
#@onready var chain_mesh = $ChainMesh
@onready var grabbable_area = $GrabbableArea
@onready var grabbable_shape = $GrabbableArea/GrabbableShape

@export_group("Player Limit Parameters")
@export var climb_speed: float = 3.0
@export var slide_speed: float = 5.0
@export var lower_climb_limit: float = 1.0
@export var upper_climb_limit: float = 1.0
var grab_position: float
var _angle: float = 0.0

# --- Chain System ---
#var chain_link_mesh: Mesh = preload("res://Assets/3D/Objects/chain_link.res")
const chain_link_mesh : Mesh = preload("uid://dwkxg4rigpq0d")

class ChainPoint:
	var position: Vector3
	var prev_position: Vector3
	var locked: bool

var points: Array[ChainPoint] = []
var link_mesh_instances: Array[MeshInstance3D] = []

func _ready():
	update_chain_geometry()

func _physics_process(delta: float):
	if not Engine.is_editor_hint() and points.size() > 1:
		apply_angular_velocity_to_chain(delta)
		simulate(delta)
		update_link_transforms()
		angular_velocity *= 1 - angular_dampening * delta

	_angle = derive_angle()
	update_chain_angle()

func apply_angular_velocity_to_chain(delta: float):
	var tangent_dir = Vector3(cos(_angle), -sin(_angle), 0)
	for i in range(1, points.size()):
		var p = points[i]
		if p.locked:
			continue
		var dist = i * link_spacing
		var tangent_speed = angular_velocity * dist
		var desired_vel = tangent_dir * tangent_speed
		p.prev_position = p.position - desired_vel * delta

func simulate(delta: float):
	for i in range(1, points.size()):
		var p = points[i]
		if p.locked:
			continue
		var vel = p.position - p.prev_position
		p.prev_position = p.position
		p.position += vel * damping
		p.position += Vector3.DOWN * -gravity * delta * delta

	for _iter in range(constraint_iterations):
		for i in range(points.size() - 1):
			var p1 = points[i]
			var p2 = points[i + 1]
			var diff = Vector3(p2.position.x - p1.position.x, p2.position.y - p1.position.y, 0)
			var dist = diff.length()
			if dist < 0.0001:
				continue
			var error = dist - link_spacing
			var correction = diff * (error / dist) * 0.5
			if not p1.locked:
				p1.position.x += correction.x
				p1.position.y += correction.y
			if not p2.locked:
				p2.position.x -= correction.x
				p2.position.y -= correction.y
			p1.position.z = 0
			p2.position.z = 0

func derive_angle() -> float:
	if points.size() < 2:
		return 0.0
	var offset = points[-1].position - points[0].position
	return atan2(offset.x, -offset.y)

## --------------------------------------------------------
## ROPE GEOMETRY
## --------------------------------------------------------
func sync_link_count(count: int):
	var existing: Array[MeshInstance3D] = []
	for child in get_children():
		var mi = child as MeshInstance3D
		if mi != null: # and mi != chain_mesh:
			existing.append(mi)

	link_mesh_instances.clear()
	for i in range(count):
		if i < existing.size():
			var mi = existing[i]
			mi.name = "Link%d" % i
			link_mesh_instances.append(mi)
		else:
			var mi = MeshInstance3D.new()
			mi.mesh = chain_link_mesh
			mi.name = "Link%d" % i
			#mi.owner = self
			add_child(mi)
			link_mesh_instances.append(mi)

	for i in range(count, existing.size()):
		remove_child(existing[i])
		existing[i].queue_free()

func update_chain_geometry():
	points.clear()

	var count = _link_count
	for i in range(count + 1):
		var p = ChainPoint.new()
		p.position = Vector3(0, -i * link_spacing, 0)
		p.prev_position = p.position
		p.locked = i == 0
		points.append(p)

	sync_link_count(count)
	update_link_transforms()

	if grabbable_shape != null and grabbable_shape.shape != null:
		var shape = grabbable_shape.shape.duplicate() as BoxShape3D
		shape.size = Vector3(shape.size.x, _link_count * link_spacing + 0.5, shape.size.z)
		grabbable_shape.shape = shape

	if grabbable_area != null:
		grabbable_area.position = Vector3(0, -(_link_count * link_spacing + 0.5) / 2, 0)

	#if chain_mesh != null:
		#chain_mesh.visible = false

func update_link_transforms():
	for i in range(link_mesh_instances.size()):
		var p1 = points[i]
		var p2 = points[i + 1]
		var mid = (p1.position + p2.position) * 0.5

		var mi = link_mesh_instances[i]
		mi.position = mid
		mi.rotation.y = deg_to_rad(90) if i % 2 == 1 else 0.0

func update_chain_angle():
	rotation = Vector3(rotation.x, rotation.y, _angle)

## --------------------------------------------------------
## INTERACTION LOGIC
## --------------------------------------------------------
func on_player_enter(player: Node3D):
	if player is Player:
		interact_with(player)

func interact_with(player: Player):
	print("Interacting")
	if not player.r_arm or player.r_arm.is_detached or not player.l_arm or player.l_arm.is_detached:
		return

	player.grab_chain(self)

	var distToChain: Vector3 = global_position - player.get_grab_location()
	distToChain.z = 0

	grab_position = clamp(distToChain.length(), lower_climb_limit, _link_count * link_spacing - upper_climb_limit)

	var chainDir: Vector3 = distToChain.normalized()
	var tangentDir: Vector3 = Vector3(chainDir.y, -chainDir.x, 0)
	var tangentSpeed: float = player.velocity.dot(tangentDir)
	
	angular_velocity += tangentSpeed / grab_position

func stop_interaction(interactor: Node3D):
	grab_position = 0.0

func jump_off() -> Vector3:
	var tangent: Vector3 = Vector3(cos(_angle), 0, 0)
	var tangentSpeed: float = angular_velocity * grab_position
	angular_velocity = 0
	return tangent * tangentSpeed * launch_force

func get_grab_point() -> Vector3:
	return Vector3(
		grab_position * sin(_angle),
		-grab_position * cos(_angle),
		0
	) + global_position

func push(dir: Vector3, force: float):
	if grab_position < 0.001:
		return

	var tangentDir: Vector3 = Vector3(cos(_angle), -sin(_angle), 0)
	var tangentialForce: float = dir.dot(tangentDir) * force
	var angularAccel: float = tangentialForce / grab_position

	angular_velocity += angularAccel

func climb(dir: Vector3, speed: float):
	var dirSpeed: float = climb_speed if dir.y < 0 else slide_speed if dir.y > 0 else 0
	grab_position += dir.y * speed * dirSpeed
	grab_position = clamp(grab_position, lower_climb_limit, _link_count * link_spacing - upper_climb_limit)
