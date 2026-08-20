class_name Zombie
extends Enemy

## The undercroft's other undead - a MAN-SIZED walking corpse, not a green
## scarecrow. Built the way the HTML's drawZombie settled on: the SHARED figure in
## a rot-green palette, with rot laid over its pixels - a split flank with two ribs
## showing, a torn shoulder, a sagging jaw the mouth has fallen out of, and BOTH
## arms thrown forward on the lunge, which is his whole attack read. Half the
## skeleton's stride (step*3.4) so the slow cadence tells them apart at a glance.

const ZOM := Color("54762c")
const ZOM_HI := Color("7a9c42")
const ZOM_LO := Color("3a5220")
const ZOM_D := Color("28381a")
const ZOM_SK := Color("8aa84a")


func _ready() -> void:
	super()
	max_hp = 35.0
	hp = 35.0
	xp_reward = 16
	ember_reward = 5
	enemy_id = &"zombie"
	body_radius = 8.0
	chase_speed = 26.0        # half the skeleton's stride - it has no hurry
	attack_range = 22.0
	attack_windup = 0.95      # a long, readable tell
	attack_recover = 0.30
	attack_cooldown = 3.1
	damage_min = 45
	damage_max = 60


func _on_attack_land() -> void:
	Sfx.play(&"hit")


func _draw() -> void:
	var flash := hurt > 0.0
	var pal := {
		"cloak": Color("c8e07a") if flash else ZOM,
		"hi": Color("e0f4a0") if flash else ZOM_HI,
		"lo": Color("8aa050") if flash else ZOM_LO,
		"trim": Color("6a7c3a") if flash else Color("3f4a24"),
		"skin": Color("d8f0a8") if flash else ZOM_SK,
		"fold": Color("a8c060") if flash else ZOM_LO,
		"tunic": Color("8c9a4e") if flash else Color("43542a"),   # sodden rags over the rot
		"hand": Color("d8f0a8") if flash else ZOM_SK,
	}
	var phase := step * 3.4      # slow, heavy cadence
	var off := lunge_offset()
	Figure.draw_body(self, facing, phase, moving, pal, {"eyes": "rot"}, t, off)
	draw_set_transform(off, 0.0, Vector2.ONE)

	var sw := sin(phase) if moving else 0.0
	var bob := 1.0 if (moving and sin(phase * 2.0) > 0.4) else 0.0
	var by := -bob
	var side := facing == 2 or facing == 3
	var fc := 1.0 if facing == 3 else (-1.0 if facing == 2 else 0.0)
	var arm_f := fc if side else (1.0 if facing == 0 else -1.0)
	var rot := Color("7a3a2a") if flash else Color("2a1410")   # the colour of an open wound
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)

	# ---- the drag: the figure walks him evenly, this trails one foot
	if moving and sw < -0.2:
		var dx := (-2.0 - fc * 3.0) if side else -5.0
		R.call(dx, by - 2, 5, 2, Color("1b2410"))
		R.call(dx - 2, by - 1, 4, 1, Color(0, 0, 0, 0.35))

	# ---- split flank, two ribs showing through - the bones are a wound, not worn
	if not side:
		R.call(-3, by - 16, 5, 7, rot)
		R.call(-3, by - 15, 5, 1, Color("b9b39a"))
		R.call(-3, by - 12, 5, 1, Color("b9b39a"))
		R.call(-3, by - 16, 1, 7, Color("8a4030") if flash else Color("3d1c16"))
	else:
		R.call(-1 + fc, by - 15, 3, 5, rot)
		R.call(-1 + fc, by - 14, 3, 1, Color("b9b39a"))
	R.call((-4.0 if side else -6.0), by - 18, 3, 2, rot)      # a torn shoulder

	# ---- sagging jaw: the figure has a face, the rot takes the mouth
	if facing != 1:
		var jx := (3.0 if fc > 0 else -5.0) if side else -3.0
		var jw := 3.0 if side else 6.0
		R.call(jx, by - 19, jw, 2, Color("141a0c"))
		var teeth := 2 if side else 3
		for i in teeth:
			R.call(jx + i * 2, by - 19, 1, 1, Color("b8c88a"))

	# ---- the lunge: BOTH arms thrown forward, the whole of his attack
	if swing > 0.0:
		var reach := roundf(sin(minf(1.0, swing * 1.25) * PI) * 7.0)
		if reach > 0.0:
			var ay := by - 15.0 - roundf(reach * 0.35)
			for base_off: float in [-6.0, 3.0]:
				var sx := base_off + (fc * 2.0 if side else 0.0)
				R.call(sx + arm_f * reach * 0.5, ay, 4, 3, pal.cloak)     # forearm
				R.call(sx + arm_f * reach * 0.5, ay, 4, 1, pal.hi)
				var hxx := sx + arm_f * (reach * 0.5 + 3.0)
				R.call(hxx, ay - 1, 3, 4, pal.skin)                       # the hand
				R.call(hxx + (3.0 if arm_f > 0 else -1.0), ay - 1, 1, 1, Color("1b2410"))  # fingers
				R.call(hxx + (3.0 if arm_f > 0 else -1.0), ay + 2, 1, 1, Color("1b2410"))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
