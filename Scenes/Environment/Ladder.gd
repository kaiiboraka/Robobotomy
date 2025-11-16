class_name Ladder
extends Climbable


func interact_with(interactor: Node3D) -> void:
	pass

func stop_interaction(interactor: Node3D) -> void:
	pass

func get_grab_point() -> Vector3:
	return Vector3.ZERO

func climb(dir: Vector3, force: float) -> void:
	pass

func push(dir: Vector3, force: float) -> void:
	pass
