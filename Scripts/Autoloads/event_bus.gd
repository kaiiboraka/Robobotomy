extends Node
## An event handler for signals

## Emits when a limb is selected
signal limb_selected(slot: int)

## Ids for the limbs go in the order (from 0-5):
## Torso, Head, Left Arm, Left Leg, Right Leg, Right Arm
## The array contain the corresponding player limb id
var ui_limb_ids = [2, 0, 1, 4, 5, 3]

## Emits the limb_selected signal when called 
##
## Meant for the player scripts to utilize to know
## which limb is selected for throwing.
func emit_limb_selected(slot: int):
	# Slot goes from -1 - 4, so we add 1
	var correct_slot = ui_limb_ids[slot + 1]
	limb_selected.emit(correct_slot)


#region
# These are the limb ids that we will convert between
# Player Limb Ids (as handled in the player.cs script)
# 0 - Head
# 1 - Left Arm
# 2 - Torso
# 3 - Right Arm
# 4 - Left Leg
# 5 - Right Leg
#
# Radial Menu Limb Ids (will be shifted up +1
# to start at index 0)
# -1 - Torso
# 0 - Head
# 1 - Left Arm
# 2 - Left Leg
# 3 - Right Leg
# 4 - Right Arm
#endregion
