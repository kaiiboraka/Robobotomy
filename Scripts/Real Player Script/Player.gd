extends CharacterBody3D

@export var speed = 5.0
@export var jump_velocity = 4.5

@onready var head: BodyPart = $Head
@onready var torso: BodyPart = $Torso


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Constrain movement for 2.5D gameplay.
	axis_lock_linear_z = true
	
	# Initially, if the torso is attached to the player body, 
	# it should be disabled so the player script handles physics.
	if torso:
		torso.disable_part()
	if head:
		head.disable_part()
	head.core = self
	

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Number1")):
		head.enable_part()
	pass

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
