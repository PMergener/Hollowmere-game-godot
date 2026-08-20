# Houses, trees and braziers, each as its own y-sorted node.
#
# In the HTML build these were pushed into a layers[] array and sorted by y every
# frame. Here the parent has y_sort_enabled and Godot does it - one of the
# clearest wins of the port, and about forty lines deleted.
extends Node2D

enum Kind { HOUSE, TREE, BRAZIER, PYRE, WELL, CART }

var kind: int = Kind.HOUSE
var w := 0.0
var h := 0.0
var lit := false
var ruin := false
var bare := false
var seed_val := 0
var ph := 0.0
var t := 0.0

@onready var light: PointLight2D = get_node_or_null("Light")


func _process(delta: float) -> void:
	# Only the things that actually move ask for a redraw. Houses, trees, graves
	# and the cart are drawn once and cached; the HTML build had to redraw every
	# one of them every frame.
	# Lit houses redraw too - only for the wisp of chimney smoke, which is the one
	# moving thing on an otherwise static building.
	if kind == Kind.BRAZIER or kind == Kind.PYRE or kind == Kind.WELL \
			or (kind == Kind.HOUSE and lit and not ruin):
		t += delta
		queue_redraw()
		if light:
			# A warm pool that actually reads on the ground, not a faint halo -
			# the flicker rides a brighter base so a brazier looks lit, not merely
			# drawn. Two detuned sines keep the flame from settling into a pulse.
			light.energy = 1.35 + sin(t * 9.0 + ph) * 0.12 + sin(t * 17.0 + ph) * 0.07


func _draw() -> void:
	match kind:
		Kind.HOUSE: _draw_house()
		Kind.TREE: _draw_tree()
		Kind.BRAZIER: _draw_brazier()
		Kind.PYRE: _draw_pyre()
		Kind.WELL: _draw_well()
		Kind.CART: _draw_cart()


# The pyre at the village centre - the one fire that is always burning.
func _draw_pyre() -> void:
	var f := sin(t * 3.1) * 0.7 + sin(t * 7.7) * 0.4
	draw_rect(Rect2(-24, -3, 49, 10), Color(0, 0, 0, 0.5), true)
	for i in 11:
		var a := i / 11.0 * TAU
		draw_rect(Rect2(cos(a) * 21 - 3, sin(a) * 11 - 2, 6, 4), Color("22201c"), true)
		draw_rect(Rect2(cos(a) * 21 - 3, sin(a) * 11 - 2, 6, 1), Color("2c2a24"), true)
	draw_rect(Rect2(-16, -6, 33, 9), Color("100d09"), true)
	draw_rect(Rect2(-13, -9, 27, 4), Color("171208"), true)
	draw_rect(Rect2(-3, -45, 6, 39), Color("0d0a06"), true)      # the stake
	draw_rect(Rect2(-3, -45, 2, 39), Color("141009"), true)
	draw_rect(Rect2(-12, -33, 25, 3), Color("0d0a06"), true)     # the crossbar
	for i in 11:
		var px := -12 + i * 2.4 + sin(t * 2 + i) * 0.8
		draw_rect(Rect2(px, -5, 2, 3),
			Color("b0470f") if (0.5 + 0.5 * sin(t * 5 + i * 1.7)) > 0.6 else Color("5c2408"), true)
	draw_rect(Rect2(-6 + f, -9, 3, 3), Color("d9631a"), true)
	draw_rect(Rect2(4 - f, -8, 3, 3), Color("a5450f"), true)
	draw_rect(Rect2(-1, -11 + f * 0.5, 2, 2), Color("eda13a"), true)


# The well - the way down into the undercroft.
func _draw_well() -> void:
	draw_rect(Rect2(-20, -2, 41, 10), Color(0, 0, 0, 0.5), true)
	draw_rect(Rect2(-17, -15, 35, 17), Color("4e4e52"), true)
	draw_rect(Rect2(-17, -15, 35, 3), Color("6a6a70"), true)
	draw_rect(Rect2(-17, -1, 35, 3), Color("33333a"), true)
	for r2 in 3:
		for i in 6:
			var bx := -17 + i * 6 + (3 if r2 % 2 else 0)
			var byy := -15 + r2 * 6
			draw_rect(Rect2(bx, byy, 5, 5), Color("5c5c62") if r2 == 0 else Color("4a4a50"), true)
			draw_rect(Rect2(bx, byy, 5, 1), Color("6e6e76"), true)
			draw_rect(Rect2(bx + 5, byy, 1, 5), Color("2e2e34"), true)
	draw_rect(Rect2(-14, -19, 29, 5), Color("66666e"), true)
	draw_rect(Rect2(-14, -19, 29, 2), Color("7c7c86"), true)
	draw_rect(Rect2(-14, -15, 29, 1), Color("33333a"), true)
	draw_rect(Rect2(-12, -18, 25, 4), Color("1a2620"), true)     # the water
	var wob := sin(t * 0.9) * 1.0
	draw_rect(Rect2(-11, -18, 23, 3), Color("22392c"), true)
	draw_rect(Rect2(-9 + wob, -18, 8, 1), Color("2e5240"), true)
	draw_rect(Rect2(2 - wob, -17, 6, 1), Color("2a4a39"), true)
	for px in [-19.0, 15.0]:                                      # the posts
		draw_rect(Rect2(px, -46, 5, 31), Color("4a3520"), true)
		draw_rect(Rect2(px, -46, 2, 31), Color("5e4429"), true)
		draw_rect(Rect2(px, -20, 5, 3), Color("382718"), true)
	draw_rect(Rect2(-20, -49, 41, 4), Color("5e4429"), true)      # the roof beam
	draw_rect(Rect2(-20, -49, 41, 1), Color("75553a"), true)


func _draw_cart() -> void:
	draw_rect(Rect2(-18, -2, 38, 9), Color(0, 0, 0, 0.45), true)
	draw_rect(Rect2(-16, -14, 34, 14), Color("1c1811"), true)
	for i in 5:
		draw_rect(Rect2(-16, -14 + i * 3, 34, 1), Color("171309"), true)
	draw_rect(Rect2(-16, -17, 34, 4), Color("252017"), true)
	draw_rect(Rect2(-16, -17, 34, 1), Color("2e281c"), true)
	draw_rect(Rect2(-14, -3, 11, 11), Color("100d08"), true)      # wheels
	draw_rect(Rect2(-12, -1, 7, 7), Color("1d1913"), true)
	draw_rect(Rect2(-9, 2, 1, 1), Color("2a251c"), true)
	draw_rect(Rect2(7, 1, 7, 7), Color("100d08"), true)
	draw_rect(Rect2(9, 3, 3, 3), Color("1d1913"), true)
	draw_rect(Rect2(17, -12, 13, 3), Color("1a160f"), true)       # the shaft


# The node sits at the house's BASE, not its top-left, so y-sorting compares
# like with like. With the node at the top the player was sorting IN FRONT of
# every house whose top was above him - which is why you could stand on a roof.
# Everything below is still authored from the top-left, so the whole drawing is
# shifted up by the house's height.
func _draw_house() -> void:
	draw_set_transform(Vector2(0, -h), 0.0, Vector2.ONE)
	_draw_house_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Ported whole from the HTML's drawHouse: the courses-and-studs wall, a planked
# door with a handle, warm or dark windows with their mullions, and - the part
# that was missing and made the roofs read as flat wedges - a proper shingled roof
# with vertical battens and a ridge beam, topped by a chimney breathing smoke, or
# for the ruins a hole punched through to the dark and a fallen second stack.
func _draw_house_body() -> void:
	var rr := Rng.new(seed_val)
	var R := func(x, y, ww, hh, c): draw_rect(Rect2(x, y, ww, hh), c, true)
	R.call(4, 9, w, h, Color(0, 0, 0, 0.5))                       # ground shadow

	var wall_y := h * 0.62
	var wall_h := h * 0.38
	R.call(3, wall_y, w - 6, wall_h, Color("171410") if ruin else Color("1e1913"))
	for i in range(int(wall_h / 6.0)):
		R.call(3, wall_y + i * 6 + 3, w - 6, 1, Color("131009") if ruin else Color("191409"))
	for i in range(1, 5):
		R.call(3 + i * (w - 6) / 5.0, wall_y, 2, wall_h, Color("151108"))
	R.call(3, wall_y, w - 6, 2, Color("292219"))

	# the door: dark, planked, with a handle and frame highlights on the whole ones
	var dw := 17.0
	var dx := w / 2.0 - dw / 2.0
	var dh := 21.0
	R.call(dx - 1, wall_y + wall_h - dh - 1, dw + 2, dh + 1, Color("171208"))
	R.call(dx, wall_y + wall_h - dh, dw, dh, Color("0b0906"))
	for i in range(1, 4):
		R.call(dx + i * dw / 4.0, wall_y + wall_h - dh, 1, dh, Color("141009"))
	if not ruin:
		R.call(dx + dw - 4, wall_y + wall_h - 11, 2, 2, Color("5c5140"))   # handle
		R.call(dx + 1, wall_y + wall_h - dh + 3, dw - 2, 1, Color("251d12"))
		R.call(dx + 1, wall_y + wall_h - 5, dw - 2, 1, Color("251d12"))

	# windows - warm for the lit houses, dark otherwise, each with its cross mullion
	var win_y := wall_y + 6
	for wx in [11.0, w - 24.0]:
		R.call(wx - 1, win_y - 1, 15, 12, Color("100c07"))
		if lit and not ruin:
			R.call(wx, win_y, 13, 10, Color("3d2c10"))
			R.call(wx + 1, win_y + 1, 11, 8, Color("b87c22"))
			R.call(wx + 2, win_y + 2, 9, 6, Color("d99b34"))
			R.call(wx + 4, win_y + 3, 4, 3, Color("efc164"))
		else:
			R.call(wx, win_y, 13, 10, Color("0a0806"))
			R.call(wx + 1, win_y + 1, 11, 8, Color("0d0b08"))
		R.call(wx + 6, win_y, 1, 10, Color("241a0d"))
		R.call(wx, win_y + 4, 13, 1, Color("241a0d"))

	# the roof: shingle rows that taper inward, vertical battens, an eave, a ridge
	var roof_h := h * 0.62
	var mid_x := w / 2.0
	for i in range(int(roof_h)):
		var t2 := i / roof_h
		var inset := (1.0 - t2) * 4.0
		var c := Color("1b1a19") if ruin else Color("232224")
		if i % 7 == 0:
			c = Color("141312") if ruin else Color("191819")
		elif i % 7 == 1:
			c = Color("1f1e1c") if ruin else Color("282729")
		R.call(-3 + inset, i, w + 6 - inset * 2.0, 1, c)
	for k in range(int(w / 13.0)):
		var px := 2 + k * 13 + (k % 2) * 5
		R.call(px, 3, 1, roof_h - 5, Color("151413") if ruin else Color("1c1b1d"))
	R.call(-3, roof_h - 3, w + 6, 3, Color("0f0e0d"))
	R.call(mid_x - 2, 2, 4, roof_h - 4, Color("333234"))
	R.call(mid_x - 2, 2, 1, roof_h - 4, Color("3d3c3f"))

	if ruin:
		var hx := mid_x - 12 + rr.next() * 16.0                    # a hole to the dark
		R.call(hx, 5, 18, roof_h * 0.62, Color("0a0a09"))
		R.call(hx + 3, 3, 11, 3, Color("141313"))
		R.call(mid_x + 4, roof_h * 0.3, 9, roof_h * 0.5, Color("0a0a09"))
	else:
		var cx2 := w * 0.72                                        # chimney + smoke
		R.call(cx2, -11, 9, 14, Color("1a1917"))
		R.call(cx2, -13, 9, 3, Color("262421"))
		R.call(cx2 + 1, -12, 3, 1, Color("0d0c0b"))
		for s in 3:
			var sy2 := -15.0 - s * 5.0 - float(int(sin(t * 0.7 + seed_val + s) * 2.0))
			var sx := cx2 + 3.0 + sin(t * 0.5 + s + seed_val) * 3.0
			R.call(sx, sy2, 3.0 - s * 0.5, 2, Color(60.0 / 255, 58.0 / 255, 54.0 / 255, 0.16 - s * 0.04))


func _draw_tree() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 15.0 if not bare else 9.0, Color(0, 0, 0, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-9, -3, 5, 4), Color("1d1811"), true)
	draw_rect(Rect2(-6, -5, 4, 4), Color("241e15"), true)
	draw_rect(Rect2(4, -3, 6, 4), Color("1d1811"), true)
	draw_rect(Rect2(3, -5, 4, 4), Color("241e15"), true)
	var th := 42.0 if bare else 34.0
	draw_rect(Rect2(-3, -th, 7, th), Color("241e15"), true)
	draw_rect(Rect2(-3, -th, 3, th), Color("302719"), true)
	draw_rect(Rect2(3, -th, 1, th), Color("16120c"), true)
	for i in range(5):
		draw_rect(Rect2(-2, -th + 6 + i * 6, 4, 1), Color("191309"), true)
	var rr := Rng.new(seed_val)
	if bare:
		# Ten branches, not five, and at the ORIGINAL offsets. My first pass
		# invented a handful and they were invisible against the trunk, so the
		# tree read as a bare pole with rungs - a ladder, not a tree.
		for v in [[-15,-33,13], [3,-39,13], [-19,-24,10], [6,-22,12], [-10,-44,9],
				  [-22,-35,7], [14,-41,7], [-13,-28,6], [9,-31,8], [2,-46,7]]:
			draw_rect(Rect2(v[0], v[1], v[2], 1), Color("171309"), true)
			if rr.next() > 0.5:
				draw_rect(Rect2(v[0] + 1, v[1] - 1, max(2, v[2] - 3), 1), Color("1d1810"), true)
		draw_rect(Rect2(-4, -46, 8, 2), Color("1b1610"), true)
		return
	# The canopy is a fixed set of overlapping BLOBS, each drawn dark then inset
	# lighter - not a scatter of random squares. The randomised version read as
	# gravel floating above a stick.
	const LEAF_D := Color("101c0e")
	const LEAF_M := Color("1a2c15")
	const LEAF_L := Color("25401d")
	var blobs := [
		[0,-52,17,13], [-14,-46,13,11], [13,-45,13,11], [-8,-58,13,10], [8,-57,13,10],
		[0,-40,19,10], [-17,-37,11,8], [16,-36,11,8], [0,-63,10,7],
	]
	for b in blobs:
		draw_rect(Rect2(b[0] - b[2] / 2.0, b[3] / 2.0 + b[1] - b[3], b[2], b[3]), LEAF_D, true)
	for b in blobs:
		var bx: float = b[0] - b[2] / 2.0
		var by2: float = b[3] / 2.0 + b[1] - b[3]
		draw_rect(Rect2(bx + 1, by2 + 1, b[2] - 2, b[3] - 2), LEAF_M, true)
		if b[0] <= 2:
			draw_rect(Rect2(bx + 1, by2 + 1,
				max(3.0, (b[2] - 2) * 0.55), max(2.0, (b[3] - 2) * 0.55)), LEAF_L, true)
	for v in [[-6,-59,6,3], [3,-58,5,3], [-13,-49,5,3], [9,-48,5,3], [-3,-64,5,2]]:
		draw_rect(Rect2(v[0], v[1], v[2], v[3]), LEAF_L, true)


# ---- the fire poles -------------------------------------------------------
# Rebuilt from the user's five-frame torch reference. It was a squat 12px bowl;
# it is now a standing torch on a wooden pole with a proper animated flame.
#
# The flame is NOT hand-plotted as five pixel grids - miscounting one row of a
# 5x12 grid is exactly the kind of error I make and cannot see. Instead each
# frame is a table of HALF-WIDTHS per row, bottom to top, which captures the
# silhouette faithfully while being impossible to misalign. Sparks are listed
# per frame separately, as they are in the reference.
const POLE_L := Color("a5652e")
const POLE_M := Color("8a5024")
const POLE_D := Color("5e3216")
const POLE_K := Color("3f2010")
const BOWL_M := Color("6b3a1c")
const BOWL_D := Color("33190b")
const BOWL_K := Color("24120a")
# GRIM, not festive. The first pass used the reference sheet's colours straight -
# but that reference is a bright icon on white, and dropped into a night village
# the torches read as glowing street lamps and dominated every frame. These are
# deep and smoky: a dull ember red outside, burnt orange inside, and a core that
# is warm rather than pale yellow. Fire you would huddle near, not fireworks.
const FLAME_O := Color("8e2f0d")   # outer, dull ember
const FLAME_M := Color("c25a13")   # mid, burnt orange
const FLAME_C := Color("e08a2a")   # core, warm - never a bright yellow

# five frames; each is the flame's half-width per row from the bowl upward
# The silhouette HOLDS ITS WIDTH for the lower half before tapering - that is
# what makes the reference read as a body of fire rather than a spike. My first
# pass tapered from the very first row and came out as a thin wisp.
# Also SMALLER. At half-width 6-7 the flame was wider than the bowl and read as
# a lantern hood rather than a fire.
const FLAME_FRAMES := [
	[3, 4, 4, 3, 3, 2, 1],
	[3, 4, 4, 4, 3, 2, 2, 1],
	[4, 4, 5, 4, 4, 3, 2, 1, 1],
	[3, 4, 4, 4, 3, 3, 2, 1],
	[3, 3, 4, 3, 2, 2, 1],
]
# sparks that have broken away, as [x, y-above-the-flame-top] per frame
const FLAME_SPARKS := [
	[[-5, 2], [1, 4]],
	[[-1, 3], [3, 6]],
	[[2, 3], [4, 7], [-3, 5]],
	[[-2, 4], [3, 8], [5, 2]],
	[[4, 3], [-4, 6]],
]

func _draw_brazier() -> void:
	# ---- the pole
	draw_rect(Rect2(-2, -22, 4, 23), POLE_M)
	draw_rect(Rect2(-2, -22, 1, 23), POLE_L)          # lit edge
	draw_rect(Rect2(1, -22, 1, 23), POLE_K)           # shadow edge
	for i in range(3, 22, 5):                          # grain
		draw_rect(Rect2(-1, -22 + i, 2, 1), POLE_D)
	draw_rect(Rect2(-1, 1, 2, 2), POLE_K)             # the butt in the ground

	# ---- the bowl it burns in
	draw_rect(Rect2(-6, -28, 12, 6), BOWL_M)
	draw_rect(Rect2(-6, -28, 12, 2), BOWL_D)          # the rim, seen from above
	draw_rect(Rect2(-4, -27, 8, 1), BOWL_K)           # the hollow
	draw_rect(Rect2(-6, -23, 12, 1), BOWL_K)
	draw_rect(Rect2(-5, -22, 10, 1), POLE_K)          # where it meets the pole

	# ---- the flame. Five frames at ~9fps, offset per torch so a row of them
	# never flickers in unison - that synchrony is what makes fire look fake.
	var fi := int(t * 9.0 + ph * 3.0) % FLAME_FRAMES.size()
	var rows: Array = FLAME_FRAMES[fi]
	var base := -27.0
	for r in rows.size():
		var hw: int = rows[r]
		var y := base - r
		draw_rect(Rect2(-hw, y, hw * 2, 1), FLAME_O)
		if hw >= 2:
			draw_rect(Rect2(-(hw - 1), y, (hw - 1) * 2, 1), FLAME_M)
		# The pale core is a BODY in the lower-middle of the flame, not a thin
		# thread up the centre - it stops about 45% from the top, as in the
		# reference, so the tip stays orange.
		if hw >= 4 and r >= 1 and r < int(rows.size() * 0.55):
			draw_rect(Rect2(-(hw - 3), y, (hw - 3) * 2, 1), FLAME_C)
	for s in FLAME_SPARKS[fi]:
		draw_rect(Rect2(s[0], base - rows.size() - s[1], 1, 1), FLAME_O)


class Rng:
	var s: int
	func _init(seed_val2: int) -> void:
		s = seed_val2
	func next() -> float:
		s = (s + 0x6D2B79F5) & 0xFFFFFFFF
		var x := s
		var a := ((x ^ (x >> 15)) * (1 | x)) & 0xFFFFFFFF
		var b := (((a ^ (a >> 7)) * (61 | a)) ^ a) & 0xFFFFFFFF
		return float((b ^ (b >> 14)) & 0xFFFFFFFF) / 4294967296.0
