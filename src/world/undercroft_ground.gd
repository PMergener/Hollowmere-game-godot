extends Node2D

## The undercroft floor and walls, drawn once into a cached _draw. Wet limestone:
## a dark stone floor with occasional specular glints and cracks, ringed by a band
## of dressed block courses with an ambient-occlusion shadow raking in from the top
## and sides - which is what makes the border read as walls rather than a frame.

var area_w := 1100.0
var area_h := 420.0
var wall := 30.0


func _draw() -> void:
	_floor()
	_walls()
	_ao()


func _floor() -> void:
	var tile := 24
	var y := 0
	while y < int(area_h):
		var x := 0
		while x < int(area_w):
			var rr := Rng32.new((x * 73856093) ^ (y * 19349663))
			var r := rr.next()
			var c := Color("14161a") if r < 0.5 else (Color("171a1e") if r < 0.8 else Color("101216"))
			draw_rect(Rect2(x, y, tile, tile), c, true)
			if rr.next() > 0.72:  # a wet glint on the lower edge of a slab
				draw_rect(Rect2(x + 2 + int(r * 8), y + tile - 2, 5, 1), Color("2c333c"), true)
			if r > 0.94:  # a crack
				draw_rect(Rect2(x + int(r * 15), y + 4, 1, 8), Color("0a0b0e"), true)
			x += tile
		y += tile


func _walls() -> void:
	var courses := [Color("34322c"), Color("434039"), Color("54514a")]
	# top and bottom bands
	for band_y in [0.0, area_h - wall]:
		var ry: float = band_y
		while ry < band_y + wall:
			var i := 0
			while i * 22 < area_w:
				var bx := i * 22 - (11 if int(ry / 10) % 2 else 0)
				var rr := Rng32.new((int(bx) * 7919) ^ (int(ry) * 104729))
				var v := rr.next()
				draw_rect(Rect2(bx, ry, 21, 9), courses[0] if v < 0.34 else (courses[1] if v < 0.68 else courses[2]), true)
				draw_rect(Rect2(bx, ry, 21, 1), Color("6a675e"), true)
				i += 1
			draw_rect(Rect2(0, ry + 9, area_w, 1), Color("141210"), true)
			ry += 10
	# left and right bands
	for band_x in [0.0, area_w - wall]:
		draw_rect(Rect2(band_x, 0, wall, area_h), Color("3a3730"), true)
		var ry := 0.0
		while ry < area_h:
			var rr := Rng32.new((int(band_x) * 31) ^ (int(ry) * 97))
			var v := rr.next()
			draw_rect(Rect2(band_x, ry, wall, 9), courses[0] if v < 0.4 else courses[1], true)
			draw_rect(Rect2(band_x, ry, wall, 1), Color("57544c"), true)
			ry += 10


func _ao() -> void:
	# a shadow band raking down from the top wall and in from the sides
	for i in 16:
		var a := (1.0 - i / 16.0) * 0.5
		draw_rect(Rect2(wall, wall + i, area_w - wall * 2, 1), Color(0, 0, 0, a), true)
	for i in 10:
		var a := (1.0 - i / 10.0) * 0.42
		draw_rect(Rect2(wall + i, wall, 1, area_h - wall * 2), Color(0, 0, 0, a), true)
		draw_rect(Rect2(area_w - wall - i, wall, 1, area_h - wall * 2), Color(0, 0, 0, a), true)
		draw_rect(Rect2(wall, area_h - wall - i, area_w - wall * 2, 1), Color(0, 0, 0, a), true)
