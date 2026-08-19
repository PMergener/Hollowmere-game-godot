# The village floor: ground tiles, the 520 scattered props, the graveyard, the
# fence line, and the stone wall with its north gate.
#
# All of it static, so it is drawn ONCE into a cached _draw() rather than every
# frame. The HTML build redraws the whole ground every frame because a canvas has
# no choice; here it costs nothing after the first pass. That is a real win the
# port gets for free.
extends Node2D

var props: Array = []


func _ready() -> void:
	props = WorldData.build_props()


func _draw() -> void:
	_draw_tiles()
	_draw_props()
	for g in WorldData.GRAVES:
		_draw_grave(g[0], g[1])
	for f in WorldData.fences():
		_draw_fence(f.x, f.y)
	_draw_wall()


func _draw_tiles() -> void:
	var t := int(WorldData.TILE)
	var w := int(WorldData.WORLD)
	for y in range(0, w, t):
		for x in range(0, w, t):
			var rr := Rng32.new((x * 73856093) ^ (y * 19349663))
			var r := rr.next()
			var road := Vector2(x - 600, y - 600).length() < 250.0
			var c: Color
			if road:
				c = Color("211e19") if r < 0.5 else (Color("1d1a16") if r < 0.8 else Color("252119"))
			else:
				c = Color("15130f") if r < 0.5 else (Color("181611") if r < 0.8 else Color("131109"))
			draw_rect(Rect2(x, y, t, t), c, true)
			for k in range(3):
				var a := rr.next()
				var b := rr.next()
				if a > 0.62:
					draw_rect(Rect2(x + a * t, y + b * t, 2, 1),
						Color("191612") if road else Color("0f0d09"), true)
			if r > 0.955:
				draw_rect(Rect2(x + int(r * 17), y + (int(r * 23) % 18), 4, 3), Color("0e0c09"), true)


func _draw_props() -> void:
	for p in props:
		var x: float = p.x
		var y: float = p.y
		match p.t:
			"tuft":
				draw_rect(Rect2(x, y - 4, 1, 5), Color("20200f"), true)
				draw_rect(Rect2(x + 2, y - 3, 1, 4), Color("1c1d0e"), true)
				draw_rect(Rect2(x - 2, y - 2, 1, 3), Color("232310"), true)
			"rock":
				draw_rect(Rect2(x, y, 5, 3), Color("242219"), true)
				draw_rect(Rect2(x, y, 4, 1), Color("2f2c22"), true)
				draw_rect(Rect2(x + 1, y + 2, 3, 1), Color("191710"), true)
			"puddle":
				draw_rect(Rect2(x - 3, y, 10, 4), Color("101820"), true)
				draw_rect(Rect2(x - 2, y, 7, 2), Color("16222c"), true)
				draw_rect(Rect2(x, y + 1, 3, 1), Color("1d2c38"), true)
			_:
				draw_rect(Rect2(x, y, 6, 1), Color("3a3730"), true)
				draw_rect(Rect2(x + 1, y - 2, 1, 2), Color("3a3730"), true)
				draw_rect(Rect2(x + 4, y - 1, 1, 1), Color("332f28"), true)


func _draw_grave(x: float, y: float) -> void:
	draw_rect(Rect2(x - 5, y, 12, 4), Color(0, 0, 0, 0.4), true)
	draw_rect(Rect2(x - 5, y - 14, 10, 15), Color("2a2823"), true)
	draw_rect(Rect2(x - 5, y - 17, 10, 3), Color("33302a"), true)
	draw_rect(Rect2(x - 4, y - 16, 1, 2), Color("3a372f"), true)
	draw_rect(Rect2(x - 3, y - 11, 1, 6), Color("1a1815"), true)
	draw_rect(Rect2(x - 1, y - 9, 4, 1), Color("1a1815"), true)


func _draw_fence(x: float, y: float) -> void:
	draw_rect(Rect2(x, y - 17, 3, 18), Color("1b1710"), true)
	draw_rect(Rect2(x, y - 17, 1, 18), Color("231e15"), true)
	draw_rect(Rect2(x - 1, y - 14, 20, 2), Color("1b1710"), true)
	draw_rect(Rect2(x - 1, y - 8, 20, 2), Color("171308"), true)


# The wall runs just OUTSIDE the walkable line, so it needs no collision of its
# own - blocked() already refuses anything past 36px from the edge.
func _draw_wall() -> void:
	var IN := WorldData.WALL_IN
	var T := WorldData.WALL_T
	var OUT := IN - T
	var WORLD := WorldData.WORLD
	var gate_x := 600.0 - WorldData.GATE_W / 2.0

	# north, split around the gate
	_course(0, OUT, gate_x, T)
	_course(gate_x + WorldData.GATE_W, OUT, WORLD - (gate_x + WorldData.GATE_W), T)
	# south
	_course(0, WORLD - IN, WORLD, T)
	# west and east
	_band(OUT, 0, T, WORLD)
	_band(WORLD - IN, 0, T, WORLD)
	# corner towers, so the corners do not read as a mitre joint
	for c in [[OUT, OUT], [WORLD - IN, OUT], [OUT, WORLD - IN], [WORLD - IN, WORLD - IN]]:
		draw_rect(Rect2(c[0] - 3, c[1] - 3, T + 6, T + 6), WorldData.WALL_M, true)
		draw_rect(Rect2(c[0] - 3, c[1] - 3, T + 6, 2), WorldData.WALL_H, true)
		draw_rect(Rect2(c[0] - 3, c[1] + T + 1, T + 6, 2), Color("141210"), true)
	_draw_north_gate(gate_x, OUT, WorldData.GATE_W, T)


func _course(wx: float, wy: float, w: float, h: float) -> void:
	if w <= 0:
		return
	draw_rect(Rect2(wx, wy, w, h), WorldData.WALL_M, true)
	var rows := int(ceil(h / 10.0))
	for r in rows:
		var ry := wy + r * 10
		for i in range(int(ceil(w / 22.0)) + 1):
			var bx := wx + i * 22 - (11 if r % 2 else 0)
			var rr := Rng32.new((int(wx + i * 37) * 73856093) ^ (int(wy + r * 17) * 19349663))
			var v := rr.next()
			var bw: float = min(21.0, wx + w - bx)
			if bw <= 0:
				continue
			var col := WorldData.WALL_D if v < 0.34 else (WorldData.WALL_M if v < 0.68 else WorldData.WALL_L)
			draw_rect(Rect2(max(wx, bx), ry, bw, 9), col, true)
			draw_rect(Rect2(max(wx, bx), ry, bw, 1), WorldData.WALL_H, true)
		draw_rect(Rect2(wx, ry + 9, w, 1), Color("141210"), true)
	draw_rect(Rect2(wx, wy + h - 3, w, 3), WorldData.WALL_L, true)
	draw_rect(Rect2(wx, wy + h - 3, w, 1), WorldData.WALL_H, true)
	for i in 7:
		draw_rect(Rect2(wx, wy + h + i, w, 1), Color(0, 0, 0, (1.0 - i / 7.0) * 0.44), true)


func _band(wx: float, wy: float, w: float, h: float) -> void:
	draw_rect(Rect2(wx, wy, w, h), WorldData.WALL_M, true)
	for r in range(int(ceil(h / 10.0))):
		var ry := wy + r * 10
		var rr := Rng32.new((int(wx) * 7919) ^ (int(wy + r * 10) * 104729))
		var v := rr.next()
		var col := WorldData.WALL_D if v < 0.34 else (WorldData.WALL_M if v < 0.68 else WorldData.WALL_L)
		draw_rect(Rect2(wx, ry, w, 9), col, true)
		draw_rect(Rect2(wx, ry, w, 1), WorldData.WALL_H, true)
		draw_rect(Rect2(wx, ry + 9, w, 1), Color("141210"), true)


# Shut, banded and studded. The open state belongs to the quest chain and is not
# ported yet - the Godot slice has no quests.
func _draw_north_gate(x: float, y: float, w: float, h: float) -> void:
	for side in 2:
		var half := w / 2.0
		var lx := x + side * half
		draw_rect(Rect2(lx + 1, y, half - 2, h), Color("3a2b19"), true)
		for p in range(int(ceil(half / 9.0))):
			var px := lx + 2 + p * 9
			draw_rect(Rect2(px, y, 8, h), Color("42311d") if p % 2 else Color("372817"), true)
			draw_rect(Rect2(px, y, 8, 1), Color("503b23"), true)
			draw_rect(Rect2(px + 7, y, 1, h), Color("241a0e"), true)
		for by in [y + 5, y + h - 11]:
			draw_rect(Rect2(lx + 1, by, half - 2, 4), Color("2c2f33"), true)
			draw_rect(Rect2(lx + 1, by, half - 2, 1), Color("434850"), true)
			for s in 3:
				draw_rect(Rect2(lx + 6 + s * max(8.0, (half - 14) / 2.0), by + 1, 2, 2), Color("5c636c"), true)
		var hx := (lx + 4) if side else (lx + half - 8)
		draw_rect(Rect2(hx, y + h / 2.0 - 2, 4, 4), Color("2c2f33"), true)
		draw_rect(Rect2(hx + 1, y + h / 2.0 - 1, 2, 2), Color("0d0f11"), true)
	# stone jambs either side
	for j in [[x - 14, Color("343029")], [x + w - 2, Color("2a2723")]]:
		draw_rect(Rect2(j[0], y - 6, 16, h + 10), j[1], true)
		draw_rect(Rect2(j[0], y - 6, 16, 2), WorldData.WALL_H, true)
		for r in 4:
			draw_rect(Rect2(j[0], y - 6 + r * 10, 16, 1), Color("141210"), true)
	draw_rect(Rect2(x - 14, y - 14, w + 28, 9), WorldData.WALL_L, true)
	draw_rect(Rect2(x - 14, y - 14, w + 28, 2), WorldData.WALL_H, true)
	draw_rect(Rect2(x - 14, y - 6, w + 28, 2), Color("141210"), true)
