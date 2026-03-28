extends State
class_name PlayerState 

const IDLE = "Idle"
const WALKING = "Walking"
const RUNNING = "Running"
const JUMPING = "Jumping"
const FALLING = "Falling"

var player: Nameless

func _ready() -> void:
	await owner.ready
	print("owner.name: %s" % owner.name)
	print("owner: %s" % owner)
	print("owner path: %s" % owner.get_path())
	player = owner as Nameless
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
