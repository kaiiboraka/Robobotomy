extends RollingBodyPart

var limbs_attached = 0

# Torso only rolls if no limbs are attached.
func should_roll() -> bool:
	return limbs_attached == 0;
