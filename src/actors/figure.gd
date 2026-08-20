# drawFigure, ported.
#
# This is the single most important routine in the game to get right: Nestor,
# every villager, the skeletons, the zombie, the Fallen Hunter and Yotan's guards
# are ALL this body with a different palette and a different overlay. Three
# attempts at hand-drawing a separate skeleton failed before that was understood,
# so the port keeps the same discipline - one body, many palettes.
#
# Coordinates are unchanged from the HTML build: legs by-6..by, torso
# by-18..by-6, belt by-11, hood by-27..by-17, eyes at by-23. Total height 29px.
class_name Figure
extends RefCounted

# The four facings, as screen angles. NOT normalised - dir 1 is -PI/2, which is
# what forced the two-anchor rest-angle trick in the sword code.
const DIRA := [PI / 2.0, -PI / 2.0, PI, 0.0]
const SIDE := [-3, 3, 2, -2]

const PAL_PLAYER := {
	"cloak": Color("20222b"), "hi": Color("2a2d38"), "lo": Color("14151c"),
	"trim": Color("3d2f1c"), "skin": Color("050508"), "fold": Color("191b23"),
}
const PAL_BONE := {
	"cloak": Color("ded0ab"), "hi": Color("f2e9cf"), "lo": Color("8a765a"),
	"trim": Color("8a765a"), "skin": Color("bda882"), "fold": Color("bda882"),
}

# The villagers. Four muted cloaks so a crowd does not read as clones, each with
# a tunic showing at the chest and pale hands at the cuffs.
const PAL_NPC := [
	{"cloak": Color("2b2721"), "hi": Color("332f27"), "lo": Color("1b1814"),
	 "trim": Color("241d13"), "skin": Color("050505"), "fold": Color("221f19"),
	 "tunic": Color("474134"), "hand": Color("8a7563")},
	{"cloak": Color("26251f"), "hi": Color("2e2d26"), "lo": Color("181712"),
	 "trim": Color("211a11"), "skin": Color("050505"), "fold": Color("1f1e18"),
	 "tunic": Color("423f33"), "hand": Color("83705f")},
	{"cloak": Color("292228"), "hi": Color("31292f"), "lo": Color("1a1519"),
	 "trim": Color("221a15"), "skin": Color("050505"), "fold": Color("221c21"),
	 "tunic": Color("453b3e"), "hand": Color("8d7668")},
	{"cloak": Color("232823"), "hi": Color("2b302a"), "lo": Color("161a16"),
	 "trim": Color("1f1a12"), "skin": Color("050505"), "fold": Color("1d211c"),
	 "tunic": Color("3d443a"), "hand": Color("7e6f5e")},
]

# The sword in the swinging hand. The guard grows a touch and the blade grows a
# LOT with the swing extension; the guard base never moves inward, so the blade
# only ever reaches AWAY from the hand and can never cross into the body. These
# are the exact numbers the HTML build's intersection sweep was verified against.
const GUARD_BASE := 14.0
const GUARD_SPAN := 1.0
const TIP_BASE := 21.0
const TIP_SPAN := 4.0
const GUARD_C := Color("9a8760")
const GUARD_D := Color("635742")
const STEEL_HI := Color("eef3f7")
const STEEL := Color("b6c0c9")
const STEEL_LO := Color("7d868f")


static func eye_colour(kind: String, t: float) -> Color:
	var ep := 0.75 + 0.25 * sin(t * 2.3)
	if kind == "pale":
		return Color8(int(206 + 34 * ep), int(210 + 34 * ep), int(198 + 32 * ep))
	if kind == "rot":
		var rp := 0.62 + 0.38 * sin(t * 1.5)
		return Color8(int(150 + 72 * rp), int(168 + 56 * rp), int(60 + 40 * rp))
	if kind == "hunter":
		# the only green eyes in the game - the Fallen Hunter, wearing the coat
		var hp := 0.7 + 0.3 * sin(t * 2.9)
		return Color8(int(56 * hp), int(190 + 34 * hp), int(104 + 26 * hp))
	return Color8(int(194 * ep), int(42 * ep), int(30 * ep))


# `ci` is any CanvasItem currently inside _draw(). Everything is drawn in local
# space around (0,0) at the figure's FEET, so the caller positions the node and
# this never needs to know about a camera - which is a straight improvement on
# the HTML build, where every draw call carried a manual cam offset.
#
# `origin` exists because draw_body RESETS the canvas transform internally (it
# has to, to squash the shadow into an ellipse), which silently clobbers any
# transform the caller set up. In the game that never showed, because the player
# node draws at its own origin anyway - it only surfaced when the comparison
# harness tried to draw four figures side by side and got an empty frame. Offset
# through this parameter, never through draw_set_transform around the call.
static func draw_body(ci: CanvasItem, dir: int, phase: float, moving: bool,
		pal: Dictionary, opts: Dictionary, t: float,
		origin: Vector2 = Vector2.ZERO) -> void:
	var sw := sin(phase) if moving else 0.0
	var bob := 1.0 if (moving and sin(phase * 2.0) > 0.4) else 0.0
	var by := -bob
	var side := (dir == 2 or dir == 3)
	var fc := 1.0 if dir == 3 else (-1.0 if dir == 2 else 0.0)
	var swing := roundi(sw * 3.0)

	var R := func(x: float, y: float, w: float, h: float, c: Color) -> void:
		ci.draw_rect(Rect2(origin.x + x, origin.y + y, w, h), c, true)

	# Ground shadow. It is an ELLIPSE - 8 wide by 3.2 tall - not a circle. Drawn
	# round it is 16px tall, swallows the legs and makes the figure look like it
	# is standing in a hole. Godot has no draw_ellipse, so the transform is
	# scaled and a circle drawn into it.
	ci.draw_set_transform(origin + Vector2(0, by + 1), 0.0, Vector2(1.0, 0.4))
	ci.draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.5))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# ---- legs
	if side:
		var fl := roundi(sw * 3.0) * fc
		var bl := -fl
		R.call(-2 + bl, by - 6, 3, 6, pal.lo)
		R.call(-2 + fl, by - 6, 3, 6, pal.cloak)
		R.call(-2 + bl, by - 2, 5, 2, Color("0b0a08"))
		R.call(-2 + fl, by - 2, 5, 2, Color("0c0b09"))
	else:
		var la: float = max(0.0, round(sw * 3.0))
		var lb: float = max(0.0, round(-sw * 3.0))
		R.call(-5, by - 6, 3, 6 - la, pal.cloak); R.call(-5, by - 2 - la, 5, 2, Color("0b0a08"))
		R.call(2, by - 6, 3, 6 - lb, pal.cloak); R.call(2, by - 2 - lb, 5, 2, Color("0b0a08"))

	# ---- torso
	if side:
		R.call(-4, by - 18, 9, 12, pal.cloak)
		R.call(-4 + (6 if fc > 0 else 0), by - 18, 3, 12, pal.hi)
		R.call(-4 + (0 if fc > 0 else 6), by - 18, 3, 12, pal.fold)
		if pal.has("tunic"):
			R.call(-1, by - 17, 3, 8, pal.tunic)
		R.call(-6, by - 9, 13, 3, pal.lo)
		R.call(-4, by - 11, 9, 2, pal.trim)
		R.call(-1, by - 11, 2, 2, Color("6b5a3e"))
	else:
		R.call(-6, by - 18, 12, 12, pal.cloak)
		R.call(-6, by - 18, 3, 12, pal.hi)
		R.call(3, by - 18, 3, 12, pal.fold)
		if pal.has("tunic"):
			R.call(-3, by - 17, 6, 8, pal.tunic)
			R.call(-3, by - 17, 6, 1, pal.hi)
		R.call(-1, by - 17, 1, 10, pal.fold)
		R.call(-7, by - 9, 14, 3, pal.lo)
		R.call(-6, by - 11, 12, 2, pal.trim)
		R.call(-1, by - 11, 3, 2, Color("6b5a3e"))
		R.call(-7, by - 20, 14, 3, pal.hi)
		R.call(-7, by - 20, 14, 1, pal.fold)

	# Where a held light hangs. The HTML build offsets it per facing and draws it
	# BEHIND the body when you face away, so the lamp is occluded by your own
	# back - which is the whole reason walking north is frightening.
	var light_kind: String = opts.get("light", "")
	var tp := Vector2.INF
	if light_kind != "":
		var tdx := -9.0 if dir == 2 else (9.0 if dir == 3 else (-9.0 if dir == 1 else 9.0))
		tp = origin + Vector2(tdx, by - (13.0 if light_kind == "lamp" else 22.0))
		if dir == 1:
			_draw_held(ci, light_kind, tp, t)

	# ---- arms and hands
	var hand: Color = pal.get("hand", Color("0e0d0b"))
	var blade: bool = opts.get("blade", false)
	if side:
		var ax := -1 + fc * 3 + roundi(sw * 3.0) * fc
		if not blade:
			R.call(ax, by - 17, 3, 8, pal.hi)
			R.call(ax, by - 11, 3, 3, hand)
	else:
		var free := -9 if dir == 0 else 6
		var held := 6 if dir == 0 else -9
		if not blade:
			R.call(free, by - 17 + swing, 3, 8, pal.hi)
			R.call(free, by - 11 + swing, 3, 3, hand)
		# the carrying arm does not swing - it is holding something
		if light_kind != "":
			R.call(held, by - 18, 3, 9, pal.hi)
			R.call(held, by - 12, 3, 3, hand)
		elif not blade:
			R.call(held, by - 17 - swing, 3, 8, pal.hi)
			R.call(held, by - 11 - swing, 3, 3, hand)

	# ---- head and hood
	var eyes: String = opts.get("eyes", "")
	if side:
		R.call(-5, by - 27, 11, 10, pal.cloak)
		R.call(-4, by - 29, 9, 2, pal.cloak)
		R.call(-5 + (7 if fc > 0 else 0), by - 27, 4, 10, pal.hi)
		R.call(-5, by - 28, 11, 1, pal.fold)
		if fc > 0:
			R.call(2, by - 24, 4, 5, pal.skin)
			if eyes != "": R.call(4, by - 23, 2, 2, eye_colour(eyes, t))
		else:
			R.call(-5, by - 24, 4, 5, pal.skin)
			if eyes != "": R.call(-5, by - 23, 2, 2, eye_colour(eyes, t))
		R.call(-6, by - 18, 13, 2, pal.lo)
	elif dir == 1:
		R.call(-6, by - 27, 12, 10, pal.cloak)
		R.call(-5, by - 29, 10, 2, pal.cloak)
		R.call(-6, by - 27, 3, 10, pal.hi)
		R.call(-1, by - 26, 2, 9, pal.lo)
		R.call(-6, by - 28, 12, 1, pal.fold)
	else:
		R.call(-6, by - 27, 12, 10, pal.cloak)
		R.call(-5, by - 29, 10, 2, pal.cloak)
		R.call(-6, by - 27, 3, 10, pal.hi)
		R.call(-6, by - 28, 12, 1, pal.fold)
		R.call(-4, by - 24, 8, 6, pal.skin)
		R.call(-4, by - 24, 8, 1, Color.BLACK)
		if eyes != "":
			var ec := eye_colour(eyes, t)
			R.call(-3, by - 23, 2, 2, ec)
			R.call(1, by - 23, 2, 2, ec)

	# Drawn LAST for every facing except north, so the light is in front of the
	# body - you are carrying it, not standing behind it.
	if light_kind != "" and dir != 1:
		_draw_held(ci, light_kind, tp, t)

	# The sword, in the hand the swing state drives. Its angle and length come
	# from the caller's MeleeAttack so this stays a pure drawer.
	if opts.get("blade", false):
		var angle: float = opts.get("blade_angle", 0.0)
		var ext: float = opts.get("swing_ext", 0.0)
		var reach: float = opts.get("reach", 0.0)
		_draw_arm_blade(ci, origin + Vector2(SIDE[dir], by - 16.0), angle, pal, ext, reach)


# drawArmBlade, ported. Draws the cloth arm out to the guard, the crossguard,
# then a parallel-edged steel blade with a lit spine. Every coordinate rounds the
# way the HTML rect() did, so the blade stays crisp under the pixel upscale.
static func _draw_arm_blade(ci: CanvasItem, base: Vector2, ang: float,
		pal: Dictionary, ext: float, reach: float) -> void:
	var gr := GUARD_BASE + GUARD_SPAN * ext
	var tip := TIP_BASE + TIP_SPAN * ext + reach
	var cs := cos(ang)
	var sn := sin(ang)
	var nx := -sn
	var ny := cs
	var cx := base.x
	var cy := base.y
	var px := func(x, y, w, h, c): ci.draw_rect(
		Rect2(roundf(x), roundf(y), ceilf(w), ceilf(h)), c, true)

	var i := 1.0
	while i <= gr - 3.0:
		px.call(cx + cs * i - 1, cy + sn * i - 1, 3, 3, pal.cloak if i < 4.0 else pal.hi)
		i += 1.0
	px.call(cx + cs * (gr - 1.5) - 1, cy + sn * (gr - 1.5) - 1, 3, 3, Color("141210"))
	for k in range(-2, 3):
		px.call(cx + cs * gr + nx * k, cy + sn * gr + ny * k, 1, 1,
			GUARD_C if absi(k) <= 1 else GUARD_D)
	var j := ceilf(gr) + 1.0
	while j <= tip:
		var near := j > tip - 1.5
		px.call(cx + cs * j, cy + sn * j, 1, 1, Color.WHITE if near else STEEL_HI)
		if j < tip - 0.5:
			px.call(cx + cs * j + nx, cy + sn * j + ny, 1, 1, STEEL)
		if j < tip - 2.0:
			px.call(cx + cs * j + nx * 2, cy + sn * j + ny * 2, 1, 1, STEEL_LO)
		j += 1.0


static func _draw_held(ci: CanvasItem, kind: String, tp: Vector2, t: float) -> void:
	if kind == "lamp":
		_draw_lamp(ci, tp, t)
	else:
		_draw_torch(ci, tp, t)


# THE DARK IRON LAMP. It burns GREEN - that is the whole visual identity of the
# thing, and why the lamp orb is green and the light it throws is green.
static func _draw_lamp(ci: CanvasItem, p: Vector2, t: float) -> void:
	var g := 0.55 + 0.45 * sin(t * 2.6) + 0.15 * sin(t * 6.1)
	var R := func(x, y, w, h, c): ci.draw_rect(Rect2(p.x + x, p.y + y, w, h), c, true)
	R.call(-1, -12, 3, 4, Color("25262a"))          # the hanging ring
	R.call(-3, -9, 6, 2, Color("33343a"))
	R.call(-6, -7, 12, 2, Color("3c3d44"))
	R.call(-6, -7, 12, 1, Color("4a4b53"))
	R.call(-6, -5, 12, 12, Color("131418"))         # the iron body
	R.call(-4, -4, 8, 10, Color8(int(14 + 26 * g), int(96 + 72 * g), int(54 + 44 * g)))
	R.call(-3, -3, 6, 8, Color8(int(58 + 70 * g), int(186 + 66 * g), int(104 + 62 * g)))
	R.call(-2, -1, 4, 4, Color8(int(150 + 90 * g), 255, int(180 + 55 * g)))
	R.call(-6, -5, 2, 12, Color("2b2c32"))          # the cage bars
	R.call(4, -5, 2, 12, Color("2b2c32"))
	R.call(-1, -5, 1, 12, Color("202126"))
	R.call(-6, 7, 12, 2, Color("3c3d44"))
	R.call(-3, 9, 6, 1, Color("25262a"))


static func _draw_torch(ci: CanvasItem, p: Vector2, t: float) -> void:
	var f := sin(t * 11.0) * 0.9 + sin(t * 23.0) * 0.6
	var R := func(x, y, w, h, c): ci.draw_rect(Rect2(p.x + x, p.y + y, w, h), c, true)
	R.call(-2, 2, 3, 12, Color("241a10"))           # the brand
	R.call(-2, 2, 1, 12, Color("2f2214"))
	R.call(-2, 1, 3, 2, Color("3a2b18"))
	R.call(-3, -3, 6, 7, Color("c2570f"))
	R.call(-2, -6 + f * 0.5, 4, 6, Color("e8912b"))
	R.call(-1, -8 + f, 2, 4, Color("f3c85e"))
	R.call(-1, -9 + f, 1, 2, Color("fbe9a8"))
