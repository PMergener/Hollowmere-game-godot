extends CanvasLayer

## The inventory screen, opened with I: the character sheet on the left, the
## backpack on the right, both visible at once - the HTML build's layout, where
## you can see what you are equipping and what you are equipping it from without
## one panel hiding the other.
##
## Left: name, HP and lamp bars, level + XP, the weapon and armour slots (click to
## unequip), and the DMG / GOLD / SOULS / EMBERS footer. Right: the 50-slot pack,
## belt across the top row; click an item to use or equip it.

const COLS := 9
const ROWS := 6
const SLOT := 24
const PITCH := 27

# left sheet / right pack panels, at the HTML's exact IP*/PP* coordinates
const SHEET := Rect2(22, 16, 260, 316)     # IPX, IPY, IPW, IPH
const PACK := Rect2(292, 16, 268, 316)     # PPX, PPY, PPW, PPH
const EQ_SZ := 36.0
const EQ_SZ_R := 26.0
# the fixed garments shown in the WORN column, display-only ("worn, cannot be changed")
const WORN := ["head", "torso", "legs", "boots", "pack"]

var open := false
var t := 0.0
var _player: Node2D
var _hover := -1
var _hover_equip := ""

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	painter.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"open_pack"):
		_toggle()
	if not open:
		return
	t += delta
	if Input.is_action_just_pressed(&"pause"):
		_toggle()
	var m := get_viewport().get_mouse_position()
	_hover = _slot_at(m)
	_hover_equip = _equip_at(m)
	painter.queue_redraw()


func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node2D


func _unhandled_input(e: InputEvent) -> void:
	if not open:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := _slot_at(e.position)
		if i >= 0 and _player != null:
			_player.use_item_slot(i)
		elif _equip_at(e.position) == "weapon":
			Inventory.unequip_weapon()
		get_viewport().set_input_as_handled()


# --- geometry ---------------------------------------------------------------

func _grid_origin() -> Vector2:
	return Vector2(PACK.position.x + (PACK.size.x - COLS * PITCH) / 2.0, PACK.position.y + 30.0)


func _slot_rect(i: int) -> Rect2:
	var o := _grid_origin()
	return Rect2(o.x + (i % COLS) * PITCH, o.y + (i / COLS) * PITCH, SLOT, SLOT)


func _slot_at(m: Vector2) -> int:
	for i in range(COLS * ROWS):
		if i < Inventory.PACK_SIZE and _slot_rect(i).has_point(m):
			return i
	return -1


# eqRect(col, row) from the HTML: col 0 is the two changeable slots (36px) on the
# left; col 1 is the WORN garments (26px) down the right of the sheet.
func _eq_rect(col: int, row: int) -> Rect2:
	if col == 0:
		return Rect2(SHEET.position.x + 14, SHEET.position.y + 96 + row * 46, EQ_SZ, EQ_SZ)
	return Rect2(SHEET.position.x + SHEET.size.x - 14 - EQ_SZ_R, SHEET.position.y + 96 + row * 30, EQ_SZ_R, EQ_SZ_R)


func _weapon_rect() -> Rect2:
	return _eq_rect(0, 0)


func _armour_rect() -> Rect2:
	return _eq_rect(0, 1)


func _equip_at(m: Vector2) -> String:
	if _weapon_rect().has_point(m):
		return "weapon"
	if _armour_rect().has_point(m):
		return "armour"
	return ""


# --- drawing ----------------------------------------------------------------

func paint(ci: CanvasItem) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
	ci.draw_rect(Rect2(0, 0, 576, 360), Color(0.02, 0.02, 0.03, 0.76), true)
	_panel(ci, SHEET)
	_panel(ci, PACK)
	_sheet(ci)
	_pack(ci)


func _sheet(ci: CanvasItem) -> void:
	var cx := SHEET.position.x + SHEET.size.x / 2.0
	PixelText.draw(ci, "NESTOR", cx - PixelText.width("NESTOR") / 2.0, SHEET.position.y + 10, Color("e5cd8c"))

	var hp := 1.0
	var lamp := 1.0
	if _player != null:
		hp = clampf(_player.hp / _player.hp_max, 0.0, 1.0)
		lamp = clampf(_player.lamp / _player.lamp_max, 0.0, 1.0)
	_bar(ci, SHEET.position.x + 16, SHEET.position.y + 30, 84, hp, Color("e8695a"), Color("8c231b"),
		"%d/%d" % [_player.hp if _player else 0, _player.hp_max if _player else 0])
	_bar(ci, SHEET.position.x + SHEET.size.x - 100, SHEET.position.y + 30, 84, lamp, Color("6fe8a0"), Color("1c7a46"),
		"%d/%d" % [_player.lamp if _player else 0, _player.lamp_max if _player else 0])

	var lv := "LEVEL %d" % PlayerProgress.level
	PixelText.draw(ci, lv, cx - PixelText.width(lv) / 2.0, SHEET.position.y + 52, Color("d9bd70"))
	# xp bar
	var xw := 120.0
	var xx := cx - xw / 2.0
	var xf := PlayerProgress.xp_fraction()
	ci.draw_rect(Rect2(xx, SHEET.position.y + 66, xw, 6), Color("161208"), true)
	ci.draw_rect(Rect2(xx, SHEET.position.y + 66, roundf(xw * xf), 6), Color("8a6f34"), true)
	var xt := "%d/%d XP" % [PlayerProgress.xp, PlayerProgress.xp_to_next]
	PixelText.draw(ci, xt, cx - PixelText.width(xt) / 2.0, SHEET.position.y + 78, Color("9a8a64"))

	# ARMOUR badge, centred above the character between the two equipment columns
	var badge := "ARMOR  %d" % Inventory.armor_total()
	PixelText.draw(ci, badge, cx - PixelText.width(badge) / 2.0, SHEET.position.y + 116, Color("b9bfc6"))

	# the character portrait, breathing
	_portrait(ci, cx, SHEET.position.y + 232.0)

	# the two changeable slots on the left: WEAPON and BODY (armour)
	_equip_slot(ci, _weapon_rect(), "WEAPON", _weapon_id(), _hover_equip == "weapon")
	_equip_slot(ci, _armour_rect(), "BODY", _armour_id(), _hover_equip == "armour")

	# the WORN garments down the right - fixed, sunk, never brighten
	var wr0 := _eq_rect(1, 0)
	PixelText.draw(ci, "WORN", wr0.position.x - 8, wr0.position.y - 11, Color("5f5742"))
	for r in WORN.size():
		_worn_slot(ci, _eq_rect(1, r), WORN[r])

	# footer stats (ARMOUR is the badge now, not a footer line)
	var fy := SHEET.position.y + SHEET.size.y - 46
	PixelText.draw(ci, "DMG %d" % _damage(), SHEET.position.x + 18, fy, Color("c2a86e"))
	var gold := "GOLD %d" % PlayerProgress.gold
	PixelText.draw(ci, gold, SHEET.position.x + SHEET.size.x - 18 - PixelText.width(gold), fy, Color("d6b45e"))
	PixelText.draw(ci, "SOULS %d" % Inventory.count_of(&"soul"), SHEET.position.x + 18, fy + 13, Color("8ad4a6"))
	var emb := "EMBERS %d" % PlayerProgress.embers
	PixelText.draw(ci, emb, SHEET.position.x + SHEET.size.x - 18 - PixelText.width(emb), fy + 13, Color("c98a5a"))


# A worn garment slot: sunk and dark, never lit (it cannot be changed), with a
# small glyph of the piece so the column reads as head/torso/legs/boots/pack.
func _worn_slot(ci: CanvasItem, r: Rect2, kind: String) -> void:
	ci.draw_rect(Rect2(r.position.x - 2, r.position.y - 2, r.size.x + 4, r.size.y + 4), Color("0b0906"), true)
	ci.draw_rect(r, Color("0b0906"), true)
	_frame(ci, r, Color("241f16"))
	var gx := r.position.x + r.size.x / 2.0
	var gy := r.position.y + r.size.y / 2.0
	var g := func(x, y, w, h, c): ci.draw_rect(Rect2(roundf(gx + x), roundf(gy + y), w, h), c, true)
	var c := Color("6a6252")
	match kind:
		"head":
			g.call(-5, -5, 10, 7, c); g.call(-5, -6, 10, 1, Color("7c7460")); g.call(-3, -2, 6, 3, Color("2a2620"))
		"torso":
			g.call(-5, -5, 10, 10, c); g.call(-5, -5, 3, 10, Color("7c7460")); g.call(-1, -5, 2, 10, Color("3a352c"))
		"legs":
			g.call(-4, -5, 3, 10, c); g.call(1, -5, 3, 10, c); g.call(-4, -5, 8, 2, Color("7c7460"))
		"boots":
			g.call(-5, 0, 4, 4, c); g.call(1, 0, 4, 4, c); g.call(-5, 3, 5, 1, Color("2a2620")); g.call(1, 3, 5, 1, Color("2a2620"))
		_:
			g.call(-5, -5, 10, 10, Color("5c4a2c")); g.call(-5, -5, 10, 2, Color("6e5a38")); g.call(-2, -5, 4, 3, Color("3a2e1a"))


# Nestor himself, ported from the HTML's drawPortraitFigure at scale 3: the hooded
# cloak, a shadowed face with pulsing red eyes, the sword held at his side, and a
# slow breathe-and-sway so the panel is not a still life.
func _portrait(ci: CanvasItem, cx: float, cy: float) -> void:
	# the ground shadow, a squashed ellipse
	ci.draw_set_transform(Vector2(cx, cy + 9.0), 0.0, Vector2(1.0, 0.26))
	ci.draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.45))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var s := 3.0
	var breathe := sin(t * 1.15)
	var bob := 1.0 if breathe > 0.35 else 0.0
	var sway := sin(t * 0.62)
	var P := Figure.PAL_PLAYER
	var R := func(x, y, w, h, c): ci.draw_rect(
		Rect2(roundf(cx + x * s + sway), roundf(cy + y * s - bob * s * 0.34), w * s, h * s), c, true)

	R.call(-5, -6, 3, 6, P.lo); R.call(2, -6, 3, 6, P.lo)               # legs
	R.call(-5, -2, 5, 2, Color("0b0a08")); R.call(2, -2, 5, 2, Color("0b0a08"))
	R.call(-6, -18, 12, 12, P.cloak)                                    # cloak
	R.call(-6, -18, 3, 12, P.hi); R.call(3, -18, 3, 12, P.fold)
	R.call(-1, -17, 1, 10, P.fold)
	R.call(-7, -9, 14, 3, P.lo)
	R.call(-6, -11, 12, 2, P.trim); R.call(-1, -11, 3, 2, Color("6b5a3e"))
	R.call(-7, -20, 14, 3, P.hi); R.call(-7, -20, 14, 1, P.fold)
	R.call(-9, -17, 3, 8, P.hi); R.call(-9, -11, 3, 3, Color("0e0d0b")) # arms
	R.call(6, -17, 3, 8, P.hi); R.call(6, -11, 3, 3, Color("0e0d0b"))
	R.call(-6, -27, 12, 10, P.cloak); R.call(-5, -29, 10, 2, P.cloak)   # hood
	R.call(-6, -27, 3, 10, P.hi); R.call(-6, -28, 12, 1, P.fold)
	R.call(-4, -24, 8, 6, P.skin); R.call(-4, -24, 8, 1, Color("000000"))  # face
	var ep := 0.7 + 0.3 * sin(t * 2.1)                                  # pulsing eyes
	var ec := Color(200.0 * ep / 255.0, 44.0 * ep / 255.0, 32.0 * ep / 255.0)
	R.call(-3, -23, 2, 2, ec); R.call(1, -23, 2, 2, ec)
	R.call(-11, -13, 2, 1, Color("9a8760"))                            # sword at his side
	R.call(-11, -12, 1, 8, Color("eef3f7")); R.call(-10, -12, 1, 8, Color("b6c0c9"))
	R.call(-11, -4, 1, 1, Color("ffffff"))


func _equip_slot(ci: CanvasItem, r: Rect2, name: String, id: String, hov: bool) -> void:
	PixelText.draw(ci, name, r.position.x, r.position.y - 10, Color("8a7343"))
	ci.draw_rect(r, Color("2a2214") if hov else Color("100d08"), true)
	_frame(ci, r, Color("b59446") if hov else Color("4a3f26"))
	if id != "":
		if ItemIcons.has_live_icon(id):
			ItemIcons.draw_live_icon(ci, id, r.position.x + r.size.x / 2.0, r.position.y + r.size.y / 2.0, false, t)
		else:
			ItemIcons.draw_icon(ci, id, r.position.x + r.size.x / 2.0, r.position.y + r.size.y / 2.0, 0.9)


func _pack(ci: CanvasItem) -> void:
	PixelText.draw(ci, "BACKPACK", PACK.position.x + 14, PACK.position.y + 12, Color("e5cd8c"))
	for i in range(COLS * ROWS):
		if i >= Inventory.PACK_SIZE:
			continue
		_slot(ci, i)
	# SECONDARY weapon slot (the bow, drawn with TAB) below the grid
	var sr := Rect2(PACK.position.x + 14, PACK.position.y + PACK.size.y - 62, 34, 34)
	PixelText.draw(ci, "SECONDARY", sr.position.x, sr.position.y - 12, Color("8a7343"))
	ci.draw_rect(sr, Color("100d08"), true)
	_frame(ci, sr, Color("4a3f26"))
	var sec: ItemStack = Inventory.secondary
	if sec != null and sec.item != null:
		ItemIcons.draw_icon(ci, String(sec.item.id), sr.position.x + sr.size.x / 2.0, sr.position.y + sr.size.y / 2.0, 0.9)
	else:
		PixelText.draw(ci, "EMPTY", sr.position.x + sr.size.x + 10, sr.position.y + 14, Color("5f5742"))

	var line := ""
	if _hover >= 0:
		var st: ItemStack = Inventory.slot(_hover)
		if st != null and st.item != null:
			line = st.item.display_name
			if st.item.hover_hint != "":
				line += "  -  " + st.item.hover_hint
	PixelText.draw(ci, line, PACK.position.x + 14, PACK.position.y + PACK.size.y - 14, Color("9a9078"))


func _slot(ci: CanvasItem, i: int) -> void:
	var r := _slot_rect(i)
	var st: ItemStack = Inventory.slot(i)
	var is_belt := i < Inventory.BELT_SIZE
	var bg := Color(0.11, 0.10, 0.08, 0.9) if is_belt else Color(0.05, 0.05, 0.06, 0.9)
	if i == _hover:
		bg = Color(0.16, 0.15, 0.11, 0.95)
	ci.draw_rect(r, bg, true)
	_frame(ci, r, Color("574f3b") if is_belt else Color("332f28"))
	if is_belt:
		PixelText.draw(ci, str((i + 1) % 10), r.position.x + 2, r.position.y + 2, Color("6a6350"), 4.0)
	if st == null or st.item == null:
		return
	var key := String(st.item.id)
	var c := r.position + r.size / 2.0
	if ItemIcons.has_live_icon(key):
		ItemIcons.draw_live_icon(ci, key, c.x, c.y, false, t)
	else:
		ItemIcons.draw_icon(ci, key, c.x, c.y, 0.72)
	if st.amount > 1:
		PixelText.draw(ci, str(st.amount), r.position.x + r.size.x - 4 - PixelText.width(str(st.amount), 4.0),
			r.position.y + r.size.y - 8, Color("cfe6c2"), 4.0)


# --- helpers ----------------------------------------------------------------

func _weapon_id() -> String:
	return String(Inventory.weapon.item.id) if Inventory.weapon != null and Inventory.weapon.item != null else ""


func _armour_id() -> String:
	for slot in Inventory.worn:
		var st: ItemStack = Inventory.worn[slot]
		if st != null and st.item != null:
			return String(st.item.id)
	return ""


func _damage() -> int:
	var w := Inventory.held_weapon()
	var base := w.damage if w != null else 1
	return base + PlayerProgress.damage_bonus()


func _panel(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color(0.07, 0.065, 0.055, 0.97), true)
	_frame(ci, r, Color("3b382f"))


func _frame(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), c, true)
	ci.draw_rect(Rect2(r.position.x + r.size.x - 2, r.position.y, 2, r.size.y), c, true)


func _bar(ci: CanvasItem, x: float, y: float, w: float, frac: float, hi: Color, lo: Color, text: String) -> void:
	ci.draw_rect(Rect2(x - 1, y - 1, w + 2, 8), Color("0b0a08"), true)
	ci.draw_rect(Rect2(x, y, w, 6), lo, true)
	ci.draw_rect(Rect2(x, y, roundf(w * frac), 6), hi, true)
	PixelText.draw(ci, text, x + w / 2.0 - PixelText.width(text) / 2.0, y - 1, Color("e8ddc8"), 4.0)
