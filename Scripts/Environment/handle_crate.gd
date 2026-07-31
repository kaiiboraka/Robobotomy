extends RigidBody3D

var player_intersect_left: bool;
var player_intersect_right: bool;
var player_grab_left: bool;
var player_grab_right: bool;

@onready var left_snap_location: Marker3D = $LeftSnapLocation
@onready var right_snap_location: Marker3D = $RightSnapLocation

var _cached_player: Player;
var player: Player :
	get:
		if not is_instance_valid(_cached_player):
			_cached_player = Player.instance;
		return _cached_player;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event: InputEvent) -> void:
	if(!event.is_action_pressed("Player_Interact")):
		return;
	if(player.l_arm.is_detached or player.r_arm.is_detached):
		return;
	if(!player.has_all_arms_legs()):
		return
	if(player_intersect_left):
		grab_left()
	elif(player_intersect_right):
		grab_right()

func grab_left() -> void:
	player_grab_left = !player_grab_left;

func grab_right() -> void:
	player_grab_right = !player_grab_right;
	
func _physics_process(delta: float) -> void:
	if(!player.has_all_arms_legs()):
		player_grab_left = false;
		player_grab_right = false;
	if(player_grab_left):
		player.global_position = left_snap_location.global_position;
		if(Input.is_action_pressed("Player_Move_Left")):
			linear_velocity = Vector3(-3, linear_velocity.y, 0)
		if(Input.is_action_pressed("Player_Move_Right")):
			linear_velocity = Vector3(3, linear_velocity.y, 0)
	elif(player_grab_right):
		player.global_position = right_snap_location.global_position;
		if(Input.is_action_pressed("Player_Move_Left")):
			linear_velocity = Vector3(-3, linear_velocity.y, 0)
		if(Input.is_action_pressed("Player_Move_Right")):
			linear_velocity = Vector3(3, linear_velocity.y, 0)
	
func _on_left_area_entered(body: Node3D) -> void:
	if(body is Player):
		player_intersect_left = true;

func _on_left_area_exited(body: Node3D) -> void:
	if(body is Player):
		player_intersect_left = false;
		player_grab_left = false;
		
func _on_right_area_entered(body: Node3D) -> void:
	if(body is Player):
		player_intersect_right = true;

func _on_right_area_exited(body: Node3D) -> void:
	if(body is Player):
		player_intersect_right = false;
		player_grab_right = false;
