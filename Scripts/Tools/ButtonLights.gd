@tool
extends Node3D

enum LightState { OFF, ERROR, PARTIAL, FULL }

@export_range(1, 9) var weight: int = 1:
	set(val):
		weight = val;
		current_weight = clamp(current_weight, 0, weight);
		if is_node_ready():
			update_lights();
			update_materials();

@export var current_weight: int = 0:
	set(val):
		current_weight = clamp(val, 0, weight);
		if is_node_ready():
			update_materials();

@export var spacing: float = 0.22;
@export var template_node: MeshInstance3D:
	set(val):
		template_node = val;
		if is_node_ready():
			update_lights();
			update_materials();

@export var state_materials: Dictionary[LightState, StandardMaterial3D]

@onready var hub_mesh: MeshInstance3D = $Hub_MeshInstance3D;

func _ready():
	if get_parent() and get_parent().get("trigger_weight") != null:
		weight = get_parent().trigger_weight;
	update_lights();
	update_materials();

func update_lights():
	# Clean up generated nodes
	for child in get_children():
		if child.name.begins_with("Generated_"):
			child.free();

	if not template_node:
		return;

	# Hide template but keep it as base
	template_node.visible = false;

	var grid_points = [];

	match weight:
		1, 2, 3:
			# Stacks vertically
			for i in range(weight):
				grid_points.append(Vector2i(0, i));
		4:
			# 2x2 grid
			grid_points = [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)];
		5:
			# Row of 3 on bottom, row of 2 on top
			grid_points = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)];
		6:
			# Two rows of 3
			grid_points = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)];
		7, 8, 9:
			# Two rows of 3, then fill third row
			for y in range(2):
				for x in range(3):
					grid_points.append(Vector2i(x, y));
			var top_row_count = weight - 6;
			for x in range(top_row_count):
				grid_points.append(Vector2i(x, 2));

	# Create new meshes
	var base_pos = template_node.position;
	for i in range(grid_points.size()):
		var p = grid_points[i];
		var mi = template_node.duplicate();
		mi.name = "Generated_Light_" + str(i + 1);
		mi.visible = true;
		# Apply procedural position relative to parent: Spread on Z (columns) and Y (rows)
		mi.position = Vector3(base_pos.x, base_pos.y + (p.y * spacing), base_pos.z + (p.x * spacing));
		add_child(mi);
		if Engine.is_editor_hint():
			mi.owner = get_tree().edited_scene_root if get_tree() else owner;

	update_materials();

func update_materials():
	var total_required = weight;
	var is_full = current_weight >= total_required;
	var is_partial = current_weight > 0 and current_weight < total_required;

	# Find hub mesh reliably
	var hub = get_node_or_null("Hub_MeshInstance3D");

	# Determine Hub Material
	var hub_mat = state_materials.get(LightState.OFF);
	if is_full:
		hub_mat = state_materials.get(LightState.FULL);
	elif is_partial:
		hub_mat = state_materials.get(LightState.ERROR);

	if hub:
		_set_surface_material(hub, "button_light", hub_mat);

	# Update generated lights
	var generated_lights = [];
	for child in get_children():
		if child.name.begins_with("Generated_"):
			generated_lights.append(child);

	# Sort by name to ensure consistent lighting order
	generated_lights.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0);

	for i in range(generated_lights.size()):
		var light = generated_lights[i];
		var light_mat = state_materials.get(LightState.OFF);

		if is_full:
			light_mat = state_materials.get(LightState.FULL);
		elif i < current_weight:
			light_mat = state_materials.get(LightState.PARTIAL);

		_set_surface_material(light, "button_light", light_mat);

func _set_surface_material(mi: MeshInstance3D, surface_name: String, mat: Material):
	if not mi or not mi.mesh: return;
	for i in range(mi.mesh.get_surface_count()):
		if mi.mesh.surface_get_name(i) == surface_name:
			mi.set_surface_override_material(i, mat);
			return;
