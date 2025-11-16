@tool
class_name LightGridLight extends MeshInstance3D

enum LightStates { LIGHT_OFF, LIGHT_ON }

const off_mat : StandardMaterial3D = preload("uid://bc2bpiqf8rw3v")
const on_mat : StandardMaterial3D = preload("uid://345vjw4gl2qv")

func _ready() -> void:
	set_state(LightStates.LIGHT_OFF)

func set_state(lightState : LightStates) -> void:
	match lightState:
		LightStates.LIGHT_OFF:
			self.set_surface_override_material(0, off_mat)
			return
		LightStates.LIGHT_ON:
			self.set_surface_override_material(0, on_mat)
			return
