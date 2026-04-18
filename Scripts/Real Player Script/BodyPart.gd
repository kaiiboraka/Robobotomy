@abstract
class_name BodyPart
extends RigidBody3D

@export var is_part_enabled: bool = true

@export var retract_speed = 5
var starting_position : Vector3
var core : Node3D

func _ready():
	starting_position = position;
	if is_part_enabled:
		enable_part()
	else:
		disable_part()

func retract():
	var moveTween = create_tween()
	disable_part();
	var dist = core.global_position.distance_to(self.global_position)
	moveTween.tween_property(self, "position", starting_position, dist / retract_speed)

func enable_part():
	is_part_enabled = true;
	freeze = false;
	top_level = true;
	set_process(true);
	set_physics_process(true);
	set_process_input(true);

func disable_part():
	is_part_enabled = false;
	freeze = true;
	top_level = false;
	set_process(false);
	set_physics_process(false);
	set_process_input(false);
	# When disabled, we reset local transform to identity or a neutral state 
	# so it follows the parent precisely if that's the intention.
	# transform = Transform3D.IDENTITY
