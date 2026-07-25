@tool
class_name Rope extends Node3D

var _length : float = 10;
	# --- Rope Shape ---
@export_group("Rope Shape")
@export var length: float = 10 :
	get : return _length;
	set(value) :
		_length = max(value, .1)
		if (Engine.is_editor_hint()):
			update_rope_geometry();
#[Export(PropertyHint.Range, "0.1,10.0,0.1,or_greater")]
#	private float _length = 10.0f;
#	public float Length
#	{
#		get => _length;
#		set
#		{
#			_length = Mathf.Max(value, 0.1f);
#			if (Engine.IsEditorHint())
#				UpdateRopeGeometry();
#		}
#	}

# --- Physics Parameters ---
@export_group("Physics Parameters")
@export var gravity: float = -100.0;
@export var launch_force: float = 10.0;
@export var angular_dampening: float = 0.5;

# --- Debug ---
@export_group("Physics Debugging")
@export var angular_velocity: float = 0.0;

# --- Rope Geometry ---
@onready var rope_mesh: MeshInstance3D = $RopeMesh
@onready var grabbable_area: Area3D = $GrabbableArea
@onready var grabbable_shape: CollisionShape3D = $GrabbableArea/GrabbableShape

@export_group("Player Limit Parameters")
@export var climb_speed: float = 3.0;
@export var slide_speed: float = 5.0;
@export var lower_climb_limit: float = 1.0;
@export var upper_climb_limit: float = 1.0;
var grab_position: float;
var _angle: float = 0.0;

func _ready() -> void:
	update_rope_geometry();

func _physics_process(delta: float) -> void:
	var pivot: float = grab_position if grab_position > 0.001 else length;
	var angularAccel: float = (gravity / pivot) * sin(_angle);

	angular_velocity += angularAccel * delta;
	_angle += angular_velocity * delta;

	update_rope_angle();

	angular_velocity *= 1 - angular_dampening * delta;


## --------------------------------------------------------
## ROPE GEOMETRY
## --------------------------------------------------------
func update_rope_geometry() -> void:

	# Duplicate mesh
	var mesh: CylinderMesh = rope_mesh.mesh.duplicate() as CylinderMesh;
	mesh.height = length;

	# Duplicate shape
	var shape: BoxShape3D = grabbable_shape.shape.duplicate() as BoxShape3D;
	shape.size = Vector3(shape.size.x, length + 0.5, shape.size.z);

	# Positioning
	rope_mesh.position = Vector3(0, -length / 2, 0);
	grabbable_area.position = Vector3(0, -( length + 0.5 ) / 2, 0);

	# Apply
	rope_mesh.mesh = mesh;
	grabbable_shape.shape = shape;

func update_rope_angle() -> void:

	rotation = Vector3(rotation.x, rotation.y, _angle);


func on_player_enter(player: Node3D) -> void:
	if(player is Player):
		interact_with(player);
## --------------------------------------------------------
## INTERACTION LOGIC
## --------------------------------------------------------
func interact_with(player: Player) -> void:

	print("Interacting")
	if(!player.r_arm or player.r_arm.is_detached or !player.l_arm or player.l_arm.is_detached):
		return;

	player.grab_rope(self)

	var distToRope: Vector3 = global_position - player.get_grab_location();
	distToRope.z = 0;

	grab_position = clamp(distToRope.length(), lower_climb_limit, length - upper_climb_limit);

	var ropeDir: Vector3 = distToRope.normalized();
	var tangentDir: Vector3 = Vector3(ropeDir.y, -ropeDir.x, 0);
	var tangentSpeed: float = player.velocity.dot(tangentDir);
	
	angular_velocity += tangentSpeed / grab_position;

func stop_interaction(interactor: Node3D) -> void:
	grab_position = 0.0;


func jump_off() -> Vector3:
	var tangent: Vector3 = Vector3(cos(_angle), 0, 0);
	var tangentSpeed: float = angular_velocity * grab_position;
	angular_velocity = 0;
	return tangent * tangentSpeed * launch_force;

func get_grab_point() -> Vector3:
	return Vector3(
		grab_position * sin(_angle),
		-grab_position * cos(_angle),
		0
	) + global_position;

func push(dir: Vector3, force: float) -> void:
	if (grab_position < 0.001):
		return;

	var tangentDir: Vector3 = Vector3(cos(_angle), -sin(_angle), 0);
	var tangentialForce: float = dir.dot(tangentDir) * force;
	var angularAccel: float = tangentialForce / grab_position;

	angular_velocity += angularAccel;

func climb(dir: Vector3, speed: float) -> void:
	var dirSpeed: float = climb_speed if dir.y<0 else slide_speed if dir.y>0 else 0

	grab_position += dir.y * speed * dirSpeed;

	grab_position = clamp(grab_position, lower_climb_limit, length - upper_climb_limit);
