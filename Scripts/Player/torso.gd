extends RollingBodyPart

var limbs_attached: int = 0;


func enable_part() -> void:
	super.enable_part();
	sleeping = false;
	freeze = false;


func disable_part() -> void:
	super.disable_part();
	if limbs_attached > 0:
		freeze = true;
	else:
		freeze = false;


func should_roll() -> bool:
	return limbs_attached == 0;


func _on_stabilize_step(t: float, initial_rot: float, initial_y: float) -> void:
	if not is_instance_valid(self): return;
	var current_rot : float = lerp(initial_rot, 0.0, t);
	var lift : float = (abs(sin(initial_rot)) - abs(sin(current_rot))) * 0.5;
	if lift > 0: 
		global_position.y = initial_y + lift;
