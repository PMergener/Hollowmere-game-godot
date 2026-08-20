class_name AreaDoor
extends Node2D

## A way between areas: the well down into the undercroft, the shaft back up. Walk
## to it, press E, and it asks the world to carry you to [member target] and set
## you down at [member spawn]. What the door looks like is drawn by whatever sits
## on top of it (a well, a shaft) - this is just the trigger and the destination.

@export var target: StringName = &"undercroft"
@export var spawn: Vector2 = Vector2.ZERO
@export var prompt: String = "Descend"
@export var interact_radius: float = 26.0
## Shown and refused when this is false - e.g. the well before you have a reason.
@export var locked: bool = false
@export var locked_line: String = "There is no way down without a rope."
## When set, the door refuses until this item is in the pack - the Sewer Key gate.
@export var require_item: StringName = &""


func _ready() -> void:
	add_to_group(&"interactable")


func interact_prompt() -> String:
	return prompt


func can_interact() -> bool:
	return true


func interact(_by: Node) -> void:
	if locked:
		EventBus.toast(locked_line)
		return
	if require_item != &"" and not Inventory.has_item(require_item):
		EventBus.toast(locked_line)
		return
	EventBus.travel_requested.emit(target, spawn)
