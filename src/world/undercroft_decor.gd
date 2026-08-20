extends Node2D

## What the undercroft is FULL of - the thing that gives it its feel and that a
## bare room has none of. Ported from the HTML's drawDecor: smashed crates and
## staved-in barrels along the walls, bone piles and skulls and rubble across the
## floor, cobwebs strung in the corners, chains hanging from the dark and swaying,
## and water dripping out of the ceiling to break on the stone. Drawn before the
## lighting composite, so all of it lives in the dark and the lamp finds it.

const DECOR := [
	# crates and barrels line the walls, top and bottom
	["crate", 80, 96], ["crate2", 210, 92], ["barrel", 340, 94], ["barrel", 520, 96],
	["crate", 680, 92], ["crate2", 830, 96], ["barrel", 980, 100], ["crate", 1030, 94],
	["barrel", 128, 356], ["crate", 300, 360], ["crate2", 470, 356], ["barrel", 640, 360],
	["crate", 810, 358], ["barrel", 980, 356], ["crate2", 1050, 352],
	# bones, skulls and rubble scattered right across the floor you walk
	["bones", 150, 150], ["skull", 250, 200], ["rubble", 360, 168], ["bones", 300, 250],
	["skull", 440, 230], ["rubble", 520, 180], ["bones", 470, 300], ["skull", 600, 260],
	["rubble", 680, 200], ["bones", 640, 310], ["skull", 760, 175], ["rubble", 820, 250],
	["bones", 900, 210], ["skull", 960, 290], ["rubble", 1000, 180], ["bones", 1060, 250],
	["rubble", 200, 300], ["skull", 380, 330], ["bones", 560, 340], ["rubble", 720, 330],
	["skull", 880, 340], ["bones", 1040, 310], ["rubble", 120, 230],
	# cobwebs in the corners, chains hanging from the dark
	["web", 46, 74], ["web", 1054, 74], ["web", 340, 66], ["web", 760, 68],
	["chain", 200, 62], ["chain", 400, 62], ["chain", 620, 62], ["chain", 880, 62],
]

var _drips: Array = []
var _drip_t := 0.0
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	_drip_t -= delta
	if _drip_t <= 0.0:
		_drip_t = 0.25 + randf() * 0.6
		_drips.append({"x": 100.0 + randf() * 900.0, "y": 44.0, "vy": 0.0, "land": 300.0 + randf() * 90.0, "splash": 0.0})
	for i in range(_drips.size() - 1, -1, -1):
		var dr = _drips[i]
		if dr.splash > 0.0:
			dr.splash -= delta * 5.0
			if dr.splash <= 0.0:
				_drips.remove_at(i)
		else:
			dr.vy += 420.0 * delta
			dr.y += dr.vy * delta
			if dr.y >= dr.land:
				dr.splash = 1.0
	queue_redraw()


func _draw() -> void:
	for i in DECOR.size():
		var it = DECOR[i]
		_decor(String(it[0]), float(it[1]), float(it[2]), i * 13 + 9)
	# water drips and their splashes
	for dr in _drips:
		var sp: float = dr.splash
		var dx: float = dr.x
		var land: float = dr.land
		if sp > 0.0:
			var a := sp * 0.5
			draw_rect(Rect2(dx - 2.0, land, 4, 1), Color(0.55, 0.62, 0.72, a), true)
			draw_rect(Rect2(dx - 4.0 * (1.0 - sp), land - 1.0, 1, 1), Color(0.5, 0.58, 0.68, a), true)
			draw_rect(Rect2(dx + 4.0 * (1.0 - sp), land - 1.0, 1, 1), Color(0.5, 0.58, 0.68, a), true)
		else:
			draw_rect(Rect2(dx, dr.y, 1, 3), Color(0.6, 0.68, 0.78, 0.6), true)


func _decor(kind: String, x: float, y: float, seed_i: int) -> void:
	var rr := Rng32.new(seed_i)
	var R := func(px, py, w, h, c): draw_rect(Rect2(roundf(px), roundf(py), w, h), c, true)
	match kind:
		"crate", "crate2":
			var w := 20.0 if kind == "crate" else 16.0
			var h := 17.0 if kind == "crate" else 14.0
			R.call(x - w / 2.0, y - 1, w, 4, Color(0, 0, 0, 0.45))
			R.call(x - w / 2.0, y - h, w, h, Color("39291a"))
			R.call(x - w / 2.0, y - h, w, 3, Color("4a3722"))
			R.call(x - w / 2.0, y - h, 3, h, Color("43311e"))
			R.call(x + w / 2.0 - 3, y - h, 3, h, Color("2b1e12"))
			R.call(x - w / 2.0, y - 3, w, 3, Color("241a10"))
			R.call(x - w / 2.0 + 1, y - h + 4, w - 2, 2, Color("4f3b24"))
			R.call(x - w / 2.0 + 1, y - 8, w - 2, 2, Color("4f3b24"))
			for j in range(1, 3):
				R.call(x - w / 2.0 + j * w / 3.0, y - h + 2, 1, h - 4, Color("2b1e12"))
			R.call(x - w / 2.0 + 2, y - h + 2, 2, 2, Color("5c4629"))
			if kind == "crate2":
				R.call(x - w / 2.0 + 3, y - h - 3, w - 6, 4, Color("332417"))
				R.call(x - w / 2.0 + 3, y - h - 3, w - 6, 1, Color("453220"))
		"barrel":
			R.call(x - 8, y - 1, 17, 4, Color(0, 0, 0, 0.45))
			R.call(x - 7, y - 21, 15, 21, Color("3d2c1b"))
			R.call(x - 7, y - 21, 4, 21, Color("4a3722"))
			R.call(x + 5, y - 21, 3, 21, Color("2b1e12"))
			R.call(x - 8, y - 18, 17, 3, Color("5e5040"))
			R.call(x - 8, y - 9, 17, 3, Color("5e5040"))
			R.call(x - 8, y - 18, 17, 1, Color("736450"))
			R.call(x - 8, y - 9, 17, 1, Color("736450"))
			R.call(x - 6, y - 23, 13, 3, Color("4a3722"))
			R.call(x - 6, y - 23, 13, 1, Color("5c4629"))
		"web":
			var c1 := Color(0.745, 0.769, 0.80, 0.20)
			var c2 := Color(0.824, 0.847, 0.878, 0.30)
			for k in 5:
				var a := -PI * 0.5 + (k - 2) * 0.34
				var r2 := 3.0
				while r2 < 20.0:
					R.call(x + cos(a) * r2, y + sin(a) * r2 * 0.8, 1, 1, c1)
					r2 += 1.0
			var ring := 6.0
			while ring < 20.0:
				var a := -PI * 0.5 - 0.72
				while a <= -PI * 0.5 + 0.72:
					R.call(x + cos(a) * ring, y + sin(a) * ring * 0.8, 1, 1, c2)
					a += 0.08
				ring += 5.0
		"chain":
			var sway := sin(t * 0.6 + seed_i) * 0.8
			var ln := 16 + int(rr.next() * 10.0)
			for k in ln:
				var ox := sin(t * 0.5 + seed_i + k * 0.2) * 0.5 + sway * (float(k) / ln)
				R.call(x + ox, y - ln * 2 + k * 2, 3, 1, Color("4a4640") if k % 2 else Color("5e5951"))
				R.call(x + ox, y - ln * 2 + k * 2 + 1, 1, 1, Color("332f2b"))
			R.call(x - 1, y - ln * 2 - 3, 5, 3, Color("4a4640"))
			R.call(x - 1, y - ln * 2 - 3, 5, 1, Color("6b6459"))
		"bones":
			R.call(x - 9, y - 1, 19, 3, Color(0, 0, 0, 0.35))
			R.call(x - 8, y - 4, 11, 3, Color("9c9076"))
			R.call(x - 8, y - 4, 11, 1, Color("c2b697"))
			R.call(x - 9, y - 5, 3, 4, Color("a89c80")); R.call(x + 2, y - 5, 3, 4, Color("a89c80"))
			R.call(x + 1, y - 7, 9, 3, Color("9c9076"))
			R.call(x + 1, y - 7, 9, 1, Color("b8ac8e"))
			R.call(x - 4, y - 8, 3, 3, Color("8a8068"))
		"skull":
			R.call(x - 6, y - 1, 13, 3, Color(0, 0, 0, 0.4))
			R.call(x - 5, y - 10, 11, 8, Color("c2b697"))
			R.call(x - 5, y - 10, 4, 8, Color("dcd0b2"))
			R.call(x - 4, y - 8, 3, 3, Color("0d0c0a"))
			R.call(x + 1, y - 8, 3, 3, Color("0d0c0a"))
			R.call(x - 1, y - 5, 2, 2, Color("0d0c0a"))
			R.call(x - 4, y - 3, 9, 3, Color("a89c80"))
			for k in 4:
				R.call(x - 4 + k * 2.4, y - 3, 1, 3, Color("7c745f"))
		_:
			R.call(x - 10, y - 1, 21, 3, Color(0, 0, 0, 0.35))
			for k in 7:
				var a := rr.next()
				var b := rr.next()
				R.call(x - 9 + a * 18, y - 3 - b * 6, 3 + a * 3, 2 + b * 2, Color("2a2720") if a > 0.5 else Color("211f1a"))
				R.call(x - 9 + a * 18, y - 3 - b * 6, 3 + a * 2, 1, Color("35322a"))
