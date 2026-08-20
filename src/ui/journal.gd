extends CanvasLayer

## The journal, opened with J. It lists the tasks Nestor has taken, where each
## one stands, and how far along it is. Reads everything from [QuestLog] - it
## holds no quest state of its own, so a quest that advances in the world is
## already up to date here the next time it is opened.

var open := false

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	painter.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"open_journal"):
		_toggle()
	if open and Input.is_action_just_pressed(&"pause"):
		_toggle()
	if open:
		painter.queue_redraw()


func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open


func paint(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 576, 360), Color(0.02, 0.02, 0.03, 0.72), true)
	var panel := Rect2(96, 34, 384, 292)
	ci.draw_rect(panel, Color(0.07, 0.065, 0.055, 0.96), true)
	_frame(ci, panel, Color("3b382f"))
	PixelText.draw(ci, "JOURNAL", panel.position.x + 14, panel.position.y + 12, Color("c9ab68"))

	var quests := QuestLog.visible_quests()
	var y := panel.position.y + 34.0
	if quests.is_empty():
		PixelText.draw(ci, "NO TASKS YET. SPEAK TO HERBERT.",
			panel.position.x + 14, y + 6, Color("6a6353"))
		return

	for q in quests:
		y = _entry(ci, q, panel.position.x + 14, y, panel.size.x - 28)


func _entry(ci: CanvasItem, q: QuestData, x: float, y: float, w: float) -> float:
	var state := QuestLog.state_of(q)
	var done := state == QuestLog.State.DONE
	var ready := state == QuestLog.State.READY

	# a coloured tick down the left margin: amber active, blue ready, grey done
	var tab := Color("8a7343")
	if ready: tab = Color("5c8fb8")
	elif done: tab = Color("4a4a44")
	ci.draw_rect(Rect2(x, y, 3, 26), tab, true)

	var title_col := Color("c9ab68")
	if done: title_col = Color("6a6a60")
	PixelText.draw(ci, q.title, x + 10, y, title_col)

	var tag := ""
	if done: tag = "DONE"
	elif ready: tag = "READY - RETURN TO " + q.giver.to_upper()
	if tag != "":
		PixelText.draw(ci, tag, x + w - PixelText.width(tag), y, tab)

	PixelText.draw(ci, q.objective, x + 10, y + 9, Color("9a9078"))

	# progress, for anything that counts more than one
	if q.required_count > 1 and not done:
		var line := "%d / %d" % [QuestLog.count_of(q), q.required_count]
		PixelText.draw(ci, line, x + 10, y + 18, Color("7c9a6a"))
	return y + 34.0


func _frame(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), c, true)
	ci.draw_rect(Rect2(r.position.x + r.size.x - 2, r.position.y, 2, r.size.y), c, true)
