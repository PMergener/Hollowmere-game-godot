extends CanvasLayer

## The top-right minimap, ported from the HTML build's drawMinimap: same 112px
## panel, same world->panel mapping, same reveal rules. Houses, trees, braziers,
## the pyre, villagers and soul drops are always shown; PASSIVE wraiths are not -
## only hostile ones blink red, so the lamp stays the only way to find the rest.

const MM_S := 112.0
const MM_X := 576.0 - MM_S - 10.0
const MM_Y := 10.0
const SHOP_HOUSE := 8

var t := 0.0
var _player: Node2D

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 15
	# The minimap is the village's; underground the HTML shows a different map, so
	# for now it simply hides when you are not on the surface.
	EventBus.area_entered.connect(func(area): visible = (area == &"village"))


func _process(delta: float) -> void:
	t += delta
	painter.queue_redraw()


func _mm(wx: float, wy: float) -> Vector2:
	var world := WorldData.WORLD
	return Vector2(MM_X + 2.0 + wx / world * (MM_S - 4.0),
				   MM_Y + 2.0 + wy / world * (MM_S - 4.0))


func paint(ci: CanvasItem) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D

	var R := func(x, y, w, h, c): ci.draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)

	# panel + frame + corner studs
	R.call(MM_X - 2, MM_Y - 2, MM_S + 4, MM_S + 4, Color(8.0/255, 7.0/255, 5.0/255, 0.86))
	R.call(MM_X, MM_Y, MM_S, MM_S, Color(15.0/255, 13.0/255, 10.0/255, 0.9))
	var bd := Color("6a5423")
	R.call(MM_X - 2, MM_Y - 2, MM_S + 4, 2, bd)
	R.call(MM_X - 2, MM_Y + MM_S, MM_S + 4, 2, bd)
	R.call(MM_X - 2, MM_Y - 2, 2, MM_S + 4, bd)
	R.call(MM_X + MM_S, MM_Y - 2, 2, MM_S + 4, bd)
	for c in [[0.0, 0.0], [MM_S - 4, 0.0], [0.0, MM_S - 4], [MM_S - 4, MM_S - 4]]:
		R.call(MM_X - 1 + c[0], MM_Y - 1 + c[1], 5, 5, Color("8a6f34"))

	# the plaza clearing
	var plaza := _mm(600, 600)
	ci.draw_circle(plaza, 250.0 / WorldData.WORLD * (MM_S - 4.0), Color(40.0/255, 36.0/255, 26.0/255, 0.5))

	# houses
	for hi in WorldData.HOUSES.size():
		var h = WorldData.HOUSES[hi]
		var a := _mm(h[0], h[1])
		var b := _mm(h[0] + h[2], h[1] + h[3])
		var ruin: bool = hi in WorldData.HOUSE_RUIN
		var is_shop := hi == SHOP_HOUSE
		var body := Color("33302b") if ruin else (Color("5c4a28") if is_shop else Color("4a453c"))
		var top := Color("43403a") if ruin else (Color("7a6234") if is_shop else Color("5e584c"))
		R.call(a.x, a.y, b.x - a.x, b.y - a.y, body)
		R.call(a.x, a.y, b.x - a.x, 1, top)

	# trees, braziers, pyre
	for ti in WorldData.TREES.size():
		var tr = WorldData.TREES[ti]
		var p := _mm(tr[0], tr[1])
		R.call(p.x - 1, p.y - 1, 2, 2, Color("5a4a2a") if ti in WorldData.TREE_OWL else Color("26301f"))
	var braz := WorldData.braziers()
	for bi in braz.size():
		var b = braz[bi]
		var p := _mm(b[0], b[1])
		var g := 0.6 + 0.4 * sin(t * 4.0 + bi * 1.37)
		R.call(p.x - 1, p.y - 1, 2, 2, Color(150.0 * g / 255, 85.0 * g / 255, 28.0 * g / 255))
	var pyre := _mm(WorldData.STONES[0][0], WorldData.STONES[0][1])
	R.call(pyre.x - 1, pyre.y - 1, 3, 3, Color("a5450f"))

	# villagers (live), soul drops
	for n in get_tree().get_nodes_in_group(&"villagers"):
		var p := _mm(n.global_position.x, n.global_position.y)
		R.call(p.x - 1, p.y - 1, 2, 2, Color("585044"))
	for d in get_tree().get_nodes_in_group(&"drops"):
		var p := _mm(d.global_position.x, d.global_position.y)
		R.call(p.x - 1, p.y - 1, 2, 2, Color("7ce8a4"))

	# hostile wraiths only, blinking - passive ones stay hidden
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if e is Ghost and e.hostile and not e.gone and e.dying <= 0.0:
			var p := _mm(e.global_position.x, e.global_position.y)
			var k := 0.5 + 0.5 * sin(t * 7.0)
			R.call(p.x - 1, p.y - 1, 3, 3, Color(190.0 * k / 255, 40.0/255, 32.0/255, 0.9))

	# the camera's view box
	var vw := 576.0 / WorldData.WORLD * (MM_S - 4.0)
	var vh := 360.0 / WorldData.WORLD * (MM_S - 4.0)
	if _player != null:
		var vp := _mm(_player.global_position.x - 288.0, _player.global_position.y - 180.0)
		ci.draw_rect(Rect2(roundf(vp.x) + 0.5, roundf(vp.y) + 0.5, roundf(vw), roundf(vh)),
			Color(180.0/255, 160.0/255, 110.0/255, 0.35), false, 1.0)

	# Herbert's quest marker
	var herbert := _first_in_group(&"herbert")
	if herbert != null:
		var mark := ""
		if QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.READY) != null:
			mark = "?"
		elif QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.AVAILABLE) != null:
			mark = "!"
		if mark != "":
			var hp := _mm(herbert.global_position.x, herbert.global_position.y)
			var bob := roundf(sin(t * 3.2) * 1.5)
			var col := Color("f0d055") if mark == "!" else Color("8fd6f0")
			R.call(hp.x - 3, hp.y - 9 + bob, 7, 10, Color(0, 0, 0, 0.65))
			R.call(hp.x - 1, hp.y - 8 + bob, 2, 5, col)
			R.call(hp.x - 1, hp.y - 2 + bob, 2, 2, col)

	# the player, pulsing, with a facing tick
	if _player != null:
		var me := _mm(_player.global_position.x, _player.global_position.y)
		var pulse := 0.65 + 0.35 * sin(t * 3.4)
		R.call(me.x - 2, me.y - 2, 5, 5, Color(0, 0, 0, 0.7))
		R.call(me.x - 1, me.y - 1, 3, 3, Color(230.0 * pulse / 255, 215.0 * pulse / 255, 160.0 * pulse / 255))
		var fd = [[0, 3], [0, -3], [-3, 0], [3, 0]][_player.facing]
		R.call(me.x + fd[0], me.y + fd[1], 1, 1, Color("e8ddc0"))


func _first_in_group(g: StringName) -> Node2D:
	var arr := get_tree().get_nodes_in_group(g)
	return arr[0] if not arr.is_empty() else null
