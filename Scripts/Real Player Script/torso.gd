extends RollingBodyPart

var limbs_attached = 0

# Torso only rolls if no limbs are attached.
func should_roll() -> bool:
	return limbs_attached == 0;

func _on_stabilize_step(t: float, initial_rot: float, initial_y: float):
	if not is_instance_valid(self): return;
	var current_rot = lerp(initial_rot, 0.0, t);
	var lift = (abs(sin(initial_rot)) - abs(sin(current_rot))) * 0.5;
	if lift > 0: 
		global_position.y = initial_y + lift;
