# Village geometry, lifted VERBATIM from hollowmere.html so the two builds are
# comparable. If a number here disagrees with the HTML file, the HTML file is
# right and this is a porting error.
#
# Kept as plain data rather than a TileMap on purpose: the HTML build validates
# placement by flood fill, and keeping the same arrays means the same validation
# can run here and be compared against the same expected results.
class_name WorldData
extends RefCounted

const WORLD := 1200.0
const TILE := 24.0

# [x, y, w, h]
const HOUSES := [
	[834, 482, 140, 113], [110, 760, 133, 105], [756, 812, 123, 93], [275, 561, 130, 114],
	[478, 830, 114, 103], [176, 322, 126, 95], [463, 195, 147, 122], [774, 159, 117, 89],
	[736, 318, 153, 105], [390, 979, 125, 93], [639, 954, 124, 122], [949, 649, 130, 96],
	[932, 794, 157, 88], [295, 723, 137, 89], [295, 145, 112, 113],
]
const HOUSE_LIT := [0, 3, 6, 8, 11, 13]
const HOUSE_RUIN := [4, 9, 14]

const TREES := [
	[977, 936], [962, 274], [814, 678], [938, 383], [154, 612], [773, 574],
	[757, 781], [631, 750], [381, 445], [298, 853], [414, 901], [339, 318],
	[732, 255], [230, 551], [916, 671], [473, 481],
]
const TREE_BARE := [2, 7, 11, 14]
const TREE_OWL := [0, 1, 4]

# SCATTERED, NOT MULTIPLIED. The ask was that they be spread out; I read it as
# "add more" and ended up with thirty, which lit the village like a street and
# left no dark for the game to work in.
#
# The original sixteen sit in eight tight PAIRS around the centre. One of each
# pair is dropped - that is what breaks the ring - and six are placed further
# out, giving fourteen: fewer than the original, and spread.
const BRAZIER_CORE := [
	[248, 600], [392, 344], [640, 272], [816, 288],
	[920, 632], [872, 784], [640, 928], [392, 856],
]
const BRAZIER_EXTRA := [
	[168, 430], [1010, 380], [1032, 880], [300, 960], [128, 300], [560, 640],
]

# {x, y, r}
const STONES := [
	[600, 585, 22], [470, 672, 14], [722, 690, 15],
]

# The village graveyard, and the fence line east of it.
const GRAVES := [
	[196, 470], [220, 500], [178, 506], [232, 466], [200, 536], [168, 466],
]

# The village wall. blocked() already refuses anything outside 36..WORLD-36, so
# the wall needs no collision of its own - it is drawn just outside that line.
const WALL_IN := 36.0
const WALL_T := 30.0
const GATE_W := 96.0
const WALL_H := Color("6a675e")
const WALL_L := Color("54514a")
const WALL_M := Color("434039")
const WALL_D := Color("34322c")

const PLAYER_START := Vector2(600, 664)

# The people, and where they start their wandering. Palettes cycle through
# Figure.PAL_NPC. An empty line means they have nothing left to say.
const VILLAGER_SPOTS := [
	Vector2(720, 600), Vector2(685, 685), Vector2(600, 720), Vector2(515, 685),
	Vector2(480, 600), Vector2(515, 515), Vector2(600, 480), Vector2(685, 515),
]
const VILLAGER_LINES := [
	"",
	"I bar the shutters every night. It doesn't help. They don't use doors.",
	"My daughter stopped speaking after the second night. She only watches the window now.",
	"",
	"I hear my brother calling up from the well. He's been in the ground since spring.",
	"There is no point sleeping. You wake up more tired and they are still there.",
	"",
	"We used to bury them proper, with the rites. Now we just leave them. Maybe that is the sin.",
]

# Where the wraiths begin. They wander until the lamp wakes them.
const GHOST_SPOTS := [
	Vector2(812, 688), Vector2(688, 812), Vector2(512, 812), Vector2(388, 688),
	Vector2(387, 512), Vector2(512, 388), Vector2(688, 387), Vector2(812, 512),
]


# PLACEMENT IS VALIDATED, NOT EYEBALLED. I hand-typed the scattered braziers and
# one landed on a house roof - which is precisely what the project's own rule
# about generated-and-validated placement exists to prevent. Every candidate is
# now checked against the full house footprint (not just its solid lower half,
# because the ROOF is drawn above that and a torch in front of it looks like a
# torch growing out of it), against tree canopies, and against the wall band.
static func braziers() -> Array:
	var out: Array = []
	for b in BRAZIER_CORE:
		out.append(b)
	for b in BRAZIER_EXTRA:
		if _brazier_ok(b[0], b[1]):
			out.append(b)
	return out


static func _brazier_ok(x: float, y: float) -> bool:
	# clear of the wall band, with room for the pole
	if x < WALL_IN + 20 or y < WALL_IN + 44 or x > WORLD - WALL_IN - 20 or y > WORLD - WALL_IN - 20:
		return false
	# a torch is ~44px tall, so it must clear the whole house it stands near -
	# roof included, plus that height above it
	for h in HOUSES:
		if x > h[0] - 14 and x < h[0] + h[2] + 14 and y > h[1] - 12 and y < h[1] + h[3] + 20:
			return false
	for t in TREES:
		if abs(x - t[0]) < 26 and y > t[1] - 60 and y < t[1] + 14:
			return false
	for s in STONES:
		if abs(x - s[0]) < s[2] + 22 and abs(y - s[1]) < s[2] + 22:
			return false
	for g in GRAVES:
		if abs(x - g[0]) < 20 and abs(y - g[1]) < 24:
			return false
	return true


static func fences() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in 8:
		out.append(Vector2(700 + i * 19, 760))
	return out


# The 520 scattered tufts, rocks, puddles and bones. Generated by the SAME rng
# sequence as the original, so these land in the same places rather than merely
# similar ones - which is why Rng32 had to be bit-exact first.
#
# Note the draw order dependency: a candidate that falls inside a house is
# skipped with `continue` BEFORE its type and variation are rolled, so those two
# calls do not happen for it. Getting that wrong desynchronises everything after.
static func build_props() -> Array:
	var out: Array = []
	var r := Rng32.new(1337)
	for i in 520:
		var x := r.next() * WORLD
		var y := r.next() * WORLD
		var inside := false
		for h in HOUSES:
			if x > h[0] - 8 and x < h[0] + h[2] + 8 and y > h[1] - 8 and y < h[1] + h[3] + 8:
				inside = true
				break
		if inside:
			continue
		var k := r.next()
		var kind := "tuft" if k < 0.46 else ("rock" if k < 0.74 else ("puddle" if k < 0.90 else "bone"))
		out.append({"x": x, "y": y, "t": kind, "r": r.next()})
	return out


# Built the same way and in the same order as the HTML `solids` array. Houses
# are solid over their LOWER 58% only, which is what lets you walk behind them.
static func build_solids() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for h in HOUSES:
		out.append(Rect2(h[0], h[1] + h[3] * 0.42, h[2], h[3] * 0.58))
	for t in TREES:
		out.append(Rect2(t[0] - 8, t[1] - 6, 16, 12))
	for s in STONES:
		out.append(Rect2(s[0] - s[2], s[1] - s[2] * 0.6, s[2] * 2, s[2] * 1.2))
	for b in braziers():
		out.append(Rect2(b[0] - 4, b[1] - 4, 8, 7))
	return out
