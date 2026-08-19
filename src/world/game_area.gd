class_name GameArea
extends Node2D

## The root of every place in the game: the village, a house, a level of the
## sewers, the road north.
##
## An area is an ordinary scene. Everything in it - houses, trees, enemies,
## doors, triggers - is placed by hand in the editor, which is the point: the
## original held all of it in coordinate tables that nobody could look at and
## understand. Here, where a thing is IS where you dragged it.
##
## To make a new area: new scene, root node GameArea, give it an AreaData, add a
## SpawnPoint, and it can be travelled to.

## Light, weather and sound for this place.
@export var area_data: AreaData

@export_group("Bounds")
## The camera will not show past this. Leave at zero to let it roam free.
@export var camera_limits: Rect2 = Rect2()

var _spawn_points: Dictionary = {}


func _ready() -> void:
	_collect_spawn_points()
	if area_data == null:
		push_warning("Area '%s' has no AreaData, so it will use whatever light the last area left." % name)


func _collect_spawn_points() -> void:
	_spawn_points.clear()
	for node in find_children("*", "SpawnPoint", true, false):
		var point := node as SpawnPoint
		if _spawn_points.has(point.point_name):
			push_warning("Area '%s' has two spawn points called '%s'." % [name, point.point_name])
		_spawn_points[point.point_name] = point


func area_id() -> StringName:
	if area_data != null and area_data.id != &"":
		return area_data.id
	return StringName(name)


## Returns null when there is no such spawn point.
func spawn_point(point_name: StringName) -> SpawnPoint:
	if _spawn_points.has(point_name):
		return _spawn_points[point_name]
	if _spawn_points.has(&"default"):
		return _spawn_points[&"default"]
	return null


func has_camera_limits() -> bool:
	return camera_limits.size.x > 0.0 and camera_limits.size.y > 0.0
