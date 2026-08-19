# The HUD: two liquid orbs and the nine-slot action bar.
#
# Screen space, on its own CanvasLayer above the weather - these are not in the
# world and must never be touched by the darkness or the rain.
#
# The orbs are the only place the player reads their two resources, and they are
# drawn as LIQUID rather than as bars on purpose: health and lamp charge are the
# two things you watch while walking into the dark, and a moving surface catches
# the eye in peripheral vision where a rectangle does not.
extends CanvasLayer

const ORB_R := 24
const BAR_N := 9
const SLOT_W := 26
const SLOT_GAP := 3
const BAR_W := BAR_N * SLOT_W + (BAR_N - 1) * SLOT_GAP
const BAR_X := (576 - BAR_W) / 2
const BAR_Y := 360 - 32

# hi / mid / lo / glow, as the HTML build defines them
const ORB_HP := {
	"hi": Color8(255, 110, 92), "mid": Color8(186, 32, 32),
	"lo": Color8(74, 10, 10), "glow": Color8(150, 30, 26), "phase": 0.0,
}
const ORB_LAMP := {
	"hi": Color8(124, 255, 158), "mid": Color8(26, 158, 78),
	"lo": Color8(8, 58, 30), "glow": Color8(30, 150, 80), "phase": 2.1,
}

# what sits in the belt, by item key. Slots 0-8 are the hotbar.
var belt: Array = ["lamp", "torch", "soul", "", "", "", "", "", ""]
var selected := -1
var player: Node2D = null
var t := 0.0

@onready var painter: Node2D = $Painter


func _process(delta: float) -> void:
	t += delta
	painter.queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode >= KEY_1 and e.keycode <= KEY_9:
			var i: int = e.keycode - KEY_1
			if belt[i] == "" or player == null:
				return
			var key: String = belt[i]
			if key == "soul":
				# a CONSUMABLE - pressing it uses one, it is not a selection
				player.consume_soul()
				return
			if key == "lamp" or key == "torch":
				# One light at a time, and pressing the one you are holding puts
				# it away. The lamp additionally has to have charge left.
				if player.held_light == key:
					player.held_light = ""
					selected = -1
				elif key == "torch" or player.lamp > 1.0:
					player.held_light = key
					selected = i
				player.lamp_on = player.held_light == "lamp"
			else:
				selected = -1 if selected == i else i


func paint(ci: CanvasItem) -> void:
	var hp := 1.0
	var lamp := 1.0
	if player:
		hp = clampf(player.hp / player.hp_max, 0.0, 1.0)
		lamp = clampf(player.lamp / player.LAMP_MAX, 0.0, 1.0)
	_orb(ci, BAR_X - ORB_R - 9, BAR_Y + SLOT_W - ORB_R, ORB_HP, hp)
	_orb(ci, BAR_X + BAR_W + ORB_R + 9, BAR_Y + SLOT_W - ORB_R, ORB_LAMP, lamp)
	_bar(ci)


# One orb. Drawn pixel by pixel because the surface wave, the depth gradient and
# the rim shading all vary per pixel - there is no primitive that does this.
func _orb(ci: CanvasItem, cx: float, cy: float, o: Dictionary, fill: float) -> void:
	var r := float(ORB_R)
	var surf := cy + r - 2.0 * r * clampf(fill, 0.0, 1.0)
	for dy in range(-ORB_R, ORB_R + 1):
		for dx in range(-ORB_R, ORB_R + 1):
			var d := sqrt(float(dx * dx + dy * dy))
			if d > r:
				continue
			var px := cx + dx
			var py := cy + dy
			if d > r - 1.5:
				ci.draw_rect(Rect2(px, py, 1, 1), Color("0a0a0c"), true)
				continue
			if d > r - 4.5:
				var sh := (dx + dy) / (r * 2.0)
				var c := Color("3a3a41")
				if sh < -0.18: c = Color("5a5a62")
				elif sh > 0.2: c = Color("1c1c20")
				ci.draw_rect(Rect2(px, py, 1, 1), c, true)
				continue
			# The surface, two waves so it never settles into a rhythm. A FULL
			# orb has its surface at the very top where the sphere is only a few
			# pixels wide, so the wave is invisible and the orb reads as a flat
			# disc - which is exactly what it looked like. Clamping the surface a
			# little inside the rim keeps the moving line visible at any level.
			var wave := sin(t * 1.9 + dx * 0.26 + o.phase) * 1.7 \
					  + sin(t * 3.3 + dx * 0.15 + o.phase) * 1.1
			var top: float = clampf(surf, cy - r + 5.0, cy + r) + wave
			if py >= top:
				var depth: float = minf(1.0, (py - top) / (r * 1.9))
				var col: Color
				if depth < 0.16:
					col = o.hi.lerp(o.mid, depth / 0.16)
				else:
					col = o.mid.lerp(o.lo, (depth - 0.16) / 0.84)
				# the specular streak on the upper left, as if lit from there
				if dx < -r * 0.30 and dx > -r * 0.72 and dy < r * 0.1 and dy > -r * 0.55 and d < r - 6:
					col = o.hi.lerp(Color.WHITE, 0.35)
				ci.draw_rect(Rect2(px, py, 1, 1), col, true)
			else:
				var v := 1.0 - (top - py) / (r * 1.6)
				ci.draw_rect(Rect2(px, py, 1, 1),
					Color("171a1e") if v > 0.55 else Color("0d0f12"), true)
	ci.draw_rect(Rect2(cx - r * 0.42, cy - r * 0.66, 5, 2), Color(1, 1, 1, 0.30), true)
	ci.draw_rect(Rect2(cx - r * 0.54, cy - r * 0.48, 3, 1), Color(1, 1, 1, 0.18), true)


func _bar(ci: CanvasItem) -> void:
	for i in BAR_N:
		var x := BAR_X + i * (SLOT_W + SLOT_GAP)
		var y := float(BAR_Y)
		var key: String = belt[i]
		# a consumable you have none of is an empty slot
		var has: bool = key != ""
		if has and key == "soul" and player and player.souls <= 0:
			has = false
		# For a light, "selected" means IT IS THE ONE IN YOUR HAND - not merely
		# the last slot you pressed. That is what the highlight is telling you.
		var sel: bool = false
		if has:
			if player and (key == "lamp" or key == "torch"):
				sel = player.held_light == key
			else:
				sel = i == selected
		ci.draw_rect(Rect2(x, y, SLOT_W, SLOT_W),
			Color(0.102, 0.094, 0.071, 0.92) if sel else Color(0.035, 0.039, 0.051, 0.84), true)
		var bc := Color("232322")
		if sel: bc = Color("3f8a5c") if key == "lamp" else Color("8a7343")
		elif has: bc = Color("3b382f")
		ci.draw_rect(Rect2(x, y, SLOT_W, 2), bc, true)
		ci.draw_rect(Rect2(x, y + SLOT_W - 2, SLOT_W, 2), bc, true)
		ci.draw_rect(Rect2(x, y, 2, SLOT_W), bc, true)
		ci.draw_rect(Rect2(x + SLOT_W - 2, y, 2, SLOT_W), bc, true)
		_digit(ci, i + 1, x + 3, y + 3,
			(Color("c9ab68") if sel else Color("5c5849")) if has else Color("33332e"))
		if has:
			if ItemIcons.has_live_icon(key):
				# drawn, not blitted - see the note in item_icons.gd. The icon is
				# LIT when it is the light you are carrying, and it animates.
				ItemIcons.draw_live_icon(ci, key, x + 13, y + 14, sel, t)
			else:
				ItemIcons.draw_icon(ci, key, x + SLOT_W / 2.0, y + SLOT_W / 2.0, 0.72)
			# THE BAR ABOVE THE SLOT. Two pixels, sitting 4px clear of the top,
			# pulsing at 4Hz - green for the lamp, amber for anything else. This
			# is the thing that tells you at a glance which light is in your hand,
			# and it was missing entirely.
			if sel:
				var pu := 0.55 + 0.45 * sin(t * 4.0)
				var c := Color8(int(60 * pu), int(200 * pu), int(120 * pu), 230) if key == "lamp" \
					else Color8(int(190 * pu), int(158 * pu), int(92 * pu), 230)
				ci.draw_rect(Rect2(x + 5, y - 4, SLOT_W - 10, 2), c, true)
			# and the soul powder pulses its own bar when you are hurt and could
			# use it - a different signal, same language
			elif key == "soul" and player:
				if player.denied > 0.0:
					# refused, because you are already whole - the slot flashes red
					var dc := Color(0.588, 0.235, 0.204, player.denied)
					ci.draw_rect(Rect2(x, y, SLOT_W, 2), dc, true)
					ci.draw_rect(Rect2(x, y + SLOT_W - 2, SLOT_W, 2), dc, true)
					ci.draw_rect(Rect2(x, y, 2, SLOT_W), dc, true)
					ci.draw_rect(Rect2(x + SLOT_W - 2, y, 2, SLOT_W), dc, true)
				elif player.hp < player.hp_max:
					var pu2 := 0.4 + 0.6 * sin(t * 3.2)
					ci.draw_rect(Rect2(x + 5, y - 4, SLOT_W - 10, 2),
						Color8(int(70 * pu2), int(200 * pu2), int(120 * pu2), 204), true)
			# how many you have left
			if key == "soul" and player:
				var n := str(player.souls)
				for d in n.length():
					_digit(ci, int(n[d]), x + SLOT_W - 5 - (n.length() - d) * 4, y + SLOT_W - 9,
						Color("9ee0b6"))


# The 3x5 bitmap digits, copied ROW BY ROW from the HTML build rather than
# packed into hex by me - I wrote the packed version from memory first and it was
# wrong, which is not a thing you notice until a "3" looks like an "8".
# Text below ~8px turns to mush under a pixelated upscale, which is why these are
# plotted by hand in both builds.
const DIGITS := [
	[0b111, 0b101, 0b101, 0b101, 0b111],   # 0
	[0b010, 0b110, 0b010, 0b010, 0b111],   # 1
	[0b111, 0b001, 0b111, 0b100, 0b111],   # 2
	[0b111, 0b001, 0b111, 0b001, 0b111],   # 3
	[0b101, 0b101, 0b111, 0b001, 0b001],   # 4
	[0b111, 0b100, 0b111, 0b001, 0b111],   # 5
	[0b111, 0b100, 0b111, 0b101, 0b111],   # 6
	[0b111, 0b001, 0b001, 0b010, 0b010],   # 7
	[0b111, 0b101, 0b111, 0b101, 0b111],   # 8
	[0b111, 0b101, 0b111, 0b001, 0b111],   # 9
]

func _digit(ci: CanvasItem, n: int, x: float, y: float, c: Color) -> void:
	var g: Array = DIGITS[n % 10]
	for row in 5:
		for b in 3:
			if g[row] & (1 << (2 - b)):
				ci.draw_rect(Rect2(x + b, y + row, 1, 1), c, true)
