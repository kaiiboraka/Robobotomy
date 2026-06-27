extends Node

@export var activation_targets: Array[Node] = [];
var arm_in_range: bool = false;
@onready var area3d: Area3D = $Area3D;

# known bugs:
# - activates even if the player is not actively controlling the arm in range

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# eventually will light up when an arm is in range, then allow arms (or any controller using arms) to interact

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("Player_Interact")):
		if(arm_in_range):
			on_activate()
		
func on_activate() -> void:
	var player: Player = Player.instance
	if not player.l_arm and not player.r_arm:
		return
		
	if not arm_in_range:
		return
		
	print("activating")
	for target in activation_targets:
		if target and target.has_method("on_button_activated"):
			target.on_button_activated();
		
func on_deactivate():
	for target in activation_targets:
		if target and target.has_method("on_button_deactivated"):
			target.on_button_deactivated();
	print("deactivating")


func _on_area_3d_body_entered(body: Node3D) -> void:
	print("body entered")
	if(body is BodyPart):
		print("body part entered")
		arm_in_range = true;
		print("arm in range")

func _on_area_3d_body_exited(body: Node3D) -> void:
	if(area3d.get_overlapping_bodies().is_empty()):
		# TODO: check for type to avoid false positives on other types of actors
		arm_in_range = false;
		print("no arms in range")
