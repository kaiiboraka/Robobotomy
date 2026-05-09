## Triggers its targets based on a variable number of its own
## triggers firing.
##
## This node can be set to trigger when at least 
## [param min_triggers] of its triggers have fired; it 
## will call [method on_button_activated] on all of
## its [param activation_targets]. If the number of triggers of this
## [TriggerPredicate] drop below [param min_triggers], this  
## node will fire [method on_button_deactivated] on each of its targets.
##
## This node is useful in cases when a mechanism should be triggered as long
## as any of its triggers are activated, or in cases in which all triggers must
## be activated for a trigger to occur.
class_name TriggerPredicate
extends Node

## The minimum number of times this [TriggerPredicate] need be triggered for
## its [param activation_targets] to be triggered.
@export_range(1,99) var min_triggers : int = 1

## The targets which this [TriggerPredicate] will attempt to trigger when it
## itself is triggerd [param min_triggers] times.
@export var activation_targets: Array[Node] = []

var _trigger_count = 0
## Triggered by triggers that have this node attached as a target.
func on_button_activated() -> void:
	_trigger_count += 1
	if _trigger_count == min_triggers:
		for target in activation_targets:
			if target and target.has_method("on_button_activated"):
				target.on_button_activated();

## Triggered by triggers that have this node attached as a target.
func on_button_deactivated() -> void:
	_trigger_count -= 1
	if _trigger_count == min_triggers - 1:
		for target in activation_targets:
			if target and target.has_method("on_button_deactivated"):
				target.on_button_deactivated();
