class_name Player extends CharacterBody3D

@export var speed : float = 5.0;
@export var handicapped_speed : float = 3;
@export var jump_velocity : float = 6;
@export var handicapped_jump_velocity : float = 5;
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
@onready var throw_arc : ThrowArc = $ThrowArc;
@onready var holding_spot : Node3D = $Holding_Spot;

@onready var wall_detection_right: RayCast3D = $WallDetectionRight
@onready var ledge_detection_right: RayCast3D = $LedgeDetectionRight
@onready var floor_height_detection_right: RayCast3D = $FloorHeightDetectionRight
@onready var wall_detection_left: RayCast3D = $WallDetectionLeft
@onready var ledge_detection_left: RayCast3D = $LedgeDetectionLeft
@onready var floor_height_detection_left: RayCast3D = $FloorHeightDetectionLeft


var limbs: Array = [];
var selected_limb: BodyPart = null;
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity");
var is_controlling_core: bool = true;
var weight : int = 0;
var current_jump_velocity : float = 4.5;

@export var throw_speed_min : float = 6.0;
@export var throw_speed_max : float = 14.0;


const AIM_DEADZONE : float = 0.2;
const AIM_MAX : float = 0.9;
const AIM_RAISE : float = 0.3;

var _aim_dir : Vector3 = Vector3.RIGHT;
var _aim_speed : float = 40.0;
var _aim_theta : float = 0.0;
var _aim_dir_x : float = 1.0;
var _has_aim : bool = false;

enum movement_modes {DEFAULT, ROPE, LEDGE_LEFT, LEDGE_RIGHT}
var _movement_mode: movement_modes = movement_modes.DEFAULT;

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
			# Limbs are spawned at runtime with a default (0,0,0) transform, so
			# BodyPart._ready captures a zero starting_position. Override it with the
			# player's authoritative socket table so recall/reattach returns to the
			# correct socket instead of the world origin.
			if limb.name in limb_sockets:
				limb.starting_position = limb_sockets[limb.name];
				limb.starting_rotation = Vector3.ZERO;
				
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
	
	if Input.is_action_pressed("Player_RadialMenu"):
		Interface.show_radial_menu();
		pass
	elif Input.is_action_just_released("Player_RadialMenu"):
		Interface.hide_radial_menu();
	
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
	elif Input.is_action_just_pressed("Player_CycleLimb_Forward"):
		_cycle_limb(1);
	elif Input.is_action_just_pressed("Player_CycleLimb_Backward"):
		_cycle_limb(-1);

	_update_aim();

	_position_held_limb();

	_refresh_follow_target();

	if Input.is_action_just_pressed("Player_Throw_Limb") and selected_limb and selected_limb != torso:
		if not selected_limb.is_detached:
			if _has_aim:
				selected_limb.throw(_aim_dir * _aim_speed);
				if(selected_limb is Arm and get_movement_mode() == movement_modes.ROPE):
					set_movement_mode(movement_modes.DEFAULT);
			else:
				# Throw without aiming just drops the limb back into the world
				drop_limb(selected_limb);
			# Update camera to follow the thrown/dropped limb
			_set_follow_target(selected_limb, 2);
			check_torso_activation();
			
	if Input.is_action_just_pressed("Player_Drop_Limb"):
		if selected_limb == torso:
			drop_all_limbs();
		elif selected_limb != null and not selected_limb.is_detached:
			drop_limb(selected_limb);
			if(selected_limb is Arm and get_movement_mode()==movement_modes.ROPE):
				set_movement_mode(movement_modes.DEFAULT);

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
	if not is_on_floor() and get_movement_mode() == movement_modes.DEFAULT:
		velocity.y -= gravity * delta;

	# Process movement inputs only if we are controlling the core
	if is_controlling_core:
		if(get_movement_mode() == movement_modes.ROPE):
			velocity.x = 0;
			velocity.y = 0;
			if(Input.is_action_pressed("Player_Move_Up")):
				velocity.y = 2;
			elif (Input.is_action_pressed("Player_Move_Down")):
				velocity.y = -5;
#			if(Input.is_action_pressed("Player_Move_Left")):
#				velocity.x = -2;
#			elif(Input.is_action_pressed("Player_Move_Right")):
#				velocity.x = 2;
			
			if(Input.is_action_just_pressed("Player_Jump")):
				velocity.y = current_jump_velocity
				set_movement_mode(movement_modes.DEFAULT);
				
		elif(get_movement_mode() == movement_modes.LEDGE_RIGHT):
			velocity.x = 0
			velocity.y = 0;
			position.y = floor_height_detection_right.get_collision_point().y - 2.5
			if(Input.is_action_just_pressed("Player_Jump")):
				velocity.y = current_jump_velocity
				set_movement_mode(movement_modes.DEFAULT);
			if(Input.is_action_just_pressed("Player_Move_Down")):
				set_movement_mode(movement_modes.DEFAULT)
				
		elif(get_movement_mode() == movement_modes.LEDGE_LEFT):
			velocity.x=0
			velocity.y=0
			position.y = floor_height_detection_left.get_collision_point().y - 2.5
			if(Input.is_action_just_pressed("Player_Jump")):
				velocity.y = current_jump_velocity
				set_movement_mode(movement_modes.DEFAULT);
				if(Input.is_action_just_pressed("Player_Move_Down")):
					set_movement_mode(movement_modes.DEFAULT)
		else:
			# Handle Jump.
			if Input.is_action_just_pressed("Player_Jump") and is_on_floor():
				velocity.y = current_jump_velocity;

			# Get the input direction and handle the movement/deceleration.
			var input_dir := Input.get_axis("Player_Move_Left", "Player_Move_Right");
			var move_speed : float = _get_movement_speed();

			if input_dir:
				velocity.x = input_dir * move_speed;
				
				if should_grab_ledge_right():
					set_movement_mode(movement_modes.LEDGE_RIGHT)
				elif should_grab_ledge_left():
					set_movement_mode(movement_modes.LEDGE_LEFT)
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed);
	else:
		# Decelerate naturally when not under control
		velocity.x = move_toward(velocity.x, 0, speed * delta);

	if _hud_needs_periodic_update():
		_update_selection_hud();

	var show_arc := selected_limb != null and selected_limb != torso and not selected_limb.is_detached and _has_aim
	if throw_arc != null:
		if show_arc:
			throw_arc.aim_origin = _get_throw_origin()
			throw_arc.aim_direction = _aim_dir
			throw_arc.aim_speed = _aim_speed
			throw_arc.aim_collision_mask = selected_limb.collision_mask
		throw_arc.toggle_aim(show_arc)

	move_and_slide();

func should_grab_ledge_right() -> bool:
	return wall_detection_right.is_colliding() and not ledge_detection_right.is_colliding()
func should_grab_ledge_left() -> bool:
	return wall_detection_left.is_colliding() and not ledge_detection_left.is_colliding()
	
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
			current_jump_velocity = handicapped_jump_velocity / 5;


func check_torso_activation() -> void:
	if not torso or not torso.is_connected:
		is_controlling_core = (selected_limb and selected_limb.is_detached and selected_limb.is_part_enabled);
		update_weight();
		_update_selection_hud();
		return;

	var all_others_detached : bool = true;
	for limb in limbs:
		# A limb mid-retract has already flipped is_detached=false at the START
		# of its tween, well before it's actually back home. Treat retracting
		# limbs as still-away so torso doesn't prematurely enable_part() (and
		# flip top_level) while a limb is still 0.5s from landing.
		if limb and limb != torso and (not limb.is_detached or limb.is_retracting):
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

	# Return the previously-held limb to its socket (unless it was the torso)
	if old_limb and old_limb != torso and not old_limb.is_detached:
		old_limb.position = old_limb.starting_position;
		old_limb.rotation = old_limb.starting_rotation;

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

	# Bring a socketed (non-torso) limb up to the holding spot so it can be aimed
	if selected_limb != torso and not selected_limb.is_detached and holding_spot:
		selected_limb.position = holding_spot.position;
		selected_limb.rotation = Vector3.ZERO;

	# Update camera target and priority
	if phantom_camera:
		var should_follow : bool = (selected_limb.is_detached or (selected_limb == torso and not _any_limb_still_socketed()));
		if should_follow:
			_set_follow_target(selected_limb, 2);
		else:
			# Follow the core (player) by default — never leave the group empty,
			# or the PhantomCamera resolves the (empty) target to the world origin.
			_set_follow_target(null, 0);

	# Control logic
	is_controlling_core = (selected_limb == torso and not torso.is_detached);

	if limb.is_detached and not limb.is_part_enabled and limb != torso:
		limb.enable_part();

	_update_selection_hud();

func get_movement_mode() -> movement_modes:
	return _movement_mode;
func set_movement_mode(val: movement_modes) -> void:
	_movement_mode = val;
		
func drop_limb(limb: BodyPart) -> void:
	if not limb or limb == torso or limb.is_detached: return;

	limb.global_position = global_position + global_transform.basis * limb.starting_position;
	limb.global_rotation = global_rotation + limb.starting_rotation;
	limb.drop();
	# Update camera if this was the selected limb
	if limb == selected_limb:
		_set_follow_target(limb, 2);

	check_torso_activation();

func drop_all_limbs() -> void:
	for limb in limbs:
		drop_limb(limb);
	
	if torso and torso.is_connected:
		_set_follow_target(torso, 2);
		select_limb(torso);
	elif limbs.size() > 0:
		# If no torso, maybe select the first available limb?
		select_limb(limbs[0]);


func _any_limb_still_socketed() -> bool:
	for limb in limbs:
		if limb and limb != torso and not limb.is_detached:
			return true;
	return false;


func _set_follow_target(limb: Node3D, newPriority: int = -1) -> void:
	if not phantom_camera:
		return;

	if newPriority > -1:
		phantom_camera.priority = newPriority;

	# The PhantomCamera is in GROUP follow mode: it tracks the `follow_targets`
	# array. An empty array resolves the follow point to the world origin, so we
	# ALWAYS keep exactly one target: the given limb, or the player (self) when
	# null. This keeps the camera framed on something valid at all times.
	var target : Node3D = limb if is_instance_valid(limb) else self;
	phantom_camera.follow_targets = [target];


func _refresh_follow_target() -> void:
	# Safety net: the phantom_camera addon can drop `_should_follow` to false
	# for a stray frame (e.g. mid-retract), and when that happens it snaps its
	# internal transform back to this node's own never-updated base transform
	# (the raw editor-authored coordinates on Limb_PhantomCamera3D) instead of
	# preserving the last followed position. Re-asserting the correct target
	# every physics frame means any such drop self-corrects within 1 frame
	# instead of being visible for the whole tween.
	if not phantom_camera or not selected_limb:
		return;
	var should_follow : bool = (selected_limb.is_detached or (selected_limb == torso and not _any_limb_still_socketed()));
	var target : Node3D = selected_limb if should_follow else self;
	if phantom_camera.follow_targets.size() != 1 or phantom_camera.follow_targets[0] != target:
		phantom_camera.follow_targets = [target];


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


func _update_aim() -> void:
	var stick := Input.get_vector("Player_Aim_Left", "Player_Aim_Right", "Player_Aim_Down", "Player_Aim_Up");
	if stick.length() >= AIM_DEADZONE:
		_compute_aim(stick.x, stick.y);
	else:
		_compute_aim_from_mouse();


func _compute_aim(ax: float, ay: float) -> void:
	var mag := Vector2(ax, ay).length();
	var effective: float = min(AIM_MAX, mag) / AIM_MAX;
	_aim_speed = lerp(throw_speed_min, throw_speed_max, effective);
	_aim_dir = Vector3(ax, ay, 0.0).normalized();
	_has_aim = true;


func _compute_aim_from_mouse() -> void:
	var camera := get_viewport().get_camera_3d();
	if not camera:
		_has_aim = false;
		return;
	var mouse_pos := get_viewport().get_mouse_position();
	var from := camera.project_ray_origin(mouse_pos);
	var to := from + camera.project_ray_normal(mouse_pos) * 10.0;
	var dir := (to - global_position).normalized();
	dir.z = 0.0;
	_aim_dir = dir;
	_aim_speed = throw_speed_max;
	_has_aim = true;


func _get_throw_origin() -> Vector3:
	# The player holds the limb up by their head/centre area when aiming a throw.
	if selected_limb and selected_limb != torso and not selected_limb.is_detached and holding_spot:
		var p := holding_spot.global_position;
		if _has_aim:
			p.y += AIM_RAISE;
		return p;
	return global_transform * limb_sockets["Head"];


func _position_held_limb() -> void:
	# Keep a socketed, selected limb at the holding spot; raise it while aiming.
	if not holding_spot:
		return;
	if selected_limb and selected_limb != torso and not selected_limb.is_detached:
		var target := holding_spot.position;
		if _has_aim:
			target.y += AIM_RAISE;
		selected_limb.position = target;
		selected_limb.rotation = Vector3.ZERO;


func _cycle_limb(dir: int) -> void:
	# Cycle selection through connected limbs in the numeric-select order
	# (Head=1, LArm=2, RArm=3, LLeg=4, RLeg=5), wrapping back to Torso.
	var order := [torso, head, l_arm, r_arm, l_leg, r_leg];
	if order.is_empty():
		return;
	var current_index := order.find(selected_limb);
	if current_index == -1:
		current_index = 0;
	var n := order.size();
	for i in range(1, n + 1):
		var idx := posmod(current_index + dir * i, n);
		var candidate = order[idx];
		if candidate and candidate.is_connected:
			if candidate != selected_limb:
				select_limb(candidate);
			return;
	if torso and torso.is_connected and torso != selected_limb:
		select_limb(torso);
