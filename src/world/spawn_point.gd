@tool
class_name SpawnPoint
extends Marker2D

## Where the player arrives. Place one wherever an area can be entered from.
##
## Doors refer to these by name, so moving where a staircase comes out is done
## by dragging this marker - never by editing a coordinate in code.

## Name doors use to ask for this spot. Every area should have one called
## "default" as a fallback.
@export var point_name: StringName = &"default"

## Which way the player is looking on arrival. Coming up a staircase facing the
## wall you just climbed out of reads as a bug even though nothing is broken.
@export var facing: Vector2 = Vector2.DOWN


func _ready() -> void:
	add_to_group(&"spawn_points")


func _get_configuration_warnings() -> PackedStringArray:
	if point_name == &"":
		return ["This spawn point has no name, so nothing can travel to it."]
	return []
