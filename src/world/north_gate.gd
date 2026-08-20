class_name NorthGate
extends Node2D

## The gate in the north wall, and the way out of Hollowmere. It holds three
## states, the same three the HTML build tracked: barred (nothing you do moves
## it), unbarred (Herbert has had it opened after the report - it will swing now),
## and open (swung wide, the road beyond it). Walking the open road is the end.

@export var interact_radius: float = 40.0

var t: float = 0.0


func _ready() -> void:
	add_to_group(&"interactable")
	add_to_group(&"area_content")
	z_index = 2


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func interact_prompt() -> String:
	if not PlayerProgress.has_flag(&"north_gate_unbarred"):
		return "The north gate is barred"
	if not PlayerProgress.has_flag(&"north_gate_open"):
		return "Open the north gate"
	return "Take the road to Yotan"


func can_interact() -> bool:
	return true


func interact(_by: Node) -> void:
	if not PlayerProgress.has_flag(&"north_gate_unbarred"):
		EventBus.dialogue_requested.emit("Nestor", PackedStringArray([
			"The north road is not yet walked. There is nothing north of here for me until this is finished.",
		]))
		return
	if not PlayerProgress.has_flag(&"north_gate_open"):
		PlayerProgress.set_flag(&"north_gate_open")
		Sfx.play(&"quest")
		Sfx.play(&"shriek", -10.0)
		EventBus.shake_requested.emit(1.5, 0.45)
		EventBus.banner("THE GATE GIVES", "THE ROAD TO YOTAN", true)
		return
	# open, and the player chooses to walk it
	EventBus.emit_event(&"reached_yotan")


# A heavy timber-and-iron gate across the wall gap. Barred: two leaves shut, a
# drawbar across them. Unbarred: the bar is gone but the leaves still stand.
# Open: the leaves are swung back to the posts and the dark road shows between.
func _draw() -> void:
	var open := PlayerProgress.has_flag(&"north_gate_open")
	var unbarred := PlayerProgress.has_flag(&"north_gate_unbarred")
	var half := 48.0
	var top := -6.0
	var h := 30.0
	var R := func(x, y, w, hh, c): draw_rect(Rect2(roundf(x), roundf(y), w, hh), c, true)

	# stone posts either side of the gap
	R.call(-half - 6, top - 4, 6, h + 8, Color("34322c"))
	R.call(half, top - 4, 6, h + 8, Color("34322c"))
	R.call(-half - 6, top - 4, 6, 3, Color("54514a"))
	R.call(half, top - 4, 6, 3, Color("54514a"))

	if open:
		# leaves folded back against the posts; the road beyond reads as a darker gap
		R.call(-half + 1, top, 6, h, Color("2a2118"))
		R.call(half - 7, top, 6, h, Color("2a2118"))
		R.call(-half + 8, top + 2, (half - 8) * 2.0, h - 4, Color(0.02, 0.02, 0.03))
		return

	# two closed leaves of vertical planks
	for lx: float in [-half + 2.0, 2.0]:
		R.call(lx, top, half - 4.0, h, Color("3a2c1a"))
		var px := lx
		while px < lx + half - 4.0:
			R.call(px, top, 1, h, Color("2c2012"))
			px += 5.0
		R.call(lx, top, half - 4.0, 2, Color("4a3a22"))
		R.call(lx, top + h - 2.0, half - 4.0, 2, Color("241a10"))
	# iron bands
	R.call(-half + 2, top + 6, (half - 2.0) * 2.0, 3, Color("1c1a17"))
	R.call(-half + 2, top + h - 10.0, (half - 2.0) * 2.0, 3, Color("1c1a17"))

	if not unbarred:
		# the drawbar - a single timber slung across both leaves, with iron brackets
		R.call(-half + 6, top + 13, (half - 6.0) * 2.0, 5, Color("5a4327"))
		R.call(-half + 6, top + 13, (half - 6.0) * 2.0, 1, Color("6e5636"))
		R.call(-half + 10, top + 12, 4, 7, Color("15130f"))
		R.call(half - 14, top + 12, 4, 7, Color("15130f"))
