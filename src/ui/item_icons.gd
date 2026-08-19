# Item icons, cut from assets/icons.png.
#
# These replace twelve hand-plotted routines from the HTML build - drawLampIcon,
# drawTorchIcon, drawKeyIcon and the rest - which were drawn a rectangle at a
# time at 12-16px and were crude by necessity. The sheet is genuine pixel art
# (32x32 grid, ~397 colours across the set, five deliberate alpha levels), so it
# reads far better and costs nothing to use.
#
# This is the line the project draws on borrowed art: icons are UI FURNITURE and
# carry none of Hollowmere's identity. The characters stay procedural, because
# that is where the identity actually lives.
#
# Coordinates are [column, row] on the 32px grid, verified by rendering a
# labelled contact sheet and looking at it - not by counting squares in my head.
class_name ItemIcons
extends RefCounted

const SHEET := "res://assets/icons.png"
const CELL := 32

# item key -> [col, row]
const MAP := {
	# --- light, and the core loop
	"lamp":     [9, 10],    # hooded lantern with a warm glow
	"torch":    [10, 10],   # lit brand
	"soul":     [2, 9],     # green flask - Soul Powder, the only heal
	# --- quest and inert items
	"tear":     [14, 12],   # pale blue shards, matching the Tear's cyan
	"shackle":  [2, 11],    # iron cuffs on a chain
	"key":      [10, 11],   # iron keys on a ring
	"letter":   [9, 13],    # sealed envelope
	"rope":     [13, 10],   # coiled rope
	"sigil":    [7, 13],    # dark tome with red marks - the Necromancer Sigil
	# --- weapons and armour
	"sword":    [0, 5],     # plain arming sword
	"sword_long": [6, 5],   # longer, ornate blade
	"bow":      [3, 6],     # bow with a nocked arrow
	"armor":    [5, 7],     # mail shirt
	"armor_plate": [7, 7],  # plate
	# --- currency and containers
	"gold":     [7, 12],    # a single struck coin
	"gold_pile":[10, 12],   # a stack, for larger drops
	"pack":     [9, 8],     # leather backpack
	"chest":    [11, 11],   # bound chest
}

static var _sheet: Texture2D = null
static var _cache: Dictionary = {}


static func sheet() -> Texture2D:
	if _sheet == null:
		_sheet = load(SHEET)
	return _sheet


# Returns an AtlasTexture for an item key, or null if it has no icon. Cached, so
# repeated lookups during a draw cost nothing.
static func get_icon(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	if not MAP.has(key):
		return null
	var cell: Array = MAP[key]
	var at := AtlasTexture.new()
	at.atlas = sheet()
	at.region = Rect2(cell[0] * CELL, cell[1] * CELL, CELL, CELL)
	_cache[key] = at
	return at


# Draw an item icon CENTRED on (cx, cy), optionally scaled. Nothing is drawn for
# an unmapped key, which is deliberate: a missing icon should be visibly missing
# rather than silently replaced by a placeholder that looks intentional.
static func draw_icon(ci: CanvasItem, key: String, cx: float, cy: float,
		scale: float = 1.0, tint: Color = Color.WHITE) -> bool:
	var tex := get_icon(key)
	if tex == null:
		return false
	var s := CELL * scale
	ci.draw_texture_rect(tex, Rect2(cx - s / 2.0, cy - s / 2.0, s, s), false, tint)
	return true


# ---------------------------------------------------------------------------
# ICONS THAT CARRY STATE ARE DRAWN, NOT BLITTED.
#
# This revises the earlier decision to take every icon from the sheet. The lamp
# and the torch are not inert pictures: they are LIT or UNLIT, and while lit they
# animate - the lamp's green core breathes, the torch's flame gutters. A sprite
# from an atlas cannot do either, which is why the belt went dead and why the
# lamp read as a potion (the sheet's lantern glows yellow; the dark iron lamp
# burns GREEN, and that green is the whole identity of the thing).
#
# So the rule is now: an item whose icon has a STATE or an ANIMATION is drawn
# procedurally, ported from the HTML build. Genuinely inert items - the key, the
# letter, the rope, the shackles - keep the sheet, where the better art costs
# nothing.
static func has_live_icon(key: String) -> bool:
	return key == "lamp" or key == "torch" or key == "soul"


static func draw_live_icon(ci: CanvasItem, key: String, cx: float, cy: float,
		lit: bool, t: float) -> void:
	match key:
		"lamp": _lamp_icon(ci, cx, cy, lit, t)
		"torch": _torch_icon(ci, cx, cy, lit, t)
		"soul": _soul_icon(ci, cx, cy, t)


static func _R(ci: CanvasItem, x: float, y: float, w: float, h: float, c: Color) -> void:
	ci.draw_rect(Rect2(x, y, w, h), c, true)


static func _lamp_icon(ci: CanvasItem, cx: float, cy: float, lit: bool, t: float) -> void:
	_R(ci, cx - 1, cy - 11, 3, 3, Color("4a4a50") if lit else Color("33333a"))
	_R(ci, cx - 5, cy - 9, 11, 2, Color("55555c") if lit else Color("3a3a41"))
	_R(ci, cx - 5, cy - 7, 11, 11, Color("1a1b1f"))
	var g := (0.55 + 0.45 * sin(t * 3.4)) if lit else 0.0
	if lit:
		_R(ci, cx - 4, cy - 6, 9, 9, Color8(int(24 + 40 * g), int(150 + 70 * g), int(78 + 50 * g)))
		_R(ci, cx - 2, cy - 4, 5, 5, Color8(int(120 + 90 * g), 255, int(160 + 60 * g)))
	else:
		_R(ci, cx - 4, cy - 6, 9, 9, Color("1d3527"))
		_R(ci, cx - 2, cy - 4, 5, 5, Color("25452f"))
	_R(ci, cx - 5, cy - 7, 2, 11, Color("44444b") if lit else Color("303036"))
	_R(ci, cx + 4, cy - 7, 2, 11, Color("44444b") if lit else Color("303036"))
	_R(ci, cx - 5, cy + 4, 11, 2, Color("55555c") if lit else Color("3a3a41"))


static func _torch_icon(ci: CanvasItem, cx: float, cy: float, lit: bool, t: float) -> void:
	_R(ci, cx - 1, cy - 2, 3, 9, Color("4a3620") if lit else Color("332616"))
	_R(ci, cx - 1, cy - 2, 1, 9, Color("5c452a") if lit else Color("3d2d1a"))
	if lit:
		var f := sin(t * 9.0) * 0.8
		_R(ci, cx - 3, cy - 7, 6, 6, Color("c2570f"))
		_R(ci, cx - 2, cy - 10 + f, 4, 4, Color("e8912b"))
		_R(ci, cx - 1, cy - 12 + f, 2, 3, Color("f5cd66"))
	else:
		_R(ci, cx - 3, cy - 7, 6, 6, Color("3d2a12"))
		_R(ci, cx - 2, cy - 10, 4, 4, Color("4a3317"))


static func _soul_icon(ci: CanvasItem, cx: float, cy: float, t: float) -> void:
	var pu := 0.55 + 0.45 * sin(t * 2.4)
	_R(ci, cx - 5, cy - 1, 10, 7, Color("2a2620"))
	_R(ci, cx - 5, cy - 3, 10, 2, Color("3a352b"))
	_R(ci, cx - 3, cy + 1, 6, 4, Color(0.588, 0.925, 0.714, 0.35 + 0.30 * pu))
	_R(ci, cx - 1, cy + 2, 3, 2, Color(0.886, 1.0, 0.933, 0.70 + 0.30 * pu))
	_R(ci, cx - 2, cy - 8 + sin(t * 2.0) * 0.8, 2, 2, Color(0.667, 0.957, 0.776, 0.4 + 0.3 * pu))
	_R(ci, cx + 2, cy - 6 + cos(t * 2.3) * 0.8, 1, 1, Color(0.667, 0.957, 0.776, 0.3 + 0.3 * pu))


static func keys() -> Array:
	return MAP.keys()
