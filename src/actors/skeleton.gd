class_name Skeleton
extends Enemy

## The undercroft swordsman, matched to the HTML's drawSkeleton: the SHARED figure
## (Nestor's body and walk cycle) in a warm cream bone palette, with the bone detail
## the reference calls for laid over its pixels - a ribcage of dark grooves, a skull
## with deep sockets, a nasal notch and a row of teeth, a dark-green cap of a helm,
## and a straight fullered arming sword with a wrapped grip. The eye-lights gutter
## out the instant it is struck. Behaviour is the shared chase-and-lunge brain.

const BONE := Color("ded0ab")
const BONE_HI := Color("f2e9cf")
const BONE_MID := Color("bda882")
const BONE_LO := Color("8a765a")
const HELM := Color("33443a")
const HELM_HI := Color("4c6152")
const HELM_LO := Color("1e2a23")

var _seed := 0.0


func _ready() -> void:
	super()
	max_hp = 25.0
	hp = 25.0
	xp_reward = 12
	ember_reward = 5
	enemy_id = &"skeleton"
	body_radius = 7.0
	chase_speed = 52.0
	attack_range = 22.0
	attack_windup = 0.32
	attack_recover = 0.22
	attack_cooldown = 2.2
	damage_min = 28
	damage_max = 40
	_seed = randf() * TAU


func _on_attack_land() -> void:
	Sfx.play(&"hit")
	Sfx.play(&"bone", -3.0)


func _draw() -> void:
	var flash := hurt > 0.0
	var pal := {
		"cloak": Color("e8bcae") if flash else BONE,
		"hi": Color("ffe2d8") if flash else BONE_HI,
		"lo": Color("a87464") if flash else BONE_LO,
		"trim": Color("8a5040") if flash else BONE_LO,
		"skin": Color("d8ac9e") if flash else BONE_MID,
		"fold": Color("c09484") if flash else BONE_MID,
	}
	var phase := step * 7.0
	var off := lunge_offset()
	Figure.draw_body(self, facing, phase, moving, pal, {"eyes": ""}, t, off)
	draw_set_transform(off, 0.0, Vector2.ONE)   # bone detail + sword lunge with him

	var bob := 1.0 if (moving and sin(phase * 2.0) > 0.4) else 0.0
	var by := -bob
	var side := facing == 2 or facing == 3
	var fc := 1.0 if facing == 3 else (-1.0 if facing == 2 else 0.0)
	var dk := Color("5e2418") if flash else Color("141110")     # the gaps between bones
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)

	# ---- ribs: dark grooves across the torso block, sternum and pelvis line
	var tw := 9.0 if side else 12.0
	var tx := -4.0 if side else -6.0
	for i in 4:
		R.call(tx + 1, by - 16 + i * 3, tw - 2, 1, dk)
	R.call(-1, by - 17, 2, 11, pal.fold)
	R.call(tx + 1, by - 7, tw - 2, 1, dk)

	# ---- the skull over the face the figure laid down; lights go OUT when struck
	if facing != 1:
		var lit := 0.0 if flash else 1.0
		var gl := (0.72 + 0.28 * sin(t * 2.4 + _seed)) * lit
		var eye := Color(224.0 * gl / 255.0, 52.0 * gl / 255.0, 44.0 * gl / 255.0) if lit > 0.0 else Color("140b0a")
		if side:
			var ex := 3.0 if fc > 0 else -5.0
			R.call(ex, by - 23, 3, 3, Color("0a0607"))
			R.call(ex, by - 22, 3, 2, eye)
			if lit > 0.0:
				R.call(ex, by - 22, 1, 2, Color("ffb4a8"))
			R.call(2.0 if fc > 0 else -5.0, by - 19, 4, 2, pal.hi)      # jaw
		else:
			for sx: float in [-4.0, 1.0]:
				R.call(sx, by - 23, 3, 3, Color("0a0607"))             # deep socket
				R.call(sx, by - 22, 3, 2, eye)
				if lit > 0.0:
					R.call(sx, by - 22, 1, 2, Color("ffb4a8"))          # inner glint
			R.call(-1, by - 23, 2, 3, pal.hi)                          # bone between sockets
			R.call(-1, by - 20, 2, 1, Color("0a0607"))                 # nasal
			R.call(-4, by - 19, 8, 2, pal.hi)                          # teeth
			for i in 4:
				R.call(-3 + i * 2, by - 19, 1, 2, dk)                  # tooth gaps

	# ---- helm: a dark-green cap over the top of the head, with a nose guard
	R.call(-6, by - 30, 12, 4, HELM)
	R.call(-6, by - 30, 12, 1, HELM_HI)
	R.call(-6, by - 27, 12, 1, HELM_LO)
	R.call(-7, by - 29, 1, 5, HELM_LO)
	R.call(6, by - 29, 1, 5, HELM_LO)
	if not side:
		R.call(-1, by - 26, 2, 4, HELM)                               # nose guard

	# ---- the sword, in the held hand, winding up then falling
	var hx := 6.0 if facing == 0 else (-6.0 if facing == 1 else fc * 6.0)
	var hy := by - 13.0
	var ang := lerpf(PI / 2.0, -1.6, swing)   # hangs straight down at rest (SKEL_REST_ANG), over the head at full wind
	_draw_sword(R, hx, hy, ang, flash)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Ported from drawSkelSword: a fist on the grip, a wrapped brown grip, a flat
# crossguard, and a parallel-edged steel blade with a short fuller.
func _draw_sword(R: Callable, cx: float, cy: float, ang: float, flash: bool) -> void:
	var cs := cos(ang)
	var sn := sin(ang)
	var nx := -sn
	var ny := cs
	var b2 := Color("ffd8d0") if flash else BONE
	var bh2 := Color("ffeae4") if flash else BONE_HI
	for i in range(1, 4):
		R.call(cx + cs * i - 1, cy + sn * i - 1, 3, 3, b2 if i < 3 else bh2)   # fist
	for i in range(4, 8):
		R.call(cx + cs * i - 1, cy + sn * i - 1, 2, 2, Color("4a3221") if i % 2 else Color("5c3f28"))
	for g in range(-3, 4):
		R.call(cx + cs * 8 + nx * g, cy + sn * 8 + ny * g, 1, 1,
			Color("8a8478") if absi(g) < 2 else Color("5e5a50"))            # crossguard
	for i in range(9, 17):
		var near := i > 15
		R.call(cx + cs * i, cy + sn * i, 1, 1,
			Color("ffd8d0") if flash else (Color("e6ecf0") if near else Color("c2c8cc")))
		if i < 16:
			R.call(cx + cs * i + nx, cy + sn * i + ny, 1, 1, Color("e8b0a4") if flash else Color("9aa0a4"))
		if i < 14:
			R.call(cx + cs * i - nx, cy + sn * i - ny, 1, 1, Color("ffeae4") if flash else Color("7f858a"))
