# THE TRAIL A CARRIED LIGHT LEAVES BEHIND IT.
#
# Ported from updateEmbers/drawEmbers. I had not implemented one line of this,
# and it is a bigger absence than it sounds: the embers are what make a lit torch
# feel like fire being carried through a place rather than a lamp icon sliding
# over a background. They fall behind you as you walk, so the room remembers
# where you have been for a second or two.
#
# The two lights behave differently on purpose:
#
#   TORCH  spits often (50% a frame), fast and wide, and dies quickly. It is
#          burning pitch and it sheds sparks.
#   LAMP   sheds rarely (18%), slow and narrow, and lingers. It is not fire, it
#          is whatever is inside the dark iron - and it drifts.
#
# LIGHTING LAYER: drawn in the world, before the composite, with everything else
# in the scene. Embers are IN the room, not on the screen.
extends Node2D

const MAX := 220

var live: Array = []
var player: Node2D = null


func _process(delta: float) -> void:
	var kind := ""
	if player:
		kind = player.held_light
	if kind != "" and live.size() < MAX:
		var lamp := kind == "lamp"
		if randf() < (0.18 if lamp else 0.5):
			# spawn at the flame, not at the player's feet
			var tdx := -9.0 if player.facing == 2 else (9.0 if player.facing == 3 else (-9.0 if player.facing == 1 else 9.0))
			var off := Vector2(tdx, -13.0 if lamp else -22.0)
			live.append({
				"p": player.position + off + Vector2(randf() * 4.0 - 2.0, -3.0),
				"v": Vector2((randf() - 0.5) * (4.0 if lamp else 10.0),
							 (-5.0 - randf() * 6.0) if lamp else (-12.0 - randf() * 15.0)),
				"life": 1.0,
				"g": lamp,
			})
	for i in range(live.size() - 1, -1, -1):
		var e = live[i]
		e.p += e.v * delta
		e.life -= delta * (0.5 if e.g else 0.9)
		if e.life <= 0.0:
			live.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for e in live:
		var s := 2.0 if e.life > 0.6 else 1.0
		var c: Color
		if e.g:
			c = Color("7ce8a4") if e.life > 0.55 else (Color("2e9a5e") if e.life > 0.25 else Color("124026"))
		else:
			c = Color("e0902c") if e.life > 0.55 else (Color("8f4a12") if e.life > 0.25 else Color("3d2109"))
		draw_rect(Rect2(e.p.x, e.p.y, s, s), c, true)
