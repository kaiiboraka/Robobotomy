class_name Rope extends Node3D

	# --- Rope Shape ---
@export_group("Rope Shape")
@export var length: float = 10;
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
@export var launch_force: float = 4.0;
@export var angular_dampening: float = 0.5;

# --- Debug ---
@export_group("Physics Debugging")
@export var angular_velocity: float = 0.0;

# --- Rope Geometry ---
@onready var rope_mesh: MeshInstance3D = $RopeMesh
@onready var grabbable_area: Area3D = $GrabbableArea
@onready var grabbable_shape: CollisionShape3D = $GrabbableArea/GrabbableShape

@export var climb_speed: float = 1.0;
@export var slide_speed: float = 10.0;
@export var lower_climb_limit: float = 1.0;
@export var upper_climb_limit: float = 1.0;
var grab_position: float;
var _angle: float = 0.0;

func _ready() -> void:
	UpdateRopeGeometry();

func _physics_process(delta: float) -> void:
	var pivot: float = grab_position if grab_position > 0.001 else length;
	var angularAccel: float = (gravity / pivot) * sin(_angle);

	angular_velocity += angularAccel * delta;
	_angle += angular_velocity * delta;

	UpdateRopeAngle();

	angular_velocity *= 1 - angular_dampening * delta;


## --------------------------------------------------------
## ROPE GEOMETRY
## --------------------------------------------------------
func UpdateRopeGeometry() -> void:

	# Duplicate mesh
	var mesh: CylinderMesh = rope_mesh.Mesh.Duplicate() as CylinderMesh;
	mesh.Height = length;

	# Duplicate shape
	var shape: BoxShape3D = grabbable_shape.Shape.Duplicate() as BoxShape3D;
	shape.Size = Vector3(shape.Size.X, length + 0.5, shape.Size.Z);

	# Positioning
	rope_mesh.Position = Vector3(0, -length / 2, 0);
	grabbable_area.Position = Vector3(0, -( length + 0.5 ) / 2, 0);

	# Apply
	rope_mesh.Mesh = mesh;
	grabbable_shape.Shape = shape;

func UpdateRopeAngle() -> void:

	rotation = Vector3(rotation.x, rotation.y, _angle);


func OnPlayerEnter(player: Node3D) -> void:
	InteractWith(player);
## --------------------------------------------------------
## INTERACTION LOGIC
## --------------------------------------------------------
func InteractWith(player: Player) -> void:

	print("Interacting")
	if(!player.r_arm or player.r_arm.is_detached or !player.l_arm or player.l_arm.is_detached):
		return;


	player.SetMovementMode(player.movement_modes.ROPE);

	var distToRope: Vector3 = global_position - player.global_position;
	distToRope.z = 0;

	grab_position = clamp(distToRope.length(), lower_climb_limit, length - upper_climb_limit);

	var ropeDir: Vector3 = distToRope.normalized();
	var tangentDir: Vector3 = Vector3(ropeDir.y, -ropeDir.x, 0);
	var tangentSpeed: float = player.Velocity.Dot(tangentDir);
	
	angular_velocity += tangentSpeed / grab_position;

func StopInteraction(interactor: Node3D) -> void:
	grab_position = 0.0;


func JumpOff() -> Vector3:
	var tangent: Vector3 = Vector3(cos(_angle), 0, 0);
	var tangentSpeed: float = angular_velocity * grab_position;
	return tangent * tangentSpeed * launch_force;

func GetGrabPoint() -> Vector3:
	return Vector3(
		grab_position * sin(_angle),
		-grab_position * cos(_angle),
		0
	) + global_position;

func Push(dir: Vector3, force: float) -> void:
	if (grab_position < 0.001):
		return;

	var tangentDir: Vector3 = Vector3(cos(_angle), -sin(_angle), 0);
	var tangentialForce: float = dir.dot(tangentDir) * force;
	var angularAccel: float = tangentialForce / grab_position;

	angular_velocity += angularAccel;

func Climb(dir: Vector3, speed: float) -> void:
	var dirSpeed: float = climb_speed if dir.y<0 else slide_speed if dir.y>0 else 0

	grab_position += dir.y * speed * dirSpeed;

	grab_position = clamp(grab_position, lower_climb_limit, length - upper_climb_limit);
