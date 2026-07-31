extends Node3D

@export var activation_targets: Array[Node] = [];
var player_in_range: bool;
var _cached_player: Player;
var player: Player :
	get:
		if not is_instance_valid(_cached_player):
			_cached_player = Player.instance;
		return _cached_player;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player= Player.instance;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event: InputEvent) -> void:
	if(!event.is_action_pressed("Player_Interact")):
		return;
	if(not player_in_range):
		return;
	if(!player.has_all_arms_legs()):
		return
	on_activate();
		
func on_activate() -> void:
	for target in activation_targets:
		if target and target.has_method("on_activated"):
			target.on_activated();
		elif target and target.has_method("on_button_activated"):
			target.on_button_activated();
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body is Player):
		player_in_range = true;

func _on_area_3d_body_exited(body: Node3D) -> void:
	if(body is Player):
		player_in_range = false;
