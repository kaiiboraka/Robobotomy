extends Node

@export var activation_targets: Array[Node] = [];
var arm_in_range: bool :
	get:
		return !arms_in_range.is_empty()
var arms_in_range: Array[BodyPart] = [];
var is_activated: bool = false;
@onready var area3d: Area3D = $Area3D;
@export var activation_mode: ActivationModes = ActivationModes.FIRE_AND_FORGET;
var player: Player
enum ActivationModes {
	HOLD,
	FIRE_AND_FORGET,
	TOGGLE
}

# known bugs:
# - activates even if the player is not actively controlling the arm in range
func _ready():
	player= Player.instance
	
# eventually will light up when an arm is in range, then allow arms (or any controller using arms) to interact

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("Player_Interact")):
		if(not arm_in_range):
			return
		
		# also somehow check if the player is currently controlling the arm
		# ask player
		match is_activated and player.is_allowed_to_activate(self):
			true: on_deactivate()
			false: on_activate()
		
func on_activate() -> void:
	
	if not player.l_arm and not player.r_arm:
		return
	if not arm_in_range:
		return
		
	print("activating")
	for target in activation_targets:
		if target and target.has_method("on_button_activated"):
			target.on_button_activated();
	match activation_mode:
		ActivationModes.HOLD:
			is_activated = true;
			player.start_controlling_panel()
			pass
			# toggle `activated` and take control away from player, then intercept inputs until the player decides to deactivate
		ActivationModes.FIRE_AND_FORGET:
			pass
			# do nothing; shouldn't need to change `activated` because it will be deactivated immediately
		ActivationModes.TOGGLE:
			is_activated = true;
			# toggle `activated`, but don't take control from the player.
		
func on_deactivate():
	var player: Player = Player.instance
	if not player.l_arm and not player.r_arm:
		return
	if not arm_in_range:
		return
		
	print("deactivating")
	for target in activation_targets:
		if target and target.has_method("on_button_deactivated"):
			target.on_button_deactivated();
	match activation_mode:
		ActivationModes.HOLD:
			is_activated = false;
			player.stop_controlling_panel();
			pass
			# toggle `activated` back to false and give control back to player
		ActivationModes.FIRE_AND_FORGET:
			pass
			# this should not be possible
		ActivationModes.TOGGLE:
			is_activated = false;


func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body is BodyPart):
		# don't need to check type because the arms have their own collision layer
		arms_in_range.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if(body is BodyPart):
		arms_in_range.erase(body)
