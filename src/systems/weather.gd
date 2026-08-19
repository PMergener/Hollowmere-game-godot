# Atmosphere: rain, splashes, fog, vignette and film grain.
#
# The first pass was too timid and, more importantly, missing two whole layers.
# What was wrong, measured against the HTML build rather than guessed at again:
#
#   * 150 drops at alpha 0.16-0.42, should be 320 at 0.20-0.50
#   * every splash landed at the BOTTOM EDGE. In the original each drop carries
#     its own `land` height, so rain strikes the ground all over the screen -
#     that is what makes it read as weather rather than as falling lines
#   * fog was flat rectangles at alpha 0.02. It is five ADDITIVE radial blobs of
#     radius 135 at alpha 0.10, which is why mine practically did not exist
#   * NO VIGNETTE AND NO GRAIN AT ALL. These are most of what "atmosphere" means
#     here: the vignette crushes the edges to 0.75 black and the grain lays a
#     moving film over everything. Their absence is why the village looked clean
#     and dead rather than grim.
extends CanvasLayer

const N_DROPS := 320
const MAX_SPLASH := 140
const WIND := -0.17

var drops: Array = []
var splashes: Array = []
var grain_tex: ImageTexture
var t := 0.0

@onready var painter: Node2D = $Painter


func _ready() -> void:
	for i in N_DROPS:
		drops.append(_seed_drop({}, true))
	# 128x128 of static noise at low alpha, drawn with a random offset each
	# frame. Generated once - it is the same trick the HTML build uses.
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var v := randf()
			img.set_pixel(x, y, Color(v, v, v, 22.0 / 255.0))
	grain_tex = ImageTexture.create_from_image(img)


func _seed_drop(d: Dictionary, init: bool) -> Dictionary:
	d.x = randf() * (576.0 + 100.0) - 50.0
	d.y = randf() * 360.0 if init else -14.0 - randf() * 44.0
	# Each drop lands at ITS OWN height, not at the bottom of the screen.
	d.land = randf() * (360.0 + 20.0)
	d.v = 300.0 + randf() * 225.0
	d.len = 6.0 + randf() * 8.0
	d.a = 0.20 + randf() * 0.30
	if d.land < d.y + 18.0:
		d.land = d.y + 18.0 + randf() * 60.0
	return d


func _process(delta: float) -> void:
	t += delta
	for d in drops:
		d.y += d.v * delta
		d.x += d.v * delta * WIND
		if d.y >= d.land:
			if splashes.size() < MAX_SPLASH and randf() < 0.55:
				splashes.append({"x": d.x, "y": d.land, "life": 1.0})
			_seed_drop(d, false)
		elif d.x < -60.0 or d.x > 636.0:
			_seed_drop(d, false)
	for i in range(splashes.size() - 1, -1, -1):
		splashes[i].life -= delta * 4.2
		if splashes[i].life <= 0.0:
			splashes.remove_at(i)
	painter.queue_redraw()


func paint(ci: CanvasItem) -> void:
	# FOG REMOVED. The HTML draws it as additive radial gradients at alpha 0.10,
	# which lifts the dark almost invisibly. Godot 4 has no draw_set_blend_mode,
	# so I approximated it with stacked pale rings - and stacked alpha does not
	# behave like additive light. The result was five white balls sliding across
	# the screen, which is worse than no fog at all in a game that is supposed to
	# be almost entirely dark. Doing it properly needs a second CanvasItem
	# carrying a CanvasItemMaterial in ADD mode; until then, nothing.
	for s in splashes:
		var a: float = s.life * 0.42
		if s.life > 0.55:
			ci.draw_rect(Rect2(s.x - 1, s.y, 3, 1), Color(0.729, 0.800, 0.878, a), true)
		else:
			ci.draw_rect(Rect2(s.x - 3, s.y, 1, 1), Color(0.627, 0.706, 0.792, a), true)
			ci.draw_rect(Rect2(s.x + 3, s.y, 1, 1), Color(0.627, 0.706, 0.792, a), true)
	for d in drops:
		var h1: float = d.len * 0.5
		ci.draw_rect(Rect2(round(d.x), round(d.y), 1, ceil(h1)),
			Color(0.776, 0.839, 0.910, d.a), true)
		ci.draw_rect(Rect2(round(d.x) - 1, round(d.y) + h1, 1, ceil(h1)),
			Color(0.776, 0.839, 0.910, d.a * 0.7), true)
	_vignette(ci)
	_grain(ci)


# Crushes the edges of the frame. This is doing more work for the mood than
# anything else on screen - without it the village reads as a clean tile map.
func _vignette(ci: CanvasItem) -> void:
	# RINGS, not filled circles. Filled circles all cover the middle, so the
	# accumulated alpha at the centre came out around 0.63 - it was darkening the
	# whole frame and flattening the lamp's pool of light, which is the one thing
	# on screen that must stay bright.
	const STEPS := 26
	var inner := 360.0 * 0.34
	var outer := 360.0 * 1.30          # past the corners
	var step := (outer - inner) / STEPS
	for k in STEPS:
		var f := float(k) / (STEPS - 1)
		var r := inner + step * k + step * 0.5
		var a := 0.75 * f * f          # squared, so it stays clear well past the middle
		ci.draw_arc(Vector2(288, 180), r, 0.0, TAU, 64,
			Color(0, 0, 0, a * 0.5), step + 1.0)


func _grain(ci: CanvasItem) -> void:
	var ox := -randi_range(0, 127)
	var oy := -randi_range(0, 127)
	for gy in range(oy, 360, 128):
		for gx in range(ox, 576, 128):
			ci.draw_texture(grain_tex, Vector2(gx, gy))
