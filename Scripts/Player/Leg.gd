class_name Leg extends BodyPart

const FRICTIONLESS_MATERIAL : PhysicsMaterial = preload("uid://dk162vpoy6b84")


func _ready() -> void:
	super._ready();
	_set_frictionless();


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_update_friction_mode(state);
	if not is_part_enabled or not accepts_player_input:
		return;

	# Unified movement and jumping
	handle_movement(state);
	handle_jump(state);



## Apply the frictionless material override so the limb slides off walls.
func _set_frictionless() -> void:
	physics_material_override = FRICTIONLESS_MATERIAL;


## Remove the material override so the body uses its default friction.
func _clear_friction_override() -> void:
	physics_material_override = null;


## Switch between frictionless and default friction.
## Frictionless while rising (mid-jump) or airborne; normal friction only
## when definitively grounded and not moving upward.
## The jump-triggered catch + velocity.y check together ensure the very first
## upward frame is covered even when the impulse applies on the next tick.
func _update_friction_mode(state: PhysicsDirectBodyState3D) -> void:
	if state.linear_velocity.y > 0.1 or Input.is_action_just_pressed("Player_Jump"):
		_set_frictionless();
	elif _is_definitely_grounded(state):
		_clear_friction_override();
	else:
		_set_frictionless();


## Returns true when the limb is definitively resting on a horizontal surface.
## Requires a contact with a steep vertical normal (> 0.8). When a RayCast3D
## child exists it must also hit, eliminating false positives from wall contacts.
func _is_definitely_grounded(state: PhysicsDirectBodyState3D) -> bool:
	var has_steep_contact := false;
	for i in range(state.get_contact_count()):
		if state.get_contact_local_normal(i).y > 0.8:
			has_steep_contact = true;
			break;

	if not has_steep_contact:
		return false;

	var ray := get_node_or_null("RayCast3D") as RayCast3D;
	if ray:
		return ray.is_colliding();
	return true;
