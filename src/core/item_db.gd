extends Node

## Every item the game knows, loaded from res://data/items and res://data/weapons
## and keyed by id. This is what lets a wraith "drop a tear" or a chest "yield a
## key" by NAME - the runtime never hard-codes an item, it asks here for the id a
## designer wrote on a .tres. Add an item file to the folder and it is available;
## no code changes.

var _by_id: Dictionary = {}


func _ready() -> void:
	_load_folder("res://data/items")
	_load_folder("res://data/weapons")


func _load_folder(folder: String) -> void:
	var found := ResourceDir.load_by_id(folder)
	for id in found:
		_by_id[id] = found[id]


## The ItemData for an id, or null if nothing carries that id.
func get_item(id: StringName) -> ItemData:
	return _by_id.get(id)


func has(id: StringName) -> bool:
	return _by_id.has(id)
