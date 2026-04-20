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


func _ready() -> void:
	if lights:
		lights.weight = trigger_weight;
		lights.current_weight = 0;

	set_physics_process(true);
	trigger_area.body_entered.connect(_on_body_entered);
	trigger_area.body_exited.connect(_on_body_exited);


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not lights or _counted_bodies.is_empty():
		return;

	var delta_weight: int = 0;
	var invalid_bodies: Array[Node3D] = [];

	for body in _counted_bodies.keys():
		if not is_instance_valid(body):
			delta_weight -= int(_counted_bodies[body]);
			invalid_bodies.append(body);
			continue;
		
		var new_val = body.get("weight");
		if new_val == null:
			continue;
		
		var old_val: int = int(_counted_bodies[body]);
		if new_val != old_val:
			delta_weight += int(new_val) - old_val;
			_counted_bodies[body] = int(new_val);

	for b in invalid_bodies:
		_counted_bodies.erase(b);

	if delta_weight != 0:
		lights.current_weight += delta_weight;
		_check_trigger();


func _on_body_entered(body: Node3D) -> void:
	# Ignore attached limbs; the Player core will report their combined weight.
	if body is BodyPart and not body.is_detached:
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


func _on_body_exited(body: Node3D) -> void:
	# Clean up any body that was previously counted.
	if not _counted_bodies.has(body):
		return;

	var weight_val: int = int(_counted_bodies[body]);
	_counted_bodies.erase(body);

	if "stabilization_enabled" in body:
		body.set("stabilization_enabled", true);

	if lights:
		lights.current_weight -= weight_val;
		_check_trigger();

	# Bounce on exit if we are now below threshold
	#if not _was_active:
		#anim_player.play("Bounce");


func _check_trigger() -> void:
	var current: int = lights.current_weight if lights else 0;
	var is_active: bool = current >= trigger_weight;
	
	if is_active and not _was_active:
		_was_active = true;
		anim_player.play("Pressing");
		anim_player.queue("Pressed");
		
		# Notify targets
		for target in activation_targets:
			if target and target.has_method("on_button_activated"):
				target.on_button_activated();
	
	elif not is_active and _was_active:
		_was_active = false;
		anim_player.play("Unpressed");
		
		# Notify targets of deactivation
		for target in activation_targets:
			if target and target.has_method("on_button_deactivated"):
				target.on_button_deactivated();
	
	elif not is_active and not _was_active:
		# Just update visuals/bounce if needed
		pass;
