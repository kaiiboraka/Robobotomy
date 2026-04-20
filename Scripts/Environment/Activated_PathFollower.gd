extends Path3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var activated: bool = false;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(activated and $PathFollow3D.progress < self.curve.get_baked_length()-0.01):
		$PathFollow3D.progress += delta;
	elif($PathFollow3D.progress > 0.01):
		$PathFollow3D.progress -= delta;
	pass


func on_button_activated() -> void:
	activated = true;


func on_button_deactivated() -> void:
	activated = false;


'''
@ -1,26 +0,0 @@
extends RollingBodyPart

var limbs_attached = 0

# Torso only rolls if no limbs are attached.
func should_roll() -> bool:
	return limbs_attached == 0;

func enable_part():
	super.enable_part();
	sleeping = false;
	freeze = false;

func disable_part():
	super.disable_part();
	# When other limbs are socketed, keep the torso rigid while disabled.
	# If limbs_attached is 0, keep super's freeze (do not force unfreeze — that breaks recall).
	if limbs_attached > 0:
		freeze = true;

func _on_stabilize_step(t: float, initial_rot: float, initial_y: float):
	if not is_instance_valid(self): return;
	var current_rot = lerp(initial_rot, 0.0, t);
	var lift = (abs(sin(initial_rot)) - abs(sin(current_rot))) * 0.5;
	if lift > 0: 
		global_position.y = initial_y + lift;
'''
