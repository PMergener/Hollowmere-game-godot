class_name FallenHunter
extends Enemy

## Elphric. A knight of your own Order, sent before you and kept by whatever is
## down here. He wears the player's silhouette - the same hood, the same belt -
## and the only difference is the colour burning in the hood: green, not red.
## The slowest stride of anything that walks, the longest reach, and a green flare
## as he commits to a swing that is the whole of the fight to read. He carries a
## named health bar.

const CRESCENT := Color("c9b06a")


func _ready() -> void:
	super()
	max_hp = 165.0
	hp = 165.0
	xp_reward = 0          # he is a story beat, not a source of levels
	ember_reward = 0
	enemy_id = &"fallen_hunter"
	body_radius = 9.0
	chase_speed = 30.0      # the slowest stride in the game
	attack_range = 28.0     # the longest reach
	attack_windup = 0.368
	attack_recover = 0.30
	attack_cooldown = 1.52
	damage_min = 44
	damage_max = 67
	hostile = true         # aware the moment you enter his hall - the bar shows
	add_to_group(&"boss")


func melee_hit_offset() -> float:
	return 18.0


func _on_attack_land() -> void:
	Sfx.play(&"hit")


func _draw() -> void:
	# the player's hooded body, but green-eyed; the eyes flare brighter through the
	# wind-up - that is the tell.
	var off := lunge_offset()
	Figure.draw_body(self, facing, step * 9.0, moving, Figure.PAL_PLAYER,
		{"eyes": "hunter"}, t, off)
	draw_set_transform(off, 0.0, Vector2.ONE)   # crest and blade lunge with him

	var by := -1.0 if (moving and sin(step * 18.0) > 0.4) else 0.0
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)

	# the Order's waning crescent on his chest, pulsing
	var cp := 0.6 + 0.4 * sin(t * 2.0)
	var cc := Color(CRESCENT.r * cp, CRESCENT.g * cp, CRESCENT.b * cp)
	R.call(-2, by - 15, 3, 1, cc)
	R.call(-3, by - 14, 2, 3, cc)
	R.call(-2, by - 11, 3, 1, cc)

	# a long straight order blade; hangs at rest, winds overhead as swing rises
	var ang := lerpf(2.2, -1.25, swing)
	var hx := 7.0
	var hy := by - 16.0
	var cs := cos(ang)
	var sn := sin(ang)
	R.call(hx - 1, hy - 1, 3, 4, Color("2a2d38"))   # gauntlet
	var blen := 22.0                                 # the longest reach in the game
	var j := 2.0
	while j <= blen:
		var near := j > blen - 2.0
		R.call(hx + cs * j, hy + sn * j, 1, 2, Color("eef3f7") if near else Color("b6c0c9"))
		j += 1.0
	R.call(hx + cs * 1.5 - 1, hy + sn * 1.5, 3, 2, Color("6a5a3e"))

	# when he commits, a green flare over the hood
	if swing > 0.4:
		var g := (swing - 0.4) / 0.6
		R.call(-3, by - 24, 2, 2, Color(0.3, 1.0, 0.5, g))
		R.call(1, by - 24, 2, 2, Color(0.3, 1.0, 0.5, g))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
