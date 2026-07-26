extends CharacterBody3D
var control: bool;
var control_arm: BodyPart = null;
var magnetized: bool;
#var velocity: Vector3;
var crates: Array[Crate]
var weight: int = 3;
@onready var sticky_area: Area3D = $StickyArea
@export var crane_area: Area3D;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	velocity = Vector3(0,0,0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	axis_input();
	if(!control_arm):
		return;
	if(Player.instance and !Player.instance.is_controlling_arm(control_arm)):
		return
	if(Input.is_action_pressed("Player_Jump")):
		magnetized = true
	else:
		magnetized = false
	if magnetized:
		for crate in crates:
			crate.constant_force = Vector3(0, 0, 0)
			crate.constant_torque = Vector3(0, 0, 0)
			crate.global_position.z = 0;
			crate.global_rotation = Vector3(0, 0, 0);
			crate.add_constant_central_force(100*(self.position-crate.position).normalized())
		print("I am magnetized!")
	else:
		for crate in crates:
			crate.constant_force = Vector3(0, 0, 0)
			crate.constant_torque = Vector3(0, 0, 0)
	
	move_and_slide()
	pass


func axis_input() -> void:
	if !control: return;
	var x_input_dir := Input.get_axis("Player_Move_Left", "Player_Move_Right");
	if x_input_dir:
		velocity.x = x_input_dir * 5;
	else:
		velocity.x = 0
	var y_input_dir := Input.get_axis("Player_Move_Down", "Player_Move_Up");
	if y_input_dir:
		velocity.y = y_input_dir * 5;
	else:
		velocity.y = 0


#func _input(event: InputEvent) -> void:
	#pass


func on_activated_by_arm(arm: BodyPart) -> void:
	control = true
	control_arm = arm;

func on_button_deactivated() -> void:
	control = false
	control_arm = null;

func _on_area_3d_body_entered(body: Node3D) -> void:
	if(!body is Crate):
		return
	crates.push_back(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if(!body is Crate):
		return
	crates.erase(body);
