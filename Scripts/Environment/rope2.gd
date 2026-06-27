extends Node3D

var is_player_touching_rope: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("ropes")

func _on_body_entered(body: Node3D):
	if(body is Player):
		if(body.r_arm and !body.r_arm.is_detached and body.l_arm and !body.l_arm.is_detached):
			snap_player_to_self(body);
			is_player_touching_rope = true;
			body.set_movement_mode(body.movement_modes.ROPE)
		
func _on_body_exited(body: Node3D):
	if(body is Player):
		is_player_touching_rope = false;
		body.set_movement_mode(body.movement_modes.DEFAULT)	
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func snap_player_to_self(player: Player):
	player.position.x = self.global_position.x
