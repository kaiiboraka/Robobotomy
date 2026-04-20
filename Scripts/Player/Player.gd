class_name Player extends CharacterBody3D

@export var speed: float = 5.0;
@export var jump_velocity: float = 4.5;

@onready var torso: BodyPart = $Torso;
@onready var head: BodyPart = $Head;
@onready var l_arm: BodyPart = $LeftArm;
@onready var r_arm: BodyPart = $RightArm;
@onready var l_leg: BodyPart = $LeftLeg;
@onready var r_leg: BodyPart = $RightLeg;
@onready var phantom_camera: Node3D = $PhantomCamera3D;
@onready var selection_label: Label3D = $Label3D;
@onready var neck: MeshInstance3D = $Neck;

var limbs: Array = [];
var selected_limb: BodyPart = null;
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity");
var is_controlling_core: bool = true;
var weight: int = 0;


func _ready() -> void:
	axis_lock_linear_z = true;

	# Torso is 0th entry, followed by Head, Arms, and Legs
	limbs = [torso, head, l_arm, r_arm, l_leg, r_leg];

	for limb in limbs:
		if limb:
			limb.core = self;
			limb.disable_part();
			if not limb.hit_ground.is_connected(_on_limb_hit_ground):
				limb.hit_ground.connect(_on_limb_hit_ground.bind(limb));

			# Setup camera follow logic based on visibility
			if limb.notifier:
				limb.notifier.screen_entered.connect(_add_follow_target.bind(limb));
				limb.notifier.screen_exited.connect(_remove_follow_target.bind(limb));
				if limb.notifier.is_on_screen():
					_add_follow_target(limb);

	# Start with torso selected
	selected_limb = torso;
	update_weight();
	check_torso_activation();
	_update_selection_hud();


func _physics_process(delta: float) -> void:
	# just_pressed avoids re-running select_limb every frame while a limb key is held
	if Input.is_action_just_pressed("Player_SelectLimb0_Torso"):
		select_limb(torso);
	elif Input.is_action_just_pressed("Player_SelectLimb1_Head"):
		select_limb(head);
	elif Input.is_action_just_pressed("Player_SelectLimb2_L_Arm"):
		select_limb(l_arm);
	elif Input.is_action_just_pressed("Player_SelectLimb3_R_Arm"):
		select_limb(r_arm);
	elif Input.is_action_just_pressed("Player_SelectLimb4_L_Leg"):
		select_limb(l_leg);
	elif Input.is_action_just_pressed("Player_SelectLimb5_R_Leg"):
		select_limb(r_leg);

	if Input.is_action_just_pressed("Player_Throw_Limb") and selected_limb and selected_limb != torso:
		if not selected_limb.is_detached:
			var mouse_pos := get_viewport().get_mouse_position();
			var camera := get_viewport().get_camera_3d();
			if camera:
				var from := camera.project_ray_origin(mouse_pos);
				var to := from + camera.project_ray_normal(mouse_pos) * 10.0;
				var direction := (to - selected_limb.global_position).normalized();
				direction.z = 0;

				selected_limb.throw(direction * selected_limb.throw_force);

				# Update camera to follow newly thrown limb
				if phantom_camera:
					phantom_camera.set("follow_target", selected_limb);
					phantom_camera.set("priority", 2);

				check_torso_activation();
				update_weight();

	if Input.is_action_just_pressed("Player_Drop_Limb"):
		if selected_limb == torso:
			drop_all_limbs();
		elif selected_limb != null and not selected_limb.is_detached:
			drop_limb(selected_limb);

	if Input.is_action_just_pressed("Player_Recall"):
		if torso.is_part_enabled:
			sync_core_to_torso();

		if selected_limb == torso:
			is_controlling_core = true;
			for limb in limbs:
				if limb and limb != torso and limb.is_detached:
					var tween = limb.retract();
					tween.finished.connect(_on_limb_returned.bind(limb));
		elif selected_limb and selected_limb != torso and selected_limb.is_detached:
			is_controlling_core = true;
			var tween := selected_limb.retract();
			tween.finished.connect(select_limb.bind(torso));
			tween.finished.connect(_on_limb_returned.bind(selected_limb));
		_update_selection_hud();

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta;

	# Process movement inputs only if we are controlling the core
	if is_controlling_core:
		# Handle Jump.
		if Input.is_action_just_pressed("Player_Jump") and is_on_floor():
			velocity.y = jump_velocity;

		# Get the input direction and handle the movement/deceleration.
		var input_dir := Input.get_axis("Player_Move_Left", "Player_Move_Right");

		if input_dir:
			velocity.x = input_dir * speed;
		else:
			velocity.x = move_toward(velocity.x, 0, speed);
	else:
		# Decelerate naturally when not under control
		velocity.x = move_toward(velocity.x, 0, speed * delta);

	if _hud_needs_periodic_update():
		_update_selection_hud();

	move_and_slide();


func sync_core_to_torso() -> void:
	if not torso: return;

	# Snap CharacterBody3D to Torso's current location
	global_position = torso.global_position - global_transform.basis * torso.starting_position;

	# Reset torso to its relative home
	torso.disable_part();
	torso.position = torso.starting_position;
	torso.rotation = torso.starting_rotation;
	torso.linear_velocity = Vector3.ZERO;
	torso.angular_velocity = Vector3.ZERO;

	is_controlling_core = true;
	_update_selection_hud();


func update_weight() -> void:
	var total: int = torso.weight if torso else 1;
	var attached_count: int = 0;
	for limb in limbs:
		if limb and limb != torso and not limb.is_detached:
			total += limb.weight;
			attached_count += 1;
	weight = total;
	if torso and "limbs_attached" in torso:
		torso.limbs_attached = attached_count;

	if neck and head:
		neck.visible = not head.is_detached;


func check_torso_activation() -> void:
	var all_others_detached: bool = true;
	for limb in limbs:
		if limb != torso and limb and not limb.is_detached:
			all_others_detached = false;
			break;

	if all_others_detached:
		if selected_limb == torso:
			is_controlling_core = false;
			torso.enable_part();
		elif selected_limb != null and selected_limb.is_detached and selected_limb.is_part_enabled:
			# Only the rolling detached limb reads move/jump — not the CharacterBody.
			is_controlling_core = false;
		else:
			# Thrown limb mid-air, or odd states: move the core until the limb can take over.
			is_controlling_core = true;
	else:
		torso.disable_part();
		if selected_limb == torso:
			is_controlling_core = true;
		elif selected_limb != null and selected_limb.is_detached and selected_limb.is_part_enabled:
			is_controlling_core = false;
		else:
			# Socketed torso, attached limb, or thrown limb still in flight — use CharacterBody.
			is_controlling_core = true;
	_update_selection_hud();


func select_limb(limb: BodyPart) -> void:
	if not limb:
		return;
	if selected_limb == limb:
		# Re-tap while thrown but not yet control-enabled (e.g. missed hit_ground): wake if already on solid.
		if limb.is_detached and not limb.is_part_enabled and _limb_has_valid_ground_contact(limb):
			is_controlling_core = false;
			limb.enable_part();
			_update_selection_hud();
			return;
		return;

	var old_limb := selected_limb;

	# Disable control of the previously selected limb if it was active
	if selected_limb:
		selected_limb.deselect();
		if selected_limb == torso and selected_limb.is_part_enabled:
			# Rolling torso: only snap back onto the CharacterBody when other limbs are still socketed.
			if _any_limb_still_socketed():
				sync_core_to_torso();
		else:
			selected_limb.disable_part();
		# Rolling torso skips disable_part above — still must drop player input so two parts never share controls.
		if old_limb != limb:
			old_limb.set_accepts_player_input(false);

	selected_limb = limb;
	selected_limb.on_select();

	# Update camera target and priority: Only follow limb if detached
	if phantom_camera:
		if selected_limb != torso and selected_limb.is_detached:
			phantom_camera.set("follow_target", selected_limb);
			phantom_camera.set("priority", 2);
		else:
			phantom_camera.set("follow_target", null);
			phantom_camera.set("priority", 0);

	_add_follow_target(selected_limb);

	# If old limb is no longer selected and is off-screen, remove it from camera
	if old_limb and old_limb != selected_limb:
		if old_limb.notifier and not old_limb.notifier.is_on_screen():
			_remove_follow_target(old_limb);
		elif old_limb == torso: # Always remove torso from follow if not selected
			_remove_follow_target(old_limb);

	if limb == torso:
		check_torso_activation();
	else:
		if limb.is_detached:
			# Enable limb control immediately if it's already landed or moving
			limb.enable_part();
			is_controlling_core = false;
		else:
			# Attached limb selected, main body is controlled
			is_controlling_core = true;
	_update_selection_hud();


func drop_limb(limb: BodyPart) -> void:
	if limb and limb != torso and not limb.is_detached:
		limb.global_position = global_position + global_transform.basis * limb.starting_position;
		limb.global_rotation = global_rotation + limb.starting_rotation;
		limb.drop();

		# Update camera if this was the selected limb
		if limb == selected_limb and phantom_camera:
			phantom_camera.set("follow_target", limb);
			phantom_camera.set("priority", 2);

		check_torso_activation();
		update_weight();


func drop_all_limbs() -> void:
	for limb in limbs:
		if limb and limb != torso and not limb.is_detached:
			drop_limb(limb);


func _any_limb_still_socketed() -> bool:
	for limb in limbs:
		if limb and limb != torso and not limb.is_detached:
			return true;
	return false;


func _add_follow_target(limb: Node3D) -> void:
	if phantom_camera:
		var targets: Array = phantom_camera.get("follow_targets");
		if targets == null: targets = [];
		if not limb in targets:
			targets.append(limb);
			phantom_camera.set("follow_targets", targets);


func _remove_follow_target(limb: Node3D) -> void:
	if limb == selected_limb: return # Selected limb MUST stay in the group
	if phantom_camera:
		var targets: Array = phantom_camera.get("follow_targets");
		if targets != null and limb in targets:
			targets.erase(limb);
			phantom_camera.set("follow_targets", targets);


func _hud_needs_periodic_update() -> bool:
	for limb in limbs:
		if limb and limb.is_retracting:
			return true;
	if selected_limb and selected_limb.is_detached and not selected_limb.is_part_enabled:
		return true;
	return false;


func _hud_selection_subline() -> String:
	for limb in limbs:
		if limb and limb.is_retracting:
			return "Recalling…";
	if selected_limb == null:
		return "";
	if selected_limb.is_detached and not selected_limb.is_part_enabled:
		return "In flight — core moves";
	if selected_limb == torso and selected_limb.is_part_enabled:
		return "Rolling torso";
	if selected_limb.is_detached and selected_limb.is_part_enabled:
		return "Rolling limb";
	if is_controlling_core:
		return "Core: move / jump";
	return "";


func _update_selection_hud() -> void:
	if selection_label == null:
		return;
	var title: String = String(selected_limb.name) if selected_limb else "—";
	var sub := _hud_selection_subline();
	if sub.is_empty():
		selection_label.text = title;
	else:
		selection_label.text = "%s\n%s" % [title, sub];


func _limb_has_valid_ground_contact(limb: BodyPart) -> bool:
	for body in limb.get_colliding_bodies():
		if limb.counts_as_ground_for_limb(body):
			return true;
	var ray := limb.get_node_or_null("RayCast3D") as RayCast3D;
	if ray != null and ray.enabled:
		ray.force_raycast_update();
		if ray.is_colliding():
			return limb.counts_as_ground_for_limb(ray.get_collider());
	return false;


func _on_limb_hit_ground(limb: BodyPart) -> void:
	if selected_limb == limb:
		# Ensure control is active once it hits ground
		is_controlling_core = false;
		limb.enable_part();
	_update_selection_hud();


func _on_limb_returned(_limb: BodyPart) -> void:
	check_torso_activation();
	update_weight();
