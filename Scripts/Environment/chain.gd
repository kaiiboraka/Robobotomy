@tool
class_name Chain extends Node3D

# --- Chain Shape ---
var _link_count: int = 10
@export_group("Chain Shape")
@export_range(0, 100, 1) var length: int = 0:
	get:
		return _link_count
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
@export var constraint_iterations: int = 100:
	set(value):
		constraint_iterations = max(value, 1)
@export var damping: float = 0.99:
	set(value):
		damping = clamp(value, 0.0, 1.0)

# --- Chain Geometry ---
@onready var grabbable_area = $GrabbableArea
@onready var grabbable_shape = $GrabbableArea/GrabbableShape

@export_group("Player Limit Parameters")
@export var climb_speed: float = 3.0
@export var slide_speed: float = 5.0
@export_range(0,3) var push_force: float = 1.0
@export var lower_climb_limit: float = 1.0
@export var upper_climb_limit: float = 1.0
var grab_position: float
var _angle: float = 0.0
var grab_link_idx: int = -1

# --- Chain System ---
const LinkScene: PackedScene = preload("uid://mc7fntx8byk1")


class ChainPoint:
	var position: Vector3
	var prev_position: Vector3
	var locked: bool


var points: Array[ChainPoint] = []
var links: Array[Link] = []


func _ready():
	if grabbable_area != null:
		grabbable_area.body_entered.connect(on_player_enter)
	update_chain_geometry()


func _physics_process(delta: float):
	if not Engine.is_editor_hint() and points.size() > 1:
		simulate(delta)
		update_link_transforms()

	_angle = derive_angle()
	update_chain_angle()


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
		for link in links:
			link.apply_constraint()


func derive_angle() -> float:
	if points.size() < 2:
		return 0.0
	var offset = points[-1].position - points[0].position
	return atan2(offset.x, -offset.y)


## --------------------------------------------------------
## ROPE GEOMETRY
## --------------------------------------------------------
func sync_link_count(count: int):
	var existing: Array[Link] = []
	for child in get_children():
		var link = child as Link
		if link != null:
			existing.append(link)
		else:
			var mi = child as MeshInstance3D
			if mi != null and mi.name.begins_with("Link"):
				remove_child(mi)
				mi.queue_free()

	links.clear()
	for i in range(count):
		if i < existing.size():
			var link = existing[i]
			link.name = "Link%d" % i
			link.setup(points[i], points[i + 1], i, link_spacing)
			links.append(link)
		else:
			var link = LinkScene.instantiate() as Link
			link.name = "Link%d" % i
			link.setup(points[i], points[i + 1], i, link_spacing)
			add_child(link)
			link.owner = self
			links.append(link)

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


func update_link_transforms():
	for link in links:
		link.update_visual()


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

	grab_position = clamp(
		distToChain.length(),
		lower_climb_limit,
		_link_count * link_spacing - upper_climb_limit,
	)
	grab_link_idx = clamp(int(grab_position / link_spacing), 0, _link_count - 1)

	var chainDir: Vector3 = distToChain.normalized()
	var tangentDir: Vector3 = Vector3(chainDir.y, -chainDir.x, 0)
	var tangentSpeed: float = player.velocity.dot(tangentDir) * 0.3
	if grab_link_idx < points.size():
		var V = tangentDir * clampf(tangentSpeed, -10.0, 10.0)
		points[grab_link_idx].prev_position = points[grab_link_idx].position - V


func stop_interaction(interactor: Node3D):
	grab_position = 0.0
	grab_link_idx = -1


func jump_off() -> Vector3:
	if grab_link_idx < 0 or grab_link_idx >= points.size() - 1:
		return Vector3.ZERO
	var vel = points[grab_link_idx].position - points[grab_link_idx].prev_position
	return vel * launch_force


func get_grab_point() -> Vector3:
	if points.size() < 2 or grab_link_idx < 0:
		return global_position
	var idx = clampi(grab_link_idx, 0, points.size() - 2)
	var t = 0.0
	if link_spacing > 0.001:
		t = fmod(grab_position, link_spacing) / link_spacing
	return to_global(points[idx].position.lerp(points[idx + 1].position, t))


func push(dir: Vector3, force: float):
	if grab_link_idx < 0 or grab_link_idx >= points.size() - 1:
		return

	var link_dir = (points[grab_link_idx + 1].position - points[grab_link_idx].position).normalized()
	var tangent_dir = Vector3(link_dir.y, -link_dir.x, 0)
	var tangential_force = dir.dot(tangent_dir) * force * push_force
	var V = tangent_dir * clampf(tangential_force, -5.0, 5.0)
	points[grab_link_idx].prev_position = points[grab_link_idx].position - V


func climb(dir: Vector3, speed: float):
	var dirSpeed: float = climb_speed if dir.y < 0 else slide_speed if dir.y > 0 else 0.0
	grab_position += dir.y * speed * dirSpeed
	grab_position = clamp(
		grab_position,
		lower_climb_limit,
		_link_count * link_spacing - upper_climb_limit,
	)
	grab_link_idx = clamp(int(grab_position / link_spacing), 0, _link_count - 1)
