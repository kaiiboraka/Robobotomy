extends Node3D
var arm_in_range: bool :
	get:
		return !arms_in_range.is_empty();
var arms_in_range: Array[BodyPart] = [];
var is_activated: bool = false;
var attached_arm: BodyPart;

@onready var snap_location: Marker3D = $SnapLocation

var _cached_player: Player;
var player: Player :
	get:
		if not is_instance_valid(_cached_player):
			_cached_player = Player.instance;
		return _cached_player;
		
func _ready():
	player= Player.instance;

func _input(event: InputEvent) -> void:
	if(!event.is_action_pressed("Player_Interact")):
		return;
	if(not arm_in_range):
		return;
		
	if(is_activated):
		# deactivating
		if(!player.is_controlling_arm(attached_arm)):
			return;
		on_deactivate();
		return;
	# activating
	for arm in arms_in_range:
		if(player.is_controlling_arm(arm)):
			attached_arm = arm;
			on_activate();
			return;
			
func _physics_process(delta: float) -> void:
	print(arms_in_range)
	if(!is_activated or !attached_arm):
		return
	attached_arm.global_position = snap_location.global_position;
	
func on_activate():
	print("grabbing monkey bar")
	is_activated = true
	
func on_deactivate():
	print("releasing monkey bar")
	is_activated = false
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	print("body entering")
	if(body is BodyPart):
		# don't need to check type because the arms have their own collision layer
		arms_in_range.append(body);

func _on_area_3d_body_exited(body: Node3D) -> void:
	print("body exiting")
	if(body is BodyPart):
		arms_in_range.erase(body);
