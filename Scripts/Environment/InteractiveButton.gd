@tool
extends StaticBody3D

@export_range(1, 9) var trigger_weight: int = 1:
	set(val):
		trigger_weight = val;
		if is_node_ready():
			lights.weight = val;
		
@export var activation_targets: Array[Node] = [];

@onready var anim_player: AnimationPlayer = $ButtonShell/AnimationPlayer;
@onready var lights: Node3D = $Button_Lights;
@onready var trigger_area: Area3D = $Area3D;

var _was_active: bool = false;
## Bodies already contributing weight (avoids double-count on repeated body_entered).
var _counted_bodies: Dictionary = {}; # Node3D -> int

func _ready():
	if lights:
		lights.weight = trigger_weight;
		lights.current_weight = 0;
	
	trigger_area.body_entered.connect(_on_body_entered);
	trigger_area.body_exited.connect(_on_body_exited);

func _on_body_entered(body: Node3D):
	# Attached, non-active limbs are part of the core — ignore them here.
	# Torso can roll while still parented (is_detached false) but with is_part_enabled true.
	if body is BodyPart:
		if not body.is_detached and not body.is_part_enabled:
			return;

	if _counted_bodies.has(body):
		return;

	var weight_val = body.get("weight");
	if weight_val == null:
		return;

	_counted_bodies[body] = weight_val;

	if "stabilization_enabled" in body:
		body.set("stabilization_enabled", false);

	if lights:
		lights.current_weight += weight_val;
		_check_trigger();

		# If we didn't just activate, play bounce for impact
		if not _was_active:
			anim_player.play("Bounce");

func _on_body_exited(body: Node3D):
	if body is BodyPart:
		if not body.is_detached and not body.is_part_enabled:
			return;

	if not _counted_bodies.has(body):
		return;

	var weight_val: int = _counted_bodies[body];
	_counted_bodies.erase(body);

	if "stabilization_enabled" in body:
		body.set("stabilization_enabled", true);

	if lights:
		lights.current_weight -= weight_val;
		_check_trigger();

	# Bounce on exit if we are now below threshold
	#if not _was_active:
		#anim_player.play("Bounce");

func _check_trigger():
	var current = lights.current_weight if lights else 0;
	var is_active = current >= trigger_weight;
	
	if is_active and not _was_active:
		_was_active = true;
		anim_player.play("Pressing");
		anim_player.queue("Pressed");
		
		# Notify targets
		for target in activation_targets:
			if target and target.has_method("OnButtonActivated"):
				target.OnButtonActivated();
	
	elif not is_active and _was_active:
		_was_active = false;
		anim_player.play("Unpressed");
	
	elif not is_active and not _was_active:
		# Just update visuals/bounce if needed
		pass;
