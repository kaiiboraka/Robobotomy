@tool
class_name LimbToggler
extends Node3D

# This script directly reparents MeshInstance3D nodes from a Skeleton3D
# to their correct parent nodes in the model hierarchy.
# The keys are the names of the meshes currently under the Skeleton.
# The values are the paths to the TARGET PARENT nodes, relative to model_root.

const MAPPING = {
	"Chest": "Top_Half",
	"Heart": "Top_Half",
	"Hips": "Top_Half",
	"Neck": "Top_Half/Neck_Head",
	"Right_Upper_Arm": "Top_Half/R_Arm",
	"Left_Upper_Arm": "Top_Half/L_Arm",
	"Left_Upper_Leg": "Bottom_Half/L_Leg",
	"Right_Upper_Leg": "Bottom_Half/R_Leg",
	"Head_and_Hair": "Top_Half/Neck_Head/Head_New",
	"Hair_tuft": "Top_Half/Neck_Head/Head_New",
	"Right_LBow_Light": "Top_Half/R_Arm/R_ForeArm",
	"Right_Forearm": "Top_Half/R_Arm/R_ForeArm",
	"Right_Wrist_Light": "Top_Half/R_Arm/R_ForeArm",
	"Right_Hand": "Top_Half/R_Arm/R_ForeArm",
	"Left_Bow_Light": "Top_Half/L_Arm/L_ForeArm",
	"Left_Forearm": "Top_Half/L_Arm/L_ForeArm",
	"Left_Wrist_Light": "Top_Half/L_Arm/L_ForeArm",
	"Left_Hand": "Top_Half/L_Arm/L_ForeArm",
	"Left_Lower_Leg": "Bottom_Half/L_Leg/L_Lower_Leg",
	"Left_Knee_Light": "Bottom_Half/L_Leg/L_Lower_Leg",
	"Left_Armor_Bit": "Bottom_Half/L_Leg/L_Lower_Leg",
	"Left_Ankle_Light": "Bottom_Half/L_Leg/L_Lower_Leg",
	"Left_Foot": "Bottom_Half/L_Leg/L_Lower_Leg",
	"Right_Lower_Leg": "Bottom_Half/R_Leg/R_Lower_Leg",
	"Right_Knee_Light": "Bottom_Half/R_Leg/R_Lower_Leg",
	"Right_Armor_Bit": "Bottom_Half/R_Leg/R_Lower_Leg",
	"Right_Ankle_Light": "Bottom_Half/R_Leg/R_Lower_Leg",
	"Right_Foot": "Bottom_Half/R_Leg/R_Lower_Leg"
}
@onready var r_arm: Node3D = $Nam_Rig/Full_Nameless_Model/Top_Half/R_Arm
@onready var l_arm: Node3D = $Nam_Rig/Full_Nameless_Model/Top_Half/L_Arm
@onready var l_leg: Node3D = $Nam_Rig/Full_Nameless_Model/Bottom_Half/L_Leg
@onready var r_leg: Node3D = $Nam_Rig/Full_Nameless_Model/Bottom_Half/R_Leg
@onready var skeleton: Skeleton3D = $Nam_Rig/Skeleton3D
@onready var model_root: Node3D = $Nam_Rig/Full_Nameless_Model
@onready var neck_head: Node3D = $Nam_Rig/Full_Nameless_Model/Top_Half/Neck_Head

@export_tool_button("Direct Reparent Meshes") var run_fix = fix_hierarchy

@export_group("Limb Visibility")
@export_tool_button("Toggle Head") var toggle_head_btn = toggle_head
@export_tool_button("Toggle Right Arm") var toggle_r_arm_btn = toggle_r_arm
@export_tool_button("Toggle Left Arm") var toggle_l_arm_btn = toggle_l_arm
@export_tool_button("Toggle Right Leg") var toggle_r_leg_btn = toggle_r_leg
@export_tool_button("Toggle Left Leg") var toggle_l_leg_btn = toggle_l_leg

func toggle_head():
	if neck_head: neck_head.visible = not neck_head.visible

func toggle_r_arm():
	if r_arm: r_arm.visible = not r_arm.visible

func toggle_l_arm():
	if l_arm: l_arm.visible = not l_arm.visible

func toggle_r_leg():
	if r_leg: r_leg.visible = not r_leg.visible

func toggle_l_leg():
	if l_leg: l_leg.visible = not l_leg.visible


func fix_hierarchy():
	if not model_root or not skeleton:
		printerr("MeshHierarchyFixer: Assign Model Root and Skeleton in inspector.")
		return
	
	var scene_root = get_tree().edited_scene_root
	if not scene_root:
		printerr("MeshHierarchyFixer: Open the scene in the editor.")
		return

	print("MeshHierarchyFixer: Starting Direct Reparent...")
	
	# Process shallower paths first to ensure parents are moved before their children
	var mesh_names = MAPPING.keys()
	mesh_names.sort_custom(func(a, b): return MAPPING[a].count("/") < MAPPING[b].count("/"))
	
	var moved_count = 0
	for mesh_name in mesh_names:
		var mesh = skeleton.get_node_or_null(mesh_name)
		if not mesh:
			# Fallback for common importer renaming
			for child in skeleton.get_children():
				if child.name.begins_with(mesh_name) and child is MeshInstance3D:
					mesh = child
					break
		
		if not mesh:
			print("MeshHierarchyFixer: Mesh '", mesh_name, "' not found under skeleton.")
			continue
			
		var parent_path = MAPPING[mesh_name]
		var target_parent = model_root.get_node_or_null(parent_path)
		
		if target_parent:
			print("MeshHierarchyFixer: Reparenting '", mesh.name, "' to '", target_parent.get_path(), "'")
			var global_trans = mesh.global_transform
			
			# Standard reparenting logic
			if mesh.get_parent():
				mesh.get_parent().remove_child(mesh)
			target_parent.add_child(mesh)
			
			# Restore properties
			mesh.global_transform = global_trans
			mesh.skeleton = mesh.get_path_to(skeleton)
			mesh.owner = scene_root
			moved_count += 1
		else:
			printerr("MeshHierarchyFixer: ERROR -> Target parent path '", parent_path, "' not found under model_root.")

	print("MeshHierarchyFixer: Successfully moved ", moved_count, " meshes.")
