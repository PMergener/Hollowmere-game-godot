extends Node2D

var player: Player

@onready var y_sort: Node2D = $World
@onready var cam: Camera2D = $World/Camera


func _ready() -> void:
	CollisionMap.set_solids(WorldData.build_solids(), WorldData.WORLD, 36.0)

	var ground := Node2D.new()
	ground.set_script(load("res://src/world/ground.gd"))
	ground.z_index = -100
	ground.y_sort_enabled = false
	y_sort.add_child(ground)
	y_sort.move_child(ground, 0)

	for i in WorldData.HOUSES.size():
		var h = WorldData.HOUSES[i]
		var n := _prop(1, Vector2(h[0], h[1] + h[3]))
		n.w = h[2]; n.h = h[3]
		n.lit = i in WorldData.HOUSE_LIT
		n.ruin = i in WorldData.HOUSE_RUIN

	for i in WorldData.TREES.size():
		var tr = WorldData.TREES[i]
		var n := _prop(2, Vector2(tr[0], tr[1]))
		n.bare = i in WorldData.TREE_BARE
		n.seed_val = i * 13 + 7

	var pyre := _prop(4, Vector2(WorldData.STONES[0][0], WorldData.STONES[0][1]))
	var pl2 := PointLight2D.new()
	pl2.name = "Light"
	pl2.texture = _light_texture(150)
	pl2.color = Color(1.00, 0.66, 0.34)
	pl2.energy = 1.0
	pl2.position = Vector2(0, -18)
	pyre.add_child(pl2)
	_prop(5, Vector2(WorldData.STONES[1][0], WorldData.STONES[1][1]))
	_prop(6, Vector2(WorldData.STONES[2][0], WorldData.STONES[2][1]))

	var bl := WorldData.braziers()
	for i in bl.size():
		var b = bl[i]
		var n := _prop(3, Vector2(b[0], b[1]))
		n.ph = i * 1.37
		var l := PointLight2D.new()
		l.name = "Light"
		l.texture = _light_texture(74)
		l.color = Color(1.00, 0.68, 0.38)
		l.energy = 0.62
		l.position = Vector2(0, -30)
		n.add_child(l)

	player = Player.new()
	player.position = WorldData.PLAYER_START
	var pl := PointLight2D.new()
	pl.name = "Light"
	player.tex_lamp = _light_texture(93)
	player.tex_torch = _light_texture(117)
	pl.texture = player.tex_lamp
	pl.color = Color(0.78, 0.98, 0.86)
	pl.energy = 1.05
	pl.position = Vector2(0, -14)
	pl.enabled = false
	player.add_child(pl)

	var melee := MeleeAttack.new()
	melee.name = "Melee"
	player.add_child(melee)

	y_sort.add_child(player)

	cam.reparent(player)
	cam.position = Vector2.ZERO

	var em := Node2D.new()
	em.set_script(load("res://src/world/embers.gd"))
	em.player = player
	em.z_index = 5
	em.y_sort_enabled = false
	y_sort.add_child(em)

	_populate_village()

	# The editable props layer: open scenes/areas/village_props.tscn to drag
	# trees, rocks, chests and crates around by hand. This is the map-editing
	# workflow - placed nodes, not coordinate tables.
	var props_path := "res://scenes/areas/village_props.tscn"
	if ResourceLoader.exists(props_path):
		y_sort.add_child((load(props_path) as PackedScene).instantiate())

	var interaction := Node.new()
	interaction.set_script(load("res://src/systems/interaction.gd"))
	add_child(interaction)

	var hud := get_node_or_null("HUD")
	if hud:
		hud.player = player

	# The rain is always falling on Hollowmere; a looping bed under everything.
	Sfx.play_ambience(&"rain", -9.0)


func _populate_village() -> void:
	var herbert := Herbert.new()
	herbert.position = Vector2(638, 488)
	herbert.facing = 0  # 0 = facing down, toward the square
	y_sort.add_child(herbert)

	for i in WorldData.VILLAGER_SPOTS.size():
		var v := Villager.new()
		v.position = WorldData.VILLAGER_SPOTS[i]
		v.palette_index = i
		v.line = WorldData.VILLAGER_LINES[i % WorldData.VILLAGER_LINES.size()]
		y_sort.add_child(v)

	for spot in WorldData.GHOST_SPOTS:
		var g := Ghost.new()
		g.position = spot
		y_sort.add_child(g)


func _prop(kind: int, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.set_script(load("res://src/world/prop.gd"))
	n.kind = kind - 1
	n.position = pos
	y_sort.add_child(n)
	return n


func _light_texture(radius: int) -> ImageTexture:
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(radius, radius)
	const CORE := 0.40
	const CORE_A := 0.88
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c) / float(radius)
			var a: float
			if d <= CORE:
				a = CORE_A - d * 0.14
			else:
				var k: float = clampf((1.0 - d) / (1.0 - CORE), 0.0, 1.0)
				a = (k * k * (3.0 - 2.0 * k)) * CORE_A * 0.94
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
