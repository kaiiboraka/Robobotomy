extends Node3D;

@onready var animation_player: AnimationPlayer = $AnimationPlayer;
@export var launch_speed: float = 1.0;

# known bugs:
# - registers as floor so the player sticks to it

## Called by a WeightedButton activation target. Plays the "launch" animation
## at the configured launch_speed multiplier.
func on_button_activated():
	print("launching");
	animation_player.play("launch", -1, launch_speed);
