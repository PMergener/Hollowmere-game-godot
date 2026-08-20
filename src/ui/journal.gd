extends CanvasLayer

## The journal, opened with J. Two tabs: VOWS lists the tasks Nestor has taken and
## how far along each is; NOTES holds the lore scraps he has read, and shows how
## many are still out there without saying where. Reads from QuestLog and NotesLog
## - it holds no state of its own.

const PANEL := Rect2(98, 15, 380, 322)   # journalPanel(): centred 380x322

var open := false
var tab := "vows"

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	painter.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"open_journal"):
		_toggle()
	if not open:
		return
	if Input.is_action_just_pressed(&"pause"):
		_toggle()
	painter.queue_redraw()


func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open


func _unhandled_input(e: InputEvent) -> void:
	if not open:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if _vows_tab().has_point(e.position):
			tab = "vows"
		elif _notes_tab().has_point(e.position):
			tab = "notes"
		elif Inventory.has_item(&"letter") and _letter_rect().has_point(e.position):
			_toggle()   # close the journal so the pages play unpaused
			EventBus.dialogue_requested.emit("Aldric's Letter", PackedStringArray(AldricBody.PAGES))
		get_viewport().set_input_as_handled()


func _tab_rect(i: int) -> Rect2:
	return Rect2(PANEL.position.x + 26 + i * 92, PANEL.position.y + 30, 86, 17)


func _vows_tab() -> Rect2:
	return _tab_rect(0)


func _notes_tab() -> Rect2:
	return _tab_rect(1)


# The re-readable letter block, at the foot of the panel whenever Aldric's letter
# is in the pack - the HTML kept it in the journal exactly here.
func _letter_rect() -> Rect2:
	return Rect2(PANEL.position.x + 14, PANEL.position.y + PANEL.size.y - 40, PANEL.size.x - 28, 26)


func paint(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 576, 360), Color(0.016, 0.02, 0.031, 0.74), true)
	_parchment(ci)

	# tabs, on the parchment
	var labels := ["VOWS", "NOTES  %d/%d" % [NotesLog.found_count(), NotesLog.total()]]
	var keys := ["vows", "notes"]
	for i in 2:
		var tr := _tab_rect(i)
		var on: bool = tab == keys[i]
		ci.draw_rect(tr, Color("4e4025") if on else Color("2e2513"), true)
		ci.draw_rect(Rect2(tr.position.x, tr.position.y, tr.size.x, 1), Color("6b5a30") if on else Color("3d3018"), true)
		ci.draw_rect(Rect2(tr.position.x, tr.position.y, 1, tr.size.y), Color("6b5a30") if on else Color("3d3018"), true)
		ci.draw_rect(Rect2(tr.position.x + tr.size.x - 1, tr.position.y, 1, tr.size.y), Color("241c0e"), true)
		if not on:
			ci.draw_rect(Rect2(tr.position.x, tr.position.y + tr.size.y - 1, tr.size.x, 1), Color("241c0e"), true)
		var lw := PixelText.width(labels[i])
		PixelText.draw(ci, labels[i], tr.position.x + tr.size.x / 2.0 - lw / 2.0, tr.position.y + 5,
			Color("f0dfae") if on else Color("8a7648"))
	ci.draw_rect(Rect2(PANEL.position.x + 26, PANEL.position.y + 47, PANEL.size.x - 52, 1), Color("6b5a30"), true)

	if tab == "vows":
		_paint_vows(ci)
	else:
		_paint_notes(ci)

	if Inventory.has_item(&"letter"):
		var lr := _letter_rect()
		ci.draw_rect(lr, Color("3a2f1a"), true)
		_frame(ci, lr, Color("6b5a30"))
		PixelText.draw(ci, "ALDRIC'S LETTER", lr.position.x + 8, lr.position.y + 6, Color("d9c07a"))
		var hint := "CLICK TO READ"
		PixelText.draw(ci, hint, lr.position.x + lr.size.x - PixelText.width(hint) - 8, lr.position.y + 6, Color("9a8a5a"))
		PixelText.draw(ci, "FOUR PAGES, IN HIS HAND", lr.position.x + 8, lr.position.y + 16, Color("8a7a52"))


# The journal's parchment, ported from drawScrollFrameJ: a ruled tan page inside a
# dark border, with a title bar top and bottom. Ink is dark on the page, not gold.
func _parchment(ci: CanvasItem) -> void:
	var r := PANEL
	ci.draw_rect(Rect2(r.position.x - 4, r.position.y - 4, r.size.x + 8, r.size.y + 8), Color("0b0906"), true)
	ci.draw_rect(r, Color("241d10"), true)
	ci.draw_rect(Rect2(r.position.x + 4, r.position.y + 4, r.size.x - 8, r.size.y - 8), Color("3a2f1a"), true)
	ci.draw_rect(Rect2(r.position.x + 6, r.position.y + 6, r.size.x - 12, r.size.y - 12), Color("4e4025"), true)
	var i := 0
	while i < r.size.y - 12:
		ci.draw_rect(Rect2(r.position.x + 6, r.position.y + 6 + i, r.size.x - 12, 1),
			Color("473a1d") if i % 9 == 0 else Color("524429"), true)
		i += 3
	ci.draw_rect(Rect2(r.position.x, r.position.y - 2, r.size.x, 14), Color("2a2113"), true)
	ci.draw_rect(Rect2(r.position.x, r.position.y - 4, r.size.x, 3), Color("3d3018"), true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + 9, r.size.x, 2), Color("191207"), true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 12, r.size.x, 14), Color("2a2113"), true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 3), Color("3d3018"), true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 14, r.size.x, 2), Color("191207"), true)
	var tw := PixelText.width("JOURNAL")
	PixelText.draw(ci, "JOURNAL", r.position.x + r.size.x / 2.0 - tw / 2.0 + 1, r.position.y + 4, Color("2a2010"))
	PixelText.draw(ci, "JOURNAL", r.position.x + r.size.x / 2.0 - tw / 2.0, r.position.y + 3, Color("e8d49a"))


func _paint_vows(ci: CanvasItem) -> void:
	var quests := QuestLog.visible_quests()
	var y := PANEL.position.y + 58.0
	if quests.is_empty():
		var msg := "NO VOWS TAKEN."
		PixelText.draw(ci, msg, PANEL.position.x + PANEL.size.x / 2.0 - PixelText.width(msg) / 2.0, y + 30, Color("5c4a28"))
		return
	for q in quests:
		y = _entry(ci, q, PANEL.position.x + 30, y, PANEL.size.x - 60)


func _paint_notes(ci: CanvasItem) -> void:
	var font := ThemeDB.fallback_font
	var y := PANEL.position.y + 58.0
	for n in NotesLog.all():
		if NotesLog.is_found(n.id):
			PixelText.draw(ci, n.title.to_upper(), PANEL.position.x + 30, y, Color("7a2c18"))
			y += 12.0
			ci.draw_multiline_string(font, Vector2(PANEL.position.x + 30, y + 9),
				n.text, HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 60, 11, -1, Color("2f2612"))
			var lines := ceili(font.get_multiline_string_size(n.text, HORIZONTAL_ALIGNMENT_LEFT,
				PANEL.size.x - 60, 11).y / 13.0)
			y += lines * 13.0 + 12.0
		else:
			PixelText.draw(ci, "- NOT YET FOUND -", PANEL.position.x + 30, y, Color("6a5528"))
			y += 20.0


# One vow on the parchment: title in dark red (green when done), giver on the
# right, the objective and a progress bar, and its status line - matching drawJournal.
func _entry(ci: CanvasItem, q: QuestData, x: float, y: float, w: float) -> float:
	var state := QuestLog.state_of(q)
	var done := state == QuestLog.State.DONE
	var ready := state == QuestLog.State.READY
	PixelText.draw(ci, q.title, x, y, Color("4a5c30") if done else Color("7a2c18"))
	var giver := "GIVEN BY " + q.giver.to_upper()
	PixelText.draw(ci, giver, x + w - PixelText.width(giver), y + 2, Color("6a5528"))
	var counted := q.id != &"yotan"
	var obj := "- " + q.objective
	if counted:
		obj += "   %d / %d" % [mini(QuestLog.count_of(q), q.required_count), q.required_count]
	PixelText.draw(ci, obj, x, y + 18, Color("2f2612"))
	if counted:
		var bw := 150.0
		ci.draw_rect(Rect2(x, y + 33, bw, 4), Color("3a2f18"), true)
		var f := clampf(float(QuestLog.count_of(q)) / maxf(1.0, q.required_count), 0.0, 1.0)
		ci.draw_rect(Rect2(x, y + 33, roundf(bw * f), 4), Color("4f8a3a") if done else Color("8a2f1c"), true)
	if ready:
		PixelText.draw(ci, "%s IS WAITING FOR YOUR REPORT" % q.giver.to_upper(), x, y + 42, Color("b58a2c"))
	elif done:
		PixelText.draw(ci, "VOW FULFILLED.", x, y + 42, Color("5f9a48"))
	return y + 62.0


func _frame(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), c, true)
	ci.draw_rect(Rect2(r.position.x + r.size.x - 2, r.position.y, 2, r.size.y), c, true)
