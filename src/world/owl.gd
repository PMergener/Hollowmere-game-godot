class_name Owl
extends Node2D

## An owl up in a bare tree: brown, tufted, with two amber eyes that blink and
## slide as it watches you cross the village, and a soft two-note call every 16-42
## seconds from wherever it happens to be perched. The HTML's drawOwl plus a
## positional hoot - an AudioStreamPlayer2D, so a hoot from the far tree comes
## quiet and from that side.

var t: float = 0.0
var _blink: float = 0.0
var _look: float = 1.0
var _next_look: float = 4.0
var _next_hoot: float = 10.0
var _voice: AudioStreamPlayer2D


func _ready() -> void:
	add_to_group(&"area_content")
	z_index = 4
	_next_look = randf_range(3.0, 9.0)
	_next_hoot = randf_range(6.0, 22.0)   # the first call comes a little sooner
	_voice = AudioStreamPlayer2D.new()
	_voice.stream = Sfx._bank.get(&"owl")
	_voice.volume_db = -7.0
	_voice.max_distance = 640.0
	add_child(_voice)


func _process(delta: float) -> void:
	t += delta
	if _blink > 0.0:
		_blink -= delta
	elif randf() < delta * 0.35:
		_blink = 0.16
	_next_look -= delta
	if _next_look <= 0.0:
		_look = [0.0, 1.0, 2.0].pick_random()
		_next_look = randf_range(3.0, 8.0)
	_next_hoot -= delta
	if _next_hoot <= 0.0:
		_next_hoot = randf_range(16.0, 42.0)
		if not Sfx.muted and _voice.stream != null:
			_voice.play()
	queue_redraw()


func _draw() -> void:
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)
	var ox := -9.0
	var oy := -32.0
	var turn := roundf(_look)
	# perch shadow + body
	R.call(ox - 1, oy + 1, 8, 2, Color("0d0b08"))
	R.call(ox - 1, oy - 6, 8, 8, Color("3a3128"))
	R.call(ox - 1, oy - 6, 3, 8, Color("463c31"))
	R.call(ox, oy - 2, 2, 1, Color("2b241c"))
	R.call(ox + 3, oy - 4, 2, 1, Color("2b241c"))
	R.call(ox + 1, oy - 1, 1, 1, Color("2b241c"))
	# head + ear tufts
	R.call(ox - 1, oy - 11, 8, 6, Color("4a3f33"))
	R.call(ox - 1, oy - 11, 3, 6, Color("564a3c"))
	R.call(ox - 2, oy - 13, 2, 2, Color("3a3128"))
	R.call(ox + 5, oy - 13, 2, 2, Color("3a3128"))
	# eyes: amber, blinking, sliding with the head-turn
	if _blink <= 0.0:
		R.call(ox + turn, oy - 9, 3, 3, Color("d9a52a"))
		R.call(ox + 4 + turn, oy - 9, 3, 3, Color("d9a52a"))
		R.call(ox + 1 + turn, oy - 8, 1, 1, Color("120d05"))
		R.call(ox + 5 + turn, oy - 8, 1, 1, Color("120d05"))
	else:
		R.call(ox + turn, oy - 8, 3, 1, Color("2b241c"))
		R.call(ox + 4 + turn, oy - 8, 3, 1, Color("2b241c"))
	R.call(ox + 3 + turn, oy - 7, 1, 2, Color("8a6a22"))   # beak
