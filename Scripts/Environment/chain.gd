@tool
class_name Chain
extends Node3D;

const LinkScene: PackedScene = preload("uid://mc7fntx8byk1");

@export_group("Chain Shape")
@export_range(0, 500, 1) var length: int = 0:
	get:
		return _link_count;
	set(value):
		_link_count = max(value, 0);
		if Engine.is_editor_hint():
			update_chain_geometry();
@export var link_spacing: float = 0.225:
	set(value):
		link_spacing = max(value, 0.01);
		if Engine.is_editor_hint():
			update_chain_geometry();


@export_group("Physics Parameters")
@export var launch_force: float = 10.0;
@export var gravity_scale: float = 1.0;

@export_group("Player Limit Parameters")
@export var climb_speed: float = 3.0;
@export var slide_speed: float = 5.0;
@export var lower_climb_limit: float = 1.0;
@export var upper_climb_limit: float = 1.0;
@export_range(0, 3) var push_force: float = 1.0;
var grab_position: float;
var grab_link_idx: int = -1;
var is_occupied: bool;

var links: Array[Link] = [];
var _link_count: int = 10;

@onready var visible_enabler = $VisibleOnScreenEnabler3D;


func _ready():
	update_chain_geometry();


func _physics_process(_delta: float):
	pass;


## --------------------------------------------------------
## INTERACTION LOGIC
## --------------------------------------------------------
func on_player_enter(player: Node3D):
	if player is Player:
		interact_with(player);


func interact_with(player: Player):
	if not player.r_arm or player.r_arm.is_detached or not player.l_arm or player.l_arm.is_detached:
		return;
	if player.attached_chain == self:
		return;

	player.grab_chain(self);

	is_occupied = true;
	_set_link_areas_enabled(false);

	var distToChain: Vector3 = global_position - player.get_grab_location();
	distToChain.z = 0;

	grab_position = clamp(
		distToChain.length(),
		lower_climb_limit,
		_link_count * link_spacing - upper_climb_limit,
	)
	grab_link_idx = clamp(int(grab_position / link_spacing), 0, _link_count - 1);

	var chainDir: Vector3 = distToChain.normalized();
	var tangentDir: Vector3 = Vector3(chainDir.y, -chainDir.x, 0);
	var tangentSpeed: float = player.velocity.dot(tangentDir) * 0.3;
	if grab_link_idx < links.size():
		var V = tangentDir * clampf(tangentSpeed, -10.0, 10.0);
		links[grab_link_idx].linear_velocity += V * 60.0;


func stop_interaction(interactor: Node3D):
	grab_position = 0.0;
	grab_link_idx = -1;


func release_chain():
	is_occupied = false;
	_set_link_areas_enabled(true);


func jump_off() -> Vector3:
	if grab_link_idx < 0 or grab_link_idx >= links.size() - 1:
		return Vector3.ZERO;
	return links[grab_link_idx].linear_velocity * launch_force;


func get_grab_point() -> Vector3:
	if links.size() < 2 or grab_link_idx < 0:
		return global_position;
	var idx = clampi(grab_link_idx, 0, links.size() - 2);
	var t = 0.0;
	if link_spacing > 0.001:
		t = fmod(grab_position, link_spacing) / link_spacing;
	return links[idx].global_position.lerp(links[idx + 1].global_position, t);


func push(dir: Vector3, force: float):
	if grab_link_idx < 0 or grab_link_idx >= links.size() - 1:
		return;
	var a = links[grab_link_idx].global_position;
	var b = links[grab_link_idx + 1].global_position;
	var link_dir = (b - a).normalized();
	var tangent_dir = Vector3(link_dir.y, -link_dir.x, 0);
	var tangential_force = dir.dot(tangent_dir) * force * push_force;
	var V = tangent_dir * clampf(tangential_force, -5.0, 5.0);
	links[grab_link_idx].linear_velocity += V * 60.0;


func climb(dir: Vector3, speed: float):
	var dirSpeed: float = climb_speed if dir.y < 0 else slide_speed if dir.y > 0 else 0.0;
	grab_position += dir.y * speed * dirSpeed;
	grab_position = clamp(
		grab_position,
		lower_climb_limit,
		_link_count * link_spacing - upper_climb_limit,
	)
	grab_link_idx = clamp(int(grab_position / link_spacing), 0, _link_count - 1);


## --------------------------------------------------------
## CHAIN GEOMETRY
## --------------------------------------------------------
func sync_link_count(count: int):
	var existing: Array[Link] = [];
	for child in get_children():
		var link = child as Link;
		if link != null:
			existing.append(link);

	links.clear();
	for i in range(count):
		if i < existing.size():
			var link = existing[i];
			link.name = "Link%d" % i;
			link.idx = i;
			_connect_link_signals(link);
			links.append(link);
		else:
			var link = LinkScene.instantiate() as Link;
			link.name = "Link%d" % i;
			add_child(link);
			link.owner = self;
			_connect_link_signals(link);
			links.append(link);

	for i in range(count, existing.size()):
		remove_child(existing[i]);
		existing[i].queue_free();


func _connect_link_signals(link: Link) -> void:
	link.parent_chain = self;
	if not link.body_entered_grabbable.is_connected(on_player_enter):
		link.body_entered_grabbable.connect(on_player_enter);


func _set_link_areas_enabled(enabled: bool) -> void:
	for link in links:
		if link.grabbable_area:
			link.grabbable_area.set_deferred("monitoring", enabled);
			link.grabbable_area.set_deferred("monitorable", enabled);


func update_chain_geometry():
	var count = _link_count;

	sync_link_count(count);

	for i in range(count):
		links[i].position = Vector3(0, -i * link_spacing, 0);
		links[i].freeze = i == 0;
		links[i].freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;
		links[i].gravity_scale = gravity_scale;
		links[i].sleeping = false;
		if i % 2 == 1:
			links[i].rotation.y = deg_to_rad(90);

	if visible_enabler != null:
		var height := _link_count * link_spacing + 0.5;
		visible_enabler.aabb = AABB(
			Vector3(-0.625, -height, -0.5),
			Vector3(1.25, height, 1.0),
		);
