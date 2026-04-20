@tool class_name Activated_PathFollower
extends Path3D

@export var target_follower : Node3D :
	set(val):
		target_follower = val
		if is_node_ready() and remote_transform_3d:
			_set_remote_path();

## Causes the progress along the path to repeat from the start if it finishes.
## (Forwarding loop property to PathFollow3D node.)
@export var loop : bool = true :
	set(val):
		loop = val;
		_apply_loop();

@export_range(.01,50) var moveSpeedForward : float = 1;
@export_range(.01,50) var moveSpeedBackward : float = 1;

@onready var path_follow_3d : PathFollow3D = $PathFollow3D
@onready var remote_transform_3d : RemoteTransform3D = $PathFollow3D/RemoteTransform3D

var activated : bool = false;


func _ready() -> void:
	_set_remote_path();
	_apply_loop();


func _process(delta : float) -> void:
	if Engine.is_editor_hint(): return;

	if activated:
		path_follow_3d.progress += delta * moveSpeedForward;
	else:
		path_follow_3d.progress -= delta * moveSpeedBackward;


func on_button_activated() -> void:
	activated = true;


func on_button_deactivated() -> void:
	activated = false;


func _set_remote_path() -> void:
	if not remote_transform_3d:
		printerr("remote transform is null")
		return;
	if not target_follower:
		printerr("target follower is null")
		return;
	
	remote_transform_3d.remote_path = target_follower.get_path();


func _apply_loop() -> void:
	if path_follow_3d:
		path_follow_3d.loop = loop;
