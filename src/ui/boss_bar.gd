extends CanvasLayer

## The named health bar for a boss - the Fallen Hunter. 280px across the top with
## four quarter-notches so it reads as a length, a pulsing leading edge, the name
## and the remaining HP. It shows only while a boss is alive and disappears the
## moment he is down. HUD, so it sits after the lighting composite.

const W := 280.0

var t := 0.0

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 16


func _process(delta: float) -> void:
	t += delta
	painter.queue_redraw()


func _boss() -> Enemy:
	for b in get_tree().get_nodes_in_group(&"boss"):
		if b is Enemy and b.hp > 0.0 and not b.gone and b.hostile:
			return b
	return null


func paint(ci: CanvasItem) -> void:
	var boss := _boss()
	if boss == null:
		return
	var x := (576.0 - W) / 2.0
	var y := 16.0
	var frac := clampf(boss.hp / boss.max_hp, 0.0, 1.0)

	ci.draw_rect(Rect2(x - 2, y - 2, W + 4, 14), Color(0, 0, 0, 0.72), true)
	ci.draw_rect(Rect2(x, y, W, 10), Color("2a1412"), true)
	ci.draw_rect(Rect2(x, y, W * frac, 10), Color("a83028"), true)
	# pulsing leading edge
	if frac > 0.0:
		var pu := 0.6 + 0.4 * sin(t * 6.0)
		ci.draw_rect(Rect2(x + W * frac - 2, y, 2, 10), Color(0.9 * pu, 0.4 * pu, 0.35 * pu), true)
	# quarter notches
	for i in range(1, 4):
		ci.draw_rect(Rect2(x + W * i / 4.0, y, 1, 10), Color(0, 0, 0, 0.6), true)
	# frame
	ci.draw_rect(Rect2(x, y, W, 1), Color("6a5423"), true)
	ci.draw_rect(Rect2(x, y + 9, W, 1), Color("6a5423"), true)

	PixelText.draw(ci, "FALLEN HUNTER", x, y - 11, Color("e5cd8c"))
	var hp := "%d" % int(boss.hp)
	PixelText.draw(ci, hp, x + W - PixelText.width(hp), y - 11, Color("c9a86e"))
