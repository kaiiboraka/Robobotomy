class_name ControlPanel extends Node3D

@export var activation_targets: Array[Node] = [];
var arm_in_range: bool :
	get:
		return !arms_in_range.is_empty();
var arms_in_range: Array[BodyPart] = [];
var control_arm: BodyPart;
var is_activated: bool = false;
@onready var area3d: Area3D = $Area3D;
@onready var snap_location: Marker3D = $SnapLocation;
@onready var terminal: MeshInstance3D = $Terminal;
var mat: BaseMaterial3D = StandardMaterial3D.new();
@export var activation_mode: ActivationModes = ActivationModes.FIRE_AND_FORGET;
var _cached_player: Player;
var player: Player :
	get:
		if not is_instance_valid(_cached_player):
			_cached_player = Player.instance;
		return _cached_player;
enum ActivationModes {
	HOLD,
	FIRE_AND_FORGET,
	TOGGLE
}

func _ready():
	player= Player.instance;
	mat.albedo_color = Color(1,1,1,1);
	terminal.material_overlay = mat;
	
# eventually will light up when an arm is in range, then allow arms (or any controller using arms) to interact

func _input(event: InputEvent) -> void:
	if(!event.is_action_pressed("Player_Interact")):
		return;
	if(not arm_in_range):
		return;
		
	if(is_activated):
		# deactivating
		if(!player.is_controlling_arm(control_arm)):
			return;
		on_deactivate();
		return;
	# activating
	for arm in arms_in_range:
		if(player.is_controlling_arm(arm)):
			control_arm = arm;
			on_activate();
			return;
		
func on_activate() -> void:
	print("activating");
	for target in activation_targets:
		if target and target.has_method("on_activated_by_arm"):
			target.on_activated_by_arm(control_arm);
		elif target and target.has_method("on_button_activated"):
			target.on_button_activated();
	match activation_mode:
		ActivationModes.HOLD:
			is_activated = true;
			player.start_controlling_panel(control_arm, self);
			mat.albedo_color = Color(0,1,0,1);
			# toggle `activated` and take control away from player, then intercept inputs until the player decides to deactivate
		ActivationModes.FIRE_AND_FORGET:
			pass;
			# do nothing; shouldn't need to change `activated` because it will be deactivated immediately
		ActivationModes.TOGGLE:
			is_activated = true;
			mat.albedo_color = Color(0,1,0,1);
			# toggle `activated`, but don't take control from the player.
		
func on_deactivate():
	print("deactivating");
	for target in activation_targets:
		if target and target.has_method("on_button_deactivated"):
			target.on_button_deactivated();
	match activation_mode:
		ActivationModes.HOLD:
			is_activated = false;
			player.stop_controlling_panel(control_arm);
			mat.albedo_color = Color(1,1,1,1);
			# toggle `activated` back to false and give control back to player
		ActivationModes.FIRE_AND_FORGET:
			pass;
			# this should not be possible
		ActivationModes.TOGGLE:
			is_activated = false;
			mat.albedo_color = Color(1,1,1,1);
			
func get_camera_target() -> Node3D:
	var targets: Array[Node3D] = [];
	for target in activation_targets:
		if target.is_class("Node3D"):
			targets.push_back(target);
	if(targets.is_empty()):
		return self;
	if(targets.size() > 1):
		printerr("Control panel " + self.to_string() + " has multiple targets. Camera is choosing only one of them to follow.");
	return targets[0];
	
func get_snap_location() -> Vector3:
	return snap_location.global_position;

func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body is BodyPart):
		# don't need to check type because the arms have their own collision layer
		arms_in_range.append(body);

func _on_area_3d_body_exited(body: Node3D) -> void:
	if(body is BodyPart):
		arms_in_range.erase(body);
