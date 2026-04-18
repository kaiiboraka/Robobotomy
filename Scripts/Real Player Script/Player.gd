extends CharacterBody3D

@export var speed = 5.0
@export var jump_velocity = 4.5
@export var throw_force = 10.0

@onready var torso: BodyPart = $Torso
@onready var head: BodyPart = $Head
@onready var l_arm: BodyPart = $LeftArm
@onready var r_arm: BodyPart = $RightArm
@onready var l_leg: BodyPart = $LeftLeg
@onready var r_leg: BodyPart = $RightLeg

@onready var phantom_camera = $PhantomCamera3D

var limbs = []
var selected_limb: BodyPart = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Flag to determine if the player inputs control the CharacterBody3D
var is_controlling_core: bool = true

func _ready():
	axis_lock_linear_z = true
	
	# Torso is 0th entry, followed by Head, Arms, and Legs
	limbs = [torso, head, l_arm, r_arm, l_leg, r_leg]
	
	for limb in limbs:
		if limb:
			limb.core = self
			limb.disable_part()
			if not limb.hit_ground.is_connected(_on_limb_hit_ground):
				limb.hit_ground.connect(_on_limb_hit_ground.bind(limb))
			
			# Setup camera follow logic based on visibility
			if limb.notifier:
				limb.notifier.screen_entered.connect(_add_follow_target.bind(limb))
				limb.notifier.screen_exited.connect(_remove_follow_target.bind(limb))
				if limb.notifier.is_on_screen():
					_add_follow_target(limb)
	
	# Start with torso selected
	selected_limb = torso
	check_torso_activation()

func sync_core_to_torso():
	if not torso: return
	
	# Snap CharacterBody3D to Torso's current location
	global_position = torso.global_position - global_transform.basis * torso.starting_position
	
	# Reset torso to its relative home
	torso.disable_part()
	torso.position = torso.starting_position
	torso.rotation = Vector3.ZERO
	torso.linear_velocity = Vector3.ZERO
	torso.angular_velocity = Vector3.ZERO
	
	is_controlling_core = true

func _input(event: InputEvent) -> void:
	# Selection switching
	if event.is_action_pressed("Player_SelectLimb0_Torso"): # Backtick key
		select_limb(torso)
	elif event.is_action_pressed("Player_SelectLimb1_Head"):
		select_limb(head)
	elif event.is_action_pressed("Player_SelectLimb2_L_Arm"):
		select_limb(l_arm)
	elif event.is_action_pressed("Player_SelectLimb3_R_Arm"):
		select_limb(r_arm)
	elif event.is_action_pressed("Player_SelectLimb4_L_Leg"):
		select_limb(l_leg)
	elif event.is_action_pressed("Player_SelectLimb5_R_Leg"):
		select_limb(r_leg)

	# Throwing logic
	if event.is_action_pressed("Player_Throw_Limb") and selected_limb and selected_limb != torso:
		if not selected_limb.is_detached:
			var mouse_pos = get_viewport().get_mouse_position()
			var camera = get_viewport().get_camera_3d()
			if camera:
				var from = camera.project_ray_origin(mouse_pos)
				var to = from + camera.project_ray_normal(mouse_pos) * 10.0
				var direction = (to - selected_limb.global_position).normalized()
				direction.z = 0 # Keep it 2.5D
				
				# Stop controlling core immediately upon throw
				is_controlling_core = false
				
				selected_limb.throw(direction * throw_force)
				check_torso_activation()

	# Retraction logic
	if event.is_action_pressed("Player_Recall"):
		if torso.is_part_enabled:
			sync_core_to_torso()

		if selected_limb == torso:
			# Retract all detached limbs
			for limb in limbs:
				if limb and limb != torso and limb.is_detached:
					var tween = limb.retract()
					tween.finished.connect(_on_limb_returned.bind(limb))
		elif selected_limb and selected_limb != torso and selected_limb.is_detached:
			# Retract specifically selected limb and return control to torso
			var tween = selected_limb.retract()
			tween.finished.connect(_on_limb_returned.bind(selected_limb))
			select_limb(torso)

func _add_follow_target(limb: Node3D):
	if phantom_camera:
		var targets = phantom_camera.get("follow_targets")
		if targets == null: targets = []
		if not limb in targets:
			targets.append(limb)
			phantom_camera.set("follow_targets", targets)

func _remove_follow_target(limb: Node3D):
	if limb == selected_limb: return # Selected limb MUST stay in the group
	if phantom_camera:
		var targets = phantom_camera.get("follow_targets")
		if targets != null and limb in targets:
			targets.erase(limb)
			phantom_camera.set("follow_targets", targets)

func check_torso_activation():
	var all_others_detached = true
	for limb in limbs:
		if limb != torso and limb and not limb.is_detached:
			all_others_detached = false
			break
	
	if all_others_detached:
		if selected_limb == torso:
			is_controlling_core = false
			torso.enable_part()
	else:
		# If we have limbs attached, the core (CharacterBody3D) handles movement
		torso.disable_part()
		if selected_limb == torso:
			is_controlling_core = true

func select_limb(limb: BodyPart):
	if not limb: return
	
	var old_limb = selected_limb
	
	# Disable control of the previously selected limb if it was active
	if selected_limb:
		selected_limb.deselect()
		if selected_limb == torso and selected_limb.is_part_enabled:
			sync_core_to_torso()
		else:
			selected_limb.disable_part()

	selected_limb = limb
	selected_limb.on_select()
	_add_follow_target(selected_limb)
	
	# If old limb is no longer selected and is off-screen, remove it from camera
	if old_limb and old_limb != selected_limb:
		if old_limb.notifier and not old_limb.notifier.is_on_screen():
			_remove_follow_target(old_limb)
		elif old_limb == torso: # Always remove torso from follow if not selected
			_remove_follow_target(old_limb)
	
	print("Selected: ", limb.name)
	
	if limb == torso:
		check_torso_activation()
	else:
		if limb.is_detached:
			# Enable limb control immediately if it's already landed or moving
			limb.enable_part()
			is_controlling_core = false
		else:
			# Attached limb selected, main body is controlled
			is_controlling_core = true

func _on_limb_hit_ground(limb: BodyPart):
	if selected_limb == limb:
		# Ensure control is active once it hits ground
		is_controlling_core = false
		limb.enable_part()

func _on_limb_returned(_limb: BodyPart):
	check_torso_activation()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Process movement inputs only if we are controlling the core
	if is_controlling_core:
		# Handle Jump.
		if Input.is_action_just_pressed("Player_Jump") and is_on_floor():
			velocity.y = jump_velocity

		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_axis("Player_Move_Left", "Player_Move_Right")
		
		if input_dir:
			velocity.x = input_dir * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
	else:
		# Decelerate naturally when not under control
		velocity.x = move_toward(velocity.x, 0, speed * delta)

	move_and_slide()

"""
Brainstorm thoughts on next steps:

OK so I have a player who is in charge of managing each body part each body part knows if it's selected and can be enabled or disabled .  
Pressing a number should switch selection to the corresponding body part with numbers one through 5 correlating to head arm arm leg leg , probably. 
The backtick key should select the torso which is the core. If you have the core selected and you press the retract key it should retract all parts or try to. If you have a different limb selected and press the retract key it will just try to retract this one and go back to the torso.
Now for enabling and disabling: A limb should only be enabled if it has been detached. I believe it only gets detached if it gets thrown. And it only gets thrown if you have it selected already. So the enable has to happen in stages probably ? Where it needs to become top level I think and only enable its controls once it hits the ground at which point everything else should be disabled which probably means we need a signal for the moment of touching the ground . There is already a tween that move's position of a body part back to the core Now we need to respond to that tween and enable control of the main body once we've come back to the core.
"""
