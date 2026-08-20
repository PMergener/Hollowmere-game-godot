extends CanvasLayer

## The hints scroll, opened with T. Two blocks: the controls (accurate to THIS
## build's bindings, not the HTML's mouse scheme - here the swing is the left
## button and E is the hand that acts), and what the four carried oddments are for.
## A listener like the journal: it reads nothing it does not print, and it pauses
## the world while it is up.

const PANEL := Rect2(78, 26, 420, 308)

const CONTROLS := [
	["WASD", "walk"],
	["SHIFT", "run while held - it costs stamina"],
	["LEFT CLICK", "swing your sword"],
	["E", "talk, take, open, climb"],
	["Q", "swap to your other weapon"],
	["F", "raise or stow the lamp"],
	["1 - 9", "use or equip that belt slot"],
	["I", "inventory and equipment"],
	["J", "journal - vows taken and notes found"],
	["K", "skills, bought with soul embers"],
	["T", "these hints"],
	["M", "mute"],
]

const ITEMS := [
	["torch", "Pitch torch", "Wide warm light. Safe. Shows you nothing that hides."],
	["lamp", "Dark iron lamp", "Narrow green light. The ONLY way to see the dead."],
	["soul", "Soul powder", "Restores 40 vigour. Dropped by banished wraiths."],
	["tear", "Crystalized Tear", "Worth nothing to you. Ondrick pays 5 gold each."],
]

var open := false

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	painter.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"open_hints"):
		_toggle()
	if not open:
		return
	if Input.is_action_just_pressed(&"pause") or Input.is_action_just_pressed(&"open_hints"):
		pass
	painter.queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if not open:
		return
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_toggle()
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed:
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open


func paint(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 576, 360), Color(0.02, 0.02, 0.03, 0.72), true)
	# parchment frame
	ci.draw_rect(Rect2(PANEL.position.x - 4, PANEL.position.y - 4, PANEL.size.x + 8, PANEL.size.y + 8), Color("0b0906"), true)
	ci.draw_rect(PANEL, Color("241d10"), true)
	ci.draw_rect(Rect2(PANEL.position.x + 4, PANEL.position.y + 4, PANEL.size.x - 8, PANEL.size.y - 8), Color("3a2f1a"), true)
	ci.draw_rect(Rect2(PANEL.position.x + 6, PANEL.position.y + 6, PANEL.size.x - 12, PANEL.size.y - 12), Color("47391f"), true)

	var x := PANEL.position.x + 20.0
	PixelText.draw(ci, "HOW TO PLAY", x, PANEL.position.y + 16, Color("e8d49a"))
	var close := "PRESS T OR CLICK TO CLOSE"
	PixelText.draw(ci, close, PANEL.position.x + PANEL.size.x - PixelText.width(close) - 20.0, PANEL.position.y + 16, Color("7c6f52"))

	var y := PANEL.position.y + 38.0
	PixelText.draw(ci, "CONTROLS", x, y, Color("c9a86e"))
	ci.draw_rect(Rect2(x, y + 10.0, PANEL.size.x - 40.0, 1), Color("5a4327"), true)
	y += 18.0
	for row in CONTROLS:
		PixelText.draw(ci, row[0], x, y, Color("d8cba6"))
		PixelText.draw(ci, String(row[1]).to_upper(), x + 92.0, y, Color("9a8a68"))
		y += 11.0

	y += 8.0
	PixelText.draw(ci, "WHAT YOU CARRY", x, y, Color("c9a86e"))
	ci.draw_rect(Rect2(x, y + 10.0, PANEL.size.x - 40.0, 1), Color("5a4327"), true)
	y += 18.0
	for it in ITEMS:
		if ItemIcons.has_live_icon(it[0]):
			ItemIcons.draw_live_icon(ci, it[0], x + 6.0, y + 5.0, false, 0.0)
		else:
			ItemIcons.draw_icon(ci, it[0], x + 6.0, y + 5.0, 0.62)
		PixelText.draw(ci, String(it[1]).to_upper(), x + 18.0, y, Color("d8cba6"))
		PixelText.draw(ci, String(it[2]).to_upper(), x + 18.0, y + 8.0, Color("8a7a5a"))
		y += 20.0
