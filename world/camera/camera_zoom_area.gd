extends Area3D
class_name CameraZoomArea
## Area3D object that causes the camera to zoom in/out

@export var camera_distance: float = 100

var bodyParts: Array[BodyPart]
var _cached_player: Player
var player: Player :
	get:
		if not is_instance_valid(_cached_player):
			_cached_player = Player.instance
		return _cached_player

@onready var phantom_camera: PhantomCamera3D = $PhantomCamera3D


func _ready():
	player= Player.instance
	phantom_camera.position = Vector3(0, 0, camera_distance)

## Selects the zoom camera
func select():
	phantom_camera.set_priority(3)

## Deselects the zoom camera and goes back to the default cam
func deselect():
	phantom_camera.set_priority(-1)


func _on_body_entered(body: Node3D) -> void:
	if(body is BodyPart):
		bodyParts.append(body)
		player.add_camera_zoom_area(body, self)
		
		if(player.is_controlling_limb(body)):
			select()


func _on_body_exited(body: Node3D) -> void:
	if(body is BodyPart):
		bodyParts.erase(body)
		player.remove_camera_zoom_area(body)
		
		if(player.is_controlling_limb(body)):
			phantom_camera.set_priority(-1)
