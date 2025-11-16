@abstract class_name Climbable
extends Interactable

## Climbing speed determines how fast the Player can climb the rope. This is a multiplier to their normal speed.
@export var climbSpeed: float = 0.2
## Slide speed determines how fast the Player slides down the rope. This is a mutliplier to their normal speed.
@export var slideSpeed: float = 1.0

@abstract func interact_with(interactor: Node3D) -> void
@abstract func get_grab_point() -> Vector3
@abstract func climb(dir: Vector3, force: float) -> void
@abstract func push(dir: Vector3, force: float) -> void
