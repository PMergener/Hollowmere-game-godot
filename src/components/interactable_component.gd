class_name InteractableComponent
extends Area2D

## Marks something the player can walk up to and press interact on: a person, a
## chest, a note in the mud, a door.
##
## It only announces that it was used. What that means - a conversation, a lid
## opening, a staircase - belongs to whatever is listening, so the same
## component serves all of them.

signal interacted(by: Node)
## The player came into range, or left it. Used to show the prompt.
signal focus_changed(focused: bool)

## Shown above the thing. Keep it a verb: "Talk", "Open", "Read", "Climb down".
@export var prompt: String = "Use"
## Untick to turn it off without deleting it - a door that is not open yet, a
## person who has nothing left to say.
@export var enabled: bool = true
## Where the prompt floats, relative to this node.
@export var prompt_offset: Vector2 = Vector2(0, -34)
## Ticked, it can only ever be used once.
@export var single_use: bool = false

var _used := false
var _focused := false


func _ready() -> void:
	add_to_group(&"interactables")


func can_interact() -> bool:
	return enabled and not (single_use and _used)


func interact(by: Node) -> bool:
	if not can_interact():
		return false
	_used = true
	interacted.emit(by)
	return true


func set_focused(value: bool) -> void:
	if _focused == value:
		return
	_focused = value
	focus_changed.emit(value)


func is_focused() -> bool:
	return _focused


func prompt_position() -> Vector2:
	return global_position + prompt_offset
