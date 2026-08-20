extends Node2D

## Boots the game and moves the player between areas. The player, camera, embers
## and the UI are persistent; each area's content is tagged "area_content" and
## torn down when you travel, so leaving for the undercroft and coming back is a
## rebuild of that layer, not of the whole world. This mirrors the HTML build's
## single-canvas AREA.name branching, done with nodes.

const UNDER_W := 1100.0
const UNDER_H := 420.0
const SEWER_W := 1400.0
const SEWER_H := 360.0
const SEWER_SKEL_HP := 30.0
const SHOP_W := 300.0
const SHOP_H := 172.0
const SHOP_DOOR := Vector2(812, 470)   # where you stand in the village, outside it

var player: Player
var current_area := &"village"

@onready var y_sort: Node2D = $World
@onready var cam: Camera2D = $World/Camera
@onready var darkness: CanvasModulate = $Darkness


func _ready() -> void:
	# persistent player
	player = Player.new()
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

	var interaction := Node.new()
	interaction.set_script(load("res://src/systems/interaction.gd"))
	add_child(interaction)

	var whispers := Node.new()
	whispers.set_script(load("res://src/systems/whispers.gd"))
	add_child(whispers)

	var hud := get_node_or_null("HUD")
	if hud:
		hud.player = player

	EventBus.travel_requested.connect(_enter_area)
	EventBus.enemy_died.connect(_on_enemy_died)
	_enter_area(&"village", WorldData.PLAYER_START)


## The Fallen Hunter falling is the turn of the whole story: Elphric's name is
## yours to carry now, so the Order's charge - report to Herbert - opens the moment
## he is down. Everything else about the report is Herbert's to answer.
func _on_enemy_died(enemy_id: StringName, _pos: Vector2) -> void:
	if enemy_id != &"fallen_hunter":
		return
	PlayerProgress.set_flag(&"hunter_slain")
	QuestLog.begin(QuestLog.by_id(&"elphric"))


## Tears down the current area and builds the target, setting its light, weather
## and bounds, then sets the player down at [param spawn].
func _enter_area(target: StringName, spawn: Vector2) -> void:
	for n in get_tree().get_nodes_in_group(&"area_content"):
		n.queue_free()
	current_area = target
	match target:
		&"undercroft":
			_build_undercroft()
		&"sewer":
			_build_sewer()
		&"sewer2":
			_build_sewer2()
		&"shop":
			_build_shop()
		_:
			_build_village()
	player.position = spawn
	player.dead = false
	EventBus.area_entered.emit(target)


# --- the village ------------------------------------------------------------

func _build_village() -> void:
	CollisionMap.set_solids(WorldData.build_solids(), WorldData.WORLD, 36.0)
	darkness.color = Color(0.1, 0.105, 0.13, 1)
	_set_weather(true)
	Sfx.play_ambience(&"rain", -20.0)

	var ground := _tag(Node2D.new())
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
		n.bare = i in WorldData.TREE_BARE or i in WorldData.TREE_OWL
		n.seed_val = i * 13 + 7
		# owls perch in three of the bare trees; they watch, blink, and hoot
		if i in WorldData.TREE_OWL:
			var owl := _tag(Owl.new())
			n.add_child(owl)
	var pyre := _prop(4, Vector2(WorldData.STONES[0][0], WorldData.STONES[0][1]))
	pyre.add_child(_point_light(150, Color(1.00, 0.66, 0.34), 1.0, Vector2(0, -18)))
	_prop(5, Vector2(WorldData.STONES[1][0], WorldData.STONES[1][1]))
	_prop(6, Vector2(WorldData.STONES[2][0], WorldData.STONES[2][1]))
	var bl := WorldData.braziers()
	for i in bl.size():
		var b = bl[i]
		var n := _prop(3, Vector2(b[0], b[1]))
		n.ph = i * 1.37
		n.add_child(_point_light(96, Color(1.00, 0.70, 0.40), 1.35, Vector2(0, -30)))

	var herbert := _tag(Herbert.new()); herbert.position = Vector2(638, 488); y_sort.add_child(herbert)
	# Ondrick keeps his shop now, not a patch of mud: a door into it, and him inside
	var shop := _tag(AreaDoor.new())
	shop.target = &"shop"
	shop.spawn = Vector2(SHOP_W / 2.0, SHOP_H - 18.0)
	shop.prompt = "Enter Ondrick's shop"
	shop.position = SHOP_DOOR
	y_sort.add_child(shop)
	for i in WorldData.VILLAGER_SPOTS.size():
		var v := _tag(Villager.new())
		v.position = WorldData.VILLAGER_SPOTS[i]
		v.palette_index = i
		v.line = WorldData.VILLAGER_LINES[i % WorldData.VILLAGER_LINES.size()]
		y_sort.add_child(v)
	for spot in WorldData.GHOST_SPOTS:
		var g := _tag(Ghost.new()); g.position = spot; y_sort.add_child(g)
	for note_def in NotesLog.in_area(&"village"):
		var note := _tag(Note.new()); note.note_id = note_def.id; note.position = note_def.pos; y_sort.add_child(note)

	# the north gate - barred until Herbert has it opened, then the way out
	var gate := _tag(NorthGate.new())
	gate.position = Vector2(WorldData.WORLD / 2.0, WorldData.WALL_IN + 22.0)
	y_sort.add_child(gate)

	# the hanged man at the crooked tree, southwest - his rope is the well's key
	var hanged := _tag(HangedMan.new())
	hanged.position = Vector2(298, 853)
	y_sort.add_child(hanged)

	# the well, down into the undercroft - needs the rope to lower yourself in
	var well := _tag(AreaDoor.new())
	well.target = &"undercroft"
	well.spawn = Vector2(120, UNDER_H / 2.0)
	well.prompt = "Descend the well"
	well.require_item = &"rope"
	well.locked_line = "I cannot go down without a rope. Southwest, past the crooked tree."
	well.position = Vector2(WorldData.STONES[1][0], WorldData.STONES[1][1])
	y_sort.add_child(well)

	var props_path := "res://scenes/areas/village_props.tscn"
	if ResourceLoader.exists(props_path):
		y_sort.add_child(_tag((load(props_path) as PackedScene).instantiate()))


# --- the undercroft ---------------------------------------------------------

func _build_undercroft() -> void:
	CollisionMap.set_bounds(UNDER_W, UNDER_H, 30.0)
	# a shade above pitch, so the clutter reads as a crypt full of things and not a
	# void - the lamp and torches still do the real seeing
	darkness.color = Color(0.10, 0.093, 0.10, 1)
	_set_weather(false)
	Sfx.play_ambience(&"hum", -20.0)

	var ground := _tag(Node2D.new())
	ground.set_script(load("res://src/world/undercroft_ground.gd"))
	ground.z_index = -100
	ground.y_sort_enabled = false
	y_sort.add_child(ground)
	y_sort.move_child(ground, 0)

	# the clutter that gives the crypt its feel: crates, barrels, bones, skulls,
	# webs, hanging chains, and water dripping from the ceiling
	var decor := _tag(Node2D.new())
	decor.set_script(load("res://src/world/undercroft_decor.gd"))
	decor.z_index = -50
	decor.y_sort_enabled = false
	y_sort.add_child(decor)

	# wall torches - a warmer, wider pool than before so each throws real light on
	# the clutter around it (the crypt was too dark to have any feel)
	for tp in [Vector2(180, 60), Vector2(460, 60), Vector2(740, 60), Vector2(1000, 60),
			Vector2(320, UNDER_H - 60), Vector2(620, UNDER_H - 60), Vector2(920, UNDER_H - 60)]:
		var torch := _tag(Node2D.new())
		torch.position = tp
		torch.add_child(_point_light(88, Color(0.62, 0.70, 0.92), 0.9, Vector2.ZERO))
		y_sort.add_child(torch)

	# five skeletons and two zombies, the undercroft's seven (its clear-it vow
	# counts both through the shared "undercroft_kill" event)
	var skel_spots := [Vector2(300, 140), Vector2(700, 150), Vector2(880, 280), Vector2(420, 320), Vector2(980, 160)]
	for s in skel_spots:
		var k := _tag(Skeleton.new()); k.position = s; k.death_event_extra = &"undercroft_kill"; y_sort.add_child(k)
	for s in [Vector2(520, 260), Vector2(760, 330)]:
		var z := _tag(Zombie.new()); z.position = s; z.death_event_extra = &"undercroft_kill"; y_sort.add_child(z)

	# the reward chest at the far end: coin, the Long sword, and the Sigil
	var chest_scene := load("res://scenes/props/chests/chest_2.tscn") as PackedScene
	var chest: Chest = null
	if chest_scene != null:
		chest = chest_scene.instantiate() as Chest
	if chest != null:
		_tag(chest)
		chest.position = Vector2(UNDER_W - 150, 110)
		chest.coins = 100
		var loot: Array[ItemData] = []
		var sword := ItemDb.get_item(&"sword_long")
		var sigil := ItemDb.get_item(&"sigil")
		if sword != null:
			loot.append(sword)
		if sigil != null:
			loot.append(sigil)
		chest.contents = loot
		y_sort.add_child(chest)

	# the shaft back up
	var shaft := _tag(AreaDoor.new())
	shaft.target = &"village"
	shaft.spawn = Vector2(WorldData.STONES[1][0], WorldData.STONES[1][1] + 26)
	shaft.prompt = "Climb back up"
	shaft.position = Vector2(120, UNDER_H / 2.0)
	y_sort.add_child(shaft)

	# the old grate at the far end, down into the Drowned Run. Locked until Herbert's
	# brother's Sewer Key is in the pack.
	var grate := _tag(AreaDoor.new())
	grate.target = &"sewer"
	grate.spawn = Vector2(130, SEWER_H / 2.0)
	grate.prompt = "The old grate"
	grate.require_item = &"key"
	grate.locked_line = "The grate is chained shut. It will take a key."
	grate.position = Vector2(UNDER_W - 80, UNDER_H / 2.0)
	y_sort.add_child(grate)


## The Drowned Run: a long, dark, near-lightless channel one level under the
## undercroft, the seven at 30 HP (the player may arrive armoured), and at the far
## end Brother Aldric beside his guttering lantern, with the grate down to the hall
## where the Hunter waits. (The HTML's zig-zag of 64px corridors is a single wide
## room here - the corridor collision is the one thing not reproduced; flagged.)
func _build_sewer() -> void:
	CollisionMap.set_bounds(SEWER_W, SEWER_H, 30.0)
	darkness.color = Color(0.03, 0.035, 0.045, 1)
	_set_weather(false)
	Sfx.play_ambience(&"hum", -20.0)

	var ground := _tag(Node2D.new())
	ground.set_script(load("res://src/world/undercroft_ground.gd"))
	ground.set(&"area_w", SEWER_W)
	ground.set(&"area_h", SEWER_H)
	ground.z_index = -100
	ground.y_sort_enabled = false
	y_sort.add_child(ground)
	y_sort.move_child(ground, 0)

	# sparse light - two at the mouth, one guttering beside Aldric (drawn by his body)
	for tp in [Vector2(150, 70), Vector2(420, SEWER_H - 70)]:
		var torch := _tag(Node2D.new())
		torch.position = tp
		torch.add_child(_point_light(50, Color(0.42, 0.66, 0.95), 0.5, Vector2.ZERO))
		y_sort.add_child(torch)

	# the seven, at 30 HP - set after add_child so Skeleton._ready cannot clobber it
	var spots := [Vector2(360, 120), Vector2(520, 220), Vector2(660, 150), Vector2(800, 250),
			Vector2(940, 130), Vector2(1080, 230), Vector2(1180, 160)]
	for s in spots:
		var k := _tag(Skeleton.new())
		k.position = s
		y_sort.add_child(k)
		k.max_hp = SEWER_SKEL_HP
		k.hp = SEWER_SKEL_HP

	for note_def in NotesLog.in_area(&"sewer"):
		var note := _tag(Note.new()); note.note_id = note_def.id; note.position = note_def.pos; y_sort.add_child(note)

	# Brother Aldric and his letter, at the far end. His guttering lantern casts a
	# real warm pool so the body reads when you finally reach it (the HTML's intent).
	var aldric := _tag(AldricBody.new())
	aldric.position = Vector2(SEWER_W - 110, SEWER_H / 2.0 + 20.0)
	y_sort.add_child(aldric)
	aldric.add_child(_point_light(64, Color(1.00, 0.60, 0.28), 0.9, Vector2(13, -12)))

	# the grate down to the Fallen Hunter's hall
	var grate := _tag(AreaDoor.new())
	grate.target = &"sewer2"
	grate.spawn = Vector2(90, 180)
	grate.prompt = "Down through the grate"
	grate.position = Vector2(SEWER_W - 250, 70)
	y_sort.add_child(grate)

	# back up to the undercroft
	var up := _tag(AreaDoor.new())
	up.target = &"undercroft"
	up.spawn = Vector2(UNDER_W - 140, UNDER_H / 2.0)
	up.prompt = "Back up the grate"
	up.position = Vector2(120, SEWER_H / 2.0)
	y_sort.add_child(up)


func _build_sewer2() -> void:
	CollisionMap.set_bounds(720.0, 360.0, 30.0)
	darkness.color = Color(0.045, 0.045, 0.055, 1)
	_set_weather(false)
	Sfx.play_ambience(&"hum", -20.0)

	var ground := _tag(Node2D.new())
	ground.set_script(load("res://src/world/undercroft_ground.gd"))
	ground.set(&"area_w", 720.0)
	ground.set(&"area_h", 360.0)
	ground.z_index = -100
	ground.y_sort_enabled = false
	y_sort.add_child(ground)
	y_sort.move_child(ground, 0)

	for tp in [Vector2(200, 55), Vector2(520, 55), Vector2(360, 305)]:
		var torch := _tag(Node2D.new())
		torch.position = tp
		torch.add_child(_point_light(48, Color(0.42, 0.66, 0.95), 0.5, Vector2.ZERO))
		y_sort.add_child(torch)

	for note_def in NotesLog.in_area(&"sewer2"):
		var note := _tag(Note.new()); note.note_id = note_def.id; note.position = note_def.pos; y_sort.add_child(note)

	var hunter := _tag(FallenHunter.new())
	hunter.position = Vector2(520, 180)
	y_sort.add_child(hunter)

	var back := _tag(AreaDoor.new())
	back.target = &"sewer"
	back.spawn = Vector2(SEWER_W - 250, 110)
	back.prompt = "Retreat"
	back.position = Vector2(60, 180)
	y_sort.add_child(back)


# --- Ondrick's shop, inside -------------------------------------------------

func _build_shop() -> void:
	CollisionMap.set_bounds(SHOP_W, SHOP_H, 8.0)
	# the room obeys the dark; the hanging lantern is the only light
	darkness.color = Color(0.22, 0.18, 0.14, 1)
	_set_weather(false)
	Sfx.stop_ambience()

	var room := _tag(Node2D.new())
	room.set_script(load("res://src/world/shop_interior.gd"))
	room.z_index = -100
	room.y_sort_enabled = false
	y_sort.add_child(room)
	y_sort.move_child(room, 0)

	# the hanging lantern throws the room's only pool of light, from the centre
	var lantern := _tag(Node2D.new())
	lantern.position = Vector2(SHOP_W / 2.0, 30.0)
	lantern.add_child(_point_light(180, Color(1.0, 0.74, 0.42), 1.3, Vector2.ZERO))
	y_sort.add_child(lantern)

	# Ondrick, behind his counter (which sits at y 82)
	var ondrick := _tag(Ondrick.new())
	ondrick.position = Vector2(150, 64)
	y_sort.add_child(ondrick)

	# the way back out, at the doorway at the foot of the room
	var leave := _tag(AreaDoor.new())
	leave.target = &"village"
	leave.spawn = SHOP_DOOR + Vector2(0, 20)
	leave.prompt = "Step outside"
	leave.position = Vector2(150, SHOP_H - 6.0)
	y_sort.add_child(leave)


# --- helpers ----------------------------------------------------------------

func _tag(n: Node) -> Node:
	n.add_to_group(&"area_content")
	return n


func _prop(kind: int, pos: Vector2) -> Node2D:
	var n := _tag(Node2D.new()) as Node2D
	n.set_script(load("res://src/world/prop.gd"))
	n.kind = kind - 1
	n.position = pos
	y_sort.add_child(n)
	return n


func _point_light(radius: int, color: Color, energy: float, pos: Vector2) -> PointLight2D:
	var l := PointLight2D.new()
	l.name = "Light"
	l.texture = _light_texture(radius)
	l.color = color
	l.energy = energy
	l.position = pos
	return l


func _set_weather(on: bool) -> void:
	# The layer stays up everywhere - only the rain itself is village-only. The
	# vignette and grain it also carries must keep drawing underground.
	var w := get_node_or_null("Weather")
	if w:
		w.raining = on


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
