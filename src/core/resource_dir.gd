class_name ResourceDir
extends RefCounted

## Loads every resource in a folder.
##
## This is what lets a designer add content by dropping a file in. Put a new
## quest in res://data/quests/ and it is in the game the next time it runs; no
## list to register it in, nothing to remember to update.
##
## Exported builds rename resources to .remap, so both are handled here. Getting
## this wrong is the classic bug where a game works in the editor and ships with
## no content.


## Every resource directly inside [param folder], sorted by filename so load
## order is stable.
static func load_all(folder: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open(folder)
	if dir == null:
		push_warning("ResourceDir: cannot open %s" % folder)
		return out

	var names: PackedStringArray = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	names.sort()
	for name in names:
		var path := _resource_path(folder, name)
		if path.is_empty():
			continue
		var res := ResourceLoader.load(path)
		if res != null:
			out.append(res)
	return out


## Same, but keyed by an "id" property, which every content resource has.
static func load_by_id(folder: String) -> Dictionary:
	var map: Dictionary = {}
	for res in load_all(folder):
		if not (&"id" in res):
			push_warning("ResourceDir: %s has no id property." % res.resource_path)
			continue
		var id: StringName = res.get(&"id")
		if id == &"":
			push_warning("ResourceDir: %s has a blank id." % res.resource_path)
			continue
		if map.has(id):
			push_warning("ResourceDir: duplicate id '%s' in %s" % [id, folder])
		map[id] = res
	return map


static func _resource_path(folder: String, file_name: String) -> String:
	var name := file_name
	if name.ends_with(".remap"):
		name = name.trim_suffix(".remap")
	elif name.ends_with(".import"):
		name = name.trim_suffix(".import")
	if not (name.ends_with(".tres") or name.ends_with(".res")):
		return ""
	return folder.path_join(name)
