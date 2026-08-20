extends Node2D

## Ondrick's shop, ported from the HTML's drawShopRoom (not drawHouseRoom, which is
## Herbert's orphaned house - that was the wrong room). A plank floor boxed by
## timber, plank courses along the back wall, four shelves of goods, a WIDE counter
## spanning most of the room with a set of scales and a ledger on it, an intact
## crate and barrel (his stock still works), the doorway at the foot, and a hanging
## lantern at the centre that is the only light in the room and the reason it
## redraws. Room-local: the top-left of the floor is (0,0), matching SHOP_ROOM.

const W := 300.0
const H := 172.0
# from SHOP_SOLIDS, shifted into room-local space (minus SHOP_ROOM origin 50,56)
const COUNTER := Rect2(10, 82, 280, 20)
const CRATE := Rect2(14, 14, 28, 24)
const BARREL := Rect2(250, 130, 26, 22)

var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var R := func(x, y, w, h, c): draw_rect(Rect2(x, y, w, h), c, true)

	# back wall: plank courses standing above the floor
	R.call(-16, -26, W + 32, 28, Color("2b2015"))
	var i := 0
	while i < ceili((W + 32) / 22.0):
		R.call(-16 + i * 22, -26, 20, 26, Color("352616"))
		R.call(-16 + i * 22, -26, 20, 2, Color("43311d"))
		R.call(-16 + i * 22 + 20, -26, 2, 26, Color("1f1609"))
		i += 1
	# side and bottom walls
	R.call(-16, 0, 16, H + 16, Color("281c11"))
	R.call(W, 0, 16, H + 16, Color("281c11"))
	R.call(-16, H, W + 32, 16, Color("221808"))

	# plank floor, 28x11 boards, per-tile hash for the shade
	var wy := 0.0
	while wy < H:
		var wx := 0.0
		while wx < W:
			var rr := Rng32.new(int(wx) * 6151 ^ int(wy) * 8221)
			var r := rr.next()
			var c := Color("40301c") if r < 0.4 else (Color("39291a") if r < 0.75 else Color("48371f"))
			R.call(wx, wy, 28, 11, c)
			R.call(wx, wy, 28, 1, Color("523d24"))
			R.call(wx + 27, wy, 1, 11, Color("281c10"))
			wx += 28.0
		wy += 11.0
	# ambient-occlusion bands, top and sides
	for k in 12:
		R.call(-16, k, W + 32, 1, Color(0, 0, 0, (1.0 - k / 12.0) * 0.5))
	for k in 8:
		R.call(-16 + k, 0, 1, H + 16, Color(0, 0, 0, (1.0 - k / 8.0) * 0.4))
		R.call(W + 15 - k, 0, 1, H + 16, Color(0, 0, 0, (1.0 - k / 8.0) * 0.4))

	# shelves of goods along the back wall
	const GOODS := ["3d4a52", "5c4326", "46503a", "5a3a3a", "4a4436"]
	var shelves := [18.0, 92.0, 188.0, 262.0]
	for si in shelves.size():
		var sx: float = shelves[si]
		var sy := -20.0
		R.call(sx, sy, 62, 3, Color("4a3620"))
		R.call(sx, sy + 3, 62, 2, Color("2a1c10"))
		var rr := Rng32.new(si * 31 + 7)
		for k in 6:
			var bw := 4.0 + floorf(rr.next() * 4.0)
			var bh := 6.0 + floorf(rr.next() * 6.0)
			var c := Color(GOODS[int(rr.next() * 5.0)])
			R.call(sx + 3 + k * 10, sy - bh, bw, bh, c)
			R.call(sx + 3 + k * 10, sy - bh, bw, 1, Color("7a6a52"))

	# the counter, spanning the room
	var cx := COUNTER.position.x
	var cy := COUNTER.position.y
	var cw := COUNTER.size.x
	var ch := COUNTER.size.y
	R.call(cx, cy - 10, cw, ch + 10, Color("3a2a18"))
	R.call(cx, cy - 10, cw, 3, Color("574024"))
	R.call(cx, cy - 7, cw, 2, Color("241a0e"))
	var pi := 0.0
	while pi < cw:
		R.call(cx + pi, cy - 5, 1, ch + 5, Color("2a1e10"))
		pi += 17.0
	R.call(cx, cy + ch - 2, cw, 2, Color("1c1409"))
	# scales and a ledger on the counter
	R.call(cx + 18, cy - 18, 2, 9, Color("6a5a3a"))
	R.call(cx + 12, cy - 20, 15, 2, Color("6a5a3a"))
	R.call(cx + 11, cy - 18, 5, 2, Color("8a7648"))
	R.call(cx + 23, cy - 17, 5, 2, Color("8a7648"))
	R.call(cx + 128, cy - 16, 16, 7, Color("6e6349"))
	R.call(cx + 128, cy - 16, 16, 2, Color("8a7c5c"))

	# an intact crate and barrel - his stock still works
	R.call(CRATE.position.x, CRATE.position.y - 12, CRATE.size.x, CRATE.size.y + 12, Color("4a3720"))
	R.call(CRATE.position.x, CRATE.position.y - 12, CRATE.size.x, 2, Color("5e4728"))
	R.call(CRATE.position.x, CRATE.position.y - 4, CRATE.size.x, 2, Color("2e2113"))
	R.call(BARREL.position.x, BARREL.position.y - 14, BARREL.size.x, BARREL.size.y + 14, Color("3e2e1a"))
	R.call(BARREL.position.x, BARREL.position.y - 14, BARREL.size.x, 3, Color("54401f"))
	R.call(BARREL.position.x, BARREL.position.y - 6, BARREL.size.x, 2, Color("241a0e"))
	R.call(BARREL.position.x, BARREL.position.y + 2, BARREL.size.x, 2, Color("241a0e"))

	# the hanging lantern - a chain from the ceiling, the body, and its glow
	var lx := W / 2.0
	var ly := 30.0
	R.call(lx - 1, -26, 2, ly + 26 - 8, Color("2e2a22"))
	R.call(lx - 5, ly - 8, 11, 2, Color("4a4038"))
	R.call(lx - 4, ly - 6, 9, 11, Color("161410"))
	var lg := 0.6 + 0.4 * sin(t * 3.2) + 0.1 * sin(t * 7.7)
	R.call(lx - 3, ly - 5, 7, 9, Color((150.0 + 70.0 * lg) / 255.0, (96.0 + 50.0 * lg) / 255.0, (34.0 + 22.0 * lg) / 255.0))
	R.call(lx - 1, ly - 3, 3, 5, Color((240.0 + 15.0 * lg) / 255.0, (210.0 + 40.0 * lg) / 255.0, (140.0 + 60.0 * lg) / 255.0))
	R.call(lx - 5, ly + 5, 11, 2, Color("4a4038"))

	# doorway at the foot (SHOP_DOOR.x 200 -> local 150; drawn 32 wide)
	R.call(150.0 - 16.0, H, 32, 16, Color("0d0a06"))
	R.call(150.0 - 16.0, H, 32, 2, Color("1e1610"))
