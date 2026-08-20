@tool
extends VBoxContainer

## The entity palette. Lists every enemy and NPC scene with a thumbnail; drag one
## into the 2D viewport to place it in the map you are editing.
##
## Placement reuses Godot's own scene-drop: the item hands the editor a "files"
## drag payload pointing at the .tscn, exactly as dragging from the FileSystem
## dock would, so instancing and undo are the engine's, not ours.

## Where to look for placeable entities. Add a folder and its scenes appear here.
const ENTITY_DIRS := ["res://scenes/enemies", "res://scenes/npcs"]

var _list: VBoxContainer


func _init() -> void:
	name = "Entities"
	_build()
	_refresh()


func _build() -> void:
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "Entities"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var refresh := Button.new()
	refresh.text = "Refresh"
	refresh.tooltip_text = "Rescan the entity folders"
	refresh.pressed.connect(_refresh)
	header.add_child(refresh)
	add_child(header)

	var hint := Label.new()
	hint.text = "Drag an entity into the map."
	hint.add_theme_color_override(&"font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override(&"font_size", 11)
	add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var found := 0
	for dir_path in ENTITY_DIRS:
		found += _scan(dir_path)
	if found == 0:
		var empty := Label.new()
		empty.text = "No entity scenes yet.\nAdd .tscn files under scenes/enemies\nor scenes/npcs."
		empty.add_theme_color_override(&"font_color", Color(0.55, 0.5, 0.4))
		_list.add_child(empty)


func _scan(dir_path: String) -> int:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	var count := 0
	for file in dir.get_files():
		if not file.ends_with(".tscn"):
			continue
		_add_item(dir_path.path_join(file))
		count += 1
	return count


func _add_item(scene_path: String) -> void:
	var item := Button.new()
	item.text = "  " + _pretty(scene_path)
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.tooltip_text = "Drag into the map to place it"
	item.custom_minimum_size = Vector2(0, 36)
	item.expand_icon = true
	item.set_meta(&"scene_path", scene_path)
	# Present a native file-drag so the 2D viewport instances the scene itself.
	item.set_drag_forwarding(
		func(_pos: Vector2) -> Variant:
			var preview := Label.new()
			preview.text = _pretty(scene_path)
			item.set_drag_preview(preview)
			return {"type": "files", "files": [scene_path], "from": "rpg_entity_palette"},
		Callable(), Callable())
	_list.add_child(item)
	_request_thumbnail(scene_path, item)


func _request_thumbnail(scene_path: String, item: Button) -> void:
	var previewer := EditorInterface.get_resource_previewer()
	if previewer != null:
		previewer.queue_resource_preview(scene_path, self, "_on_thumbnail", item)


func _on_thumbnail(_path: String, preview: Texture2D, _thumb: Texture2D, item: Button) -> void:
	if is_instance_valid(item) and preview != null:
		item.icon = preview


func _pretty(scene_path: String) -> String:
	var base := scene_path.get_file().get_basename()
	return base.replace("_", " ").capitalize()
