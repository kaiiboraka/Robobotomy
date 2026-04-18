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

var limbs = []
var selected_limb: BodyPart = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

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
	
	# Start with torso selected
	selected_limb = torso

func _input(event: InputEvent) -> void:
	# Selection switching
	if event is InputEventKey and event.pressed:
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
				selected_limb.throw(direction * throw_force)

	# Retraction logic
	if event.is_action_pressed("Player_Recall"):
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

func select_limb(limb: BodyPart):
	if not limb: return
	selected_limb = limb
	print("Selected: ", limb.name)
	
	# If we switch to a limb that is already detached and on the ground, 
	# we should probably ensure it's enabled and the core is disabled.
	if limb != torso and limb.is_detached and limb.is_part_enabled:
		set_physics_process(false)
	elif limb == torso:
		set_physics_process(true)

func _on_limb_hit_ground(limb: BodyPart):
	if selected_limb == limb:
		# Disable main body movement if we are controlling a limb
		set_physics_process(false)
		limb.enable_part()

func _on_limb_returned(_limb: BodyPart):
	# If we are back to controlling the torso, re-enable physics process
	if selected_limb == torso:
		set_physics_process(true)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Player_Jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_axis("Player_Move_Left", "Player_Move_Right")
	
	if input_dir:
		velocity.x = input_dir * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

"""
Brainstorm thoughts on next steps:

OK so I have a player who is in charge of managing each body part each body part knows if it's selected and can be enabled or disabled .  
Pressing a number should switch selection to the corresponding body part with numbers one through 5 correlating to head arm arm leg leg , probably. 
The backtick key should select the torso which is the core. If you have the core selected and you press the retract key it should retract all parts or try to. If you have a different limb selected and press the retract key it will just try to retract this one and go back to the torso.
Now for enabling and disabling: A limb should only be enabled if it has been detached. I believe it only gets detached if it gets thrown. And it only gets thrown if you have it selected already. So the enable has to happen in stages probably ? Where it needs to become top level I think and only enable its controls once it hits the ground at which point everything else should be disabled which probably means we need a signal for the moment of touching the ground . There is already a tween that move's position of a body part back to the core Now we need to respond to that tween and enable control of the main body once we've come back to the core.
"""
