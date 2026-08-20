extends SceneTree

## Builds the Hollowmere TileSet from the 16px atlases and a starter demo map,
## letting the engine encode the tile data (never hand-written). Run once:
##   godot --headless --path . --script tools/build_tiles.gd
## Re-runnable; overwrites its two outputs.

const GROUND := "res://assets/tilesets/ground_grass.png"
const ROAD := "res://assets/tilesets/road_ground.png"
const ROAD_GRASS := "res://assets/tilesets/road_grass.png"
const TILE := 16

# Fill tiles picked by scanning for fully-opaque cells (see build notes).
const DIRT := Vector2i(10, 2)   # brown dirt fill
const GRASS := Vector2i(3, 8)   # green grass fill
const ROAD_C := Vector2i(2, 2)  # cobble road centre


func _initialize() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var ground_id := _add_atlas(ts, GROUND)
	var road_id := _add_atlas(ts, ROAD)
	_add_atlas(ts, ROAD_GRASS)
	ResourceSaver.save(ts, "res://assets/tilesets/hollowmere.tres")
	print("TileSet saved: ground_id=%d road_id=%d" % [ground_id, road_id])

	_build_demo(ts, ground_id, road_id)
	print("done")
	quit()


## Adds every 16px cell of a texture as a paintable tile. Returns the source id.
func _add_atlas(ts: TileSet, path: String) -> int:
	var tex: Texture2D = load(path)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	var cols := tex.get_width() / TILE
	var rows := tex.get_height() / TILE
	for y in rows:
		for x in cols:
			src.create_tile(Vector2i(x, y))
	return ts.add_source(src)


func _build_demo(ts: TileSet, ground_id: int, road_id: int) -> void:
	var root := Node2D.new()
	root.name = "DemoMap"
	root.y_sort_enabled = true

	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.tile_set = ts

	var w := 44
	var h := 28
	for y in h:
		for x in w:
			var edge := x < 2 or y < 2 or x >= w - 2 or y >= h - 2
			layer.set_cell(Vector2i(x, y), ground_id, GRASS if edge else DIRT)
	# a dirt-road cross through the village, two tiles wide
	var cx := w / 2
	var cy := h / 2
	for x in range(2, w - 2):
		layer.set_cell(Vector2i(x, cy), road_id, ROAD_C)
		layer.set_cell(Vector2i(x, cy + 1), road_id, ROAD_C)
	for y in range(2, h - 2):
		layer.set_cell(Vector2i(cx, y), road_id, ROAD_C)
		layer.set_cell(Vector2i(cx + 1, y), road_id, ROAD_C)
	root.add_child(layer)
	layer.owner = root

	var spawn := Marker2D.new()
	spawn.name = "Spawn"
	spawn.set_script(load("res://src/world/spawn_point.gd"))
	spawn.position = Vector2((cx + 1) * TILE, (cy + 4) * TILE)
	root.add_child(spawn)
	spawn.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/areas/demo_map.tscn")
	print("demo_map.tscn saved (%dx%d tiles)" % [w, h])
