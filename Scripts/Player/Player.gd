class_name Player extends CharacterBody3D

@export var speed : float = 5.0;
@export var handicapped_speed : float = 2.5;
@export var jump_velocity : float = 4.5;
@export var handicapped_jump_velocity : float = 2.5;

@onready var torso : BodyPart = $Torso;
@onready var head : BodyPart = $Head;
@onready var l_arm : BodyPart = $LeftArm;
@onready var r_arm : BodyPart = $RightArm;
@onready var l_leg : BodyPart = $LeftLeg;
@onready var r_leg : BodyPart = $RightLeg;
@onready var phantom_camera : PhantomCamera3D = $Limb_PhantomCamera3D;
@onready var selection_label : Label3D = $Label3D;
@onready var neck : MeshInstance3D = $Neck;
@onready var tall_collider : CollisionShape3D = $Tall_CollisionShape3D;
@onready var short_collider : CollisionShape3D = $Short_CollisionShape3D;

var limbs: Array = [];
var selected_limb: BodyPart = null;
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity");
var is_controlling_core: bool = true;
var weight : int = 0;
var current_jump_velocity : float = 4.5;

var limb_sockets := {
	"Head": Vector3(0, 2.9366379, 0),
	"Torso": Vector3(0, 2.0686834, 0),
	"LeftArm": Vector3(0.86595744, 2.4061642, 0),
	"RightArm": Vector3(-0.8641265, 2.4061642, 0),
	"LeftLeg": Vector3(0.223, 0.89, 0),
	"RightLeg": Vector3(-0.223, 0.89, 0)
};

static var instance: Player

func _ready() -> void:
	if Engine.is_editor_hint():
		return; # This is for lighting. I just dont want it to run while in the editor. You can delete it, but beware j
		
	if(instance == null):
		instance = self
	else:
		queue_free()
		
	axis_lock_linear_z = true;
	
	# Only register limbs that start connected
	var possible_limbs = [torso, head, l_arm, r_arm, l_leg, r_leg];
	limbs = [];
	
	for limb in possible_limbs:
		if limb:
			if limb.is_connected:
				_init_limb(limb);
				limbs.append(limb);
			else:
				limb.core = self;
				
	apply_cell_shader_file()
	# Start with torso selected if available
	if torso and torso.is_connected:
		check_torso_activation();
		select_limb(torso);


func _init_limb(limb: BodyPart) -> void:
	limb.core = self;
	limb.disable_part();
	if not limb.hit_ground.is_connected(_on_limb_hit_ground):
		limb.hit_ground.connect(_on_limb_hit_ground.bind(limb));


func register_limb(limb: BodyPart) -> void:
	match limb.name:
		"Head": head = limb;
		"LeftArm": l_arm = limb;
		"RightArm": r_arm = limb;
		"LeftLeg": l_leg = limb;
		"RightLeg": r_leg = limb;
		"Torso": torso = limb;

	if not limb in limbs:
		limbs.append(limb);
	
	# Ensure starting positions are set if it was picked up from the world
	if limb.name in limb_sockets:
		limb.starting_position = limb_sockets[limb.name];
		limb.starting_rotation = Vector3.ZERO;
		
	_init_limb(limb);
	check_torso_activation();
	update_weight();
	_update_selection_hud();


func _physics_process(delta: float) -> void:
	# just_pressed avoids re-running select_limb every frame while a limb key is held
	if Input.is_action_just_pressed("Player_SelectLimb0_Torso") and torso and torso.is_connected:
		select_limb(torso);
	elif Input.is_action_just_pressed("Player_SelectLimb1_Head") and head and head.is_connected:
		select_limb(head);
	elif Input.is_action_just_pressed("Player_SelectLimb2_L_Arm") and l_arm and l_arm.is_connected:
		select_limb(l_arm);
	elif Input.is_action_just_pressed("Player_SelectLimb3_R_Arm") and r_arm and r_arm.is_connected:
		select_limb(r_arm);
	elif Input.is_action_just_pressed("Player_SelectLimb4_L_Leg") and l_leg and l_leg.is_connected:
		select_limb(l_leg);
	elif Input.is_action_just_pressed("Player_SelectLimb5_R_Leg") and r_leg and r_leg.is_connected:
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

	if Input.is_action_just_pressed("Player_Drop_Limb"):
		if selected_limb == torso:
			drop_all_limbs();
		elif selected_limb != null and not selected_limb.is_detached:
			drop_limb(selected_limb);

	if Input.is_action_just_pressed("Player_Recall"):
		if torso and torso.is_connected and torso.is_part_enabled:
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
		check_torso_activation();
		_update_selection_hud();

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta;

	# Process movement inputs only if we are controlling the core
	if is_controlling_core:
		# Handle Jump.
		if Input.is_action_just_pressed("Player_Jump") and is_on_floor():
			velocity.y = current_jump_velocity;

		# Get the input direction and handle the movement/deceleration.
		var input_dir := Input.get_axis("Player_Move_Left", "Player_Move_Right");
		var move_speed : float = _get_movement_speed();

		if input_dir:
			velocity.x = input_dir * move_speed;
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed);
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
	
	# Reattach torso before resetting local transform.
	# If top_level is still true here, setting position writes world-space and can launch torso away.
	torso.is_detached = false;
	torso.disable_part();
	torso.top_level = false;
	torso.position = torso.starting_position;
	torso.rotation = torso.starting_rotation;
	torso.linear_velocity = Vector3.ZERO;
	torso.angular_velocity = Vector3.ZERO;
	
	is_controlling_core = true;
	_update_selection_hud();


func update_weight() -> void:
	var total : int = 0;
	var attached_count : int = 0;
	# Torso only contributes to core weight if it isn't "detached" (lone/rolling)
	if torso and not torso.is_detached:
		total += torso.weight;
	for limb in limbs:
		if limb and limb != torso and not limb.is_detached:
			total += limb.weight;
			attached_count += 1;
	weight = total;
	if torso and "limbs_attached" in torso:
		torso.limbs_attached = attached_count;
	if neck and head:
		neck.visible = not head.is_detached;
	_update_colliders();


func _get_movement_speed() -> float:
	var leg_count : int = 0;
	if l_leg and not l_leg.is_detached:
		leg_count += 1;
	if r_leg and not r_leg.is_detached:
		leg_count += 1;

	if leg_count == 2:
		return speed;
	elif leg_count == 1:
		return handicapped_speed;
	return speed;


func _update_colliders() -> void:
	var leg_count : int = 0;
	if l_leg and not l_leg.is_detached:
		leg_count += 1;
	if r_leg and not r_leg.is_detached:
		leg_count += 1;

	if leg_count > 0:
		tall_collider.disabled = false;
		short_collider.disabled = true;
	else:
		tall_collider.disabled = true;
		short_collider.disabled = false;
	
	match leg_count:
		2:
			current_jump_velocity = jump_velocity;
		1:
			current_jump_velocity = handicapped_jump_velocity;
		0:
			current_jump_velocity = handicapped_jump_velocity / 2;


func check_torso_activation() -> void:
	if not torso or not torso.is_connected:
		is_controlling_core = (selected_limb and selected_limb.is_detached and selected_limb.is_part_enabled);
		update_weight();
		_update_selection_hud();
		return;

	var all_others_detached : bool = true;
	for limb in limbs:
		if limb and limb != torso and not limb.is_detached:
			all_others_detached = false;
			break;

	torso.is_detached = all_others_detached;
	if all_others_detached:
		torso.enable_part();
	else:
		torso.disable_part();

	# Synchronize core control state based on activation
	is_controlling_core = not (torso.is_detached or 
		(selected_limb and selected_limb.is_detached and selected_limb.is_part_enabled));

	update_weight(); # weight depends on is_detached status
	_update_selection_hud();


func select_limb(limb: BodyPart) -> void:
	if not limb: return;
	if selected_limb == limb:
		# Re-tap while thrown but not yet control-enabled (e.g. missed hit_ground): wake if already on solid.
		if limb.is_detached and not limb.is_part_enabled and _limb_has_valid_ground_contact(limb):
			is_controlling_core = false;
			limb.enable_part();
			_update_selection_hud();
			return;
		return;

	var old_limb := selected_limb;

	# Disable all limbs, then enable selected
	for l in limbs:
		if l:
			l.set_accepts_player_input(false);
			l.deselect();
			if l != torso:
				l.disable_part();

	# Handle torso specific logic
	if selected_limb == torso and selected_limb.is_part_enabled:
		# Rolling torso: only snap back onto the CharacterBody when other limbs are still socketed.
		if _any_limb_still_socketed():
			sync_core_to_torso();

	selected_limb = limb;
	selected_limb.on_select();
	selected_limb.set_accepts_player_input(true);

	# Update camera target and priority
	if phantom_camera:
		phantom_camera.follow_targets = [];
		var should_follow : bool = (selected_limb.is_detached or (selected_limb == torso and not _any_limb_still_socketed()));
		if should_follow:
			_add_follow_target(selected_limb, 2);
		else:
			_add_follow_target(null, 0);

	# If old limb is no longer selected and is off-screen, remove it from camera
	if old_limb and old_limb != selected_limb:
		if old_limb.notifier and not old_limb.notifier.is_on_screen():
			_remove_follow_target(old_limb);
		elif old_limb == torso: # Always remove torso from follow if not selected
			_remove_follow_target(old_limb);

	# Control logic
	is_controlling_core = (selected_limb == torso and not torso.is_detached);

	if limb.is_detached and not limb.is_part_enabled and limb != torso:
		limb.enable_part();

	_update_selection_hud();


func drop_limb(limb: BodyPart) -> void:
	if not limb or limb == torso or limb.is_detached: return;

	limb.global_position = global_position + global_transform.basis * limb.starting_position;
	limb.global_rotation = global_rotation + limb.starting_rotation;
	limb.drop();
	# Update camera if this was the selected limb
	if limb == selected_limb:
		_add_follow_target(limb, 2);

	check_torso_activation();

func drop_all_limbs() -> void:
	for limb in limbs:
		drop_limb(limb);
	
	if torso and torso.is_connected:
		_add_follow_target(torso, 2);
		select_limb(torso);
	elif limbs.size() > 0:
		# If no torso, maybe select the first available limb?
		select_limb(limbs[0]);


func _any_limb_still_socketed() -> bool:
	for limb in limbs:
		if limb and limb != torso and not limb.is_detached:
			return true;
	return false;


func _add_follow_target(limb: Node3D, newPriority: int = -1) -> void:
	if not phantom_camera:
		return;

	if newPriority > -1:
		phantom_camera.priority = newPriority;

	if not limb:
		phantom_camera.follow_target = null;
		return;

	if phantom_camera.follow_mode == PhantomCamera3D.FollowMode.GROUP:
		var targets : Array = phantom_camera.follow_targets;
		if targets == null:
			targets = [];
		if not limb in targets:
			targets.append(limb);
			phantom_camera.follow_targets = targets;
	else:
		phantom_camera.follow_target = limb;


func _remove_follow_target(limb: Node3D, newPriority: int = -1) -> void:
	if not phantom_camera: return;
	if (newPriority > -1): phantom_camera.priority = newPriority;
	if phantom_camera.follow_mode != PhantomCamera3D.FollowMode.GROUP: return;
	if limb == selected_limb: return # Selected limb MUST stay in the group
	
	var targets: Array = phantom_camera.follow_targets;
	if targets != null and limb in targets:
		targets.erase(limb);
		phantom_camera.follow_targets = targets;


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

func spawn_at(target_position : Vector3) -> void:
	global_position = target_position;
	velocity = Vector3.ZERO;
	
#	for lighting

func apply_cell_shader_file():
	var cel_shader = preload("res://Scripts/Lighting/cell_shader.gdshader")
	
	if neck:
		_inject_shader_preserving_texture(neck, cel_shader)

	# Process every tracking limb entry
	for limb in limbs:
		if not limb:
			continue
			
		if limb.has_method("enable_part") or "is_detached" in limb:
			_apply_material_recursively(limb, cel_shader)

# Walks down the scene sub-tree to touch every mesh in player
func _apply_material_recursively(node: Node, shader_file: Shader) -> void:
	if node != torso and node != head and node != l_arm and node != r_arm and node != l_leg and node != r_leg:
		if node.get_script() != null:
			return

	if node is MeshInstance3D:
		_inject_shader_preserving_texture(node, shader_file)
		
	for child in node.get_children():
		_apply_material_recursively(child, shader_file)


func _inject_shader_preserving_texture(mesh: MeshInstance3D, shader_file: Shader) -> void:
	if mesh.mesh == null or mesh.mesh.get_surface_count() == 0:
		return

	if mesh.material_override is ShaderMaterial and mesh.material_override.shader == shader_file:
		return

	var existing_texture: Texture2D = null
	
	if mesh.material_override is BaseMaterial3D and mesh.material_override.albedo_texture:
		existing_texture = mesh.material_override.albedo_texture
	elif mesh.get_active_material(0) is BaseMaterial3D:
		var active_mat = mesh.get_active_material(0) as BaseMaterial3D
		if active_mat and active_mat.albedo_texture:
			existing_texture = active_mat.albedo_texture

	var new_cel_mat := ShaderMaterial.new()
	new_cel_mat.shader = shader_file
	
	new_cel_mat.set_shader_parameter("albedo_color", Color.WHITE)
	new_cel_mat.set_shader_parameter("steps", 3.0)
	
	if existing_texture:
		new_cel_mat.set_shader_parameter("main_texture", existing_texture)
		
	mesh.material_override = new_cel_mat
