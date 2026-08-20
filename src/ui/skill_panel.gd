extends CanvasLayer

## The three skills, opened with K, bought with Soul Embers. Each maps to one way
## to survive the dark: see more (Thy Flame), recover faster (Perseverance), or
## take it out of them (Soul Steal). Cost climbs 20% compounding per rank owned.
## Reads PlayerProgress and SkillDb; buying goes through PlayerProgress.buy_skill.

const PANEL := Rect2(96, 40, 384, 280)
const ROW_H := 64

var open := false
var t := 0.0
var _hover := -1

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	painter.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"open_skills"):
		_toggle()
	if not open:
		return
	t += delta
	if Input.is_action_just_pressed(&"pause"):
		_toggle()
	_hover = _row_at(get_viewport().get_mouse_position())
	painter.queue_redraw()


func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open


func _unhandled_input(e: InputEvent) -> void:
	if not open:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := _row_at(e.position)
		if i >= 0:
			var skill: SkillData = SkillDb.all()[i]
			if PlayerProgress.buy_skill(skill):
				Sfx.play(&"quest")
			else:
				Sfx.play(&"denied")
		get_viewport().set_input_as_handled()


func _row_rect(i: int) -> Rect2:
	return Rect2(PANEL.position.x + 14, PANEL.position.y + 44 + i * ROW_H, PANEL.size.x - 28, ROW_H - 8)


func _row_at(m: Vector2) -> int:
	for i in SkillDb.all().size():
		if _row_rect(i).has_point(m):
			return i
	return -1


func paint(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 576, 360), Color(0.02, 0.02, 0.03, 0.76), true)
	ci.draw_rect(PANEL, Color(0.07, 0.065, 0.055, 0.97), true)
	_frame(ci, PANEL, Color("6a5423"))
	PixelText.draw(ci, "SKILLS", PANEL.position.x + 16, PANEL.position.y + 12, Color("e5cd8c"))
	var emb := "EMBERS %d" % PlayerProgress.embers
	PixelText.draw(ci, emb, PANEL.position.x + PANEL.size.x - 16 - PixelText.width(emb), PANEL.position.y + 12, Color("c98a5a"))

	var skills := SkillDb.all()
	for i in skills.size():
		_row(ci, i, skills[i])
	PixelText.draw(ci, "ESC to close", PANEL.position.x + 16, PANEL.position.y + PANEL.size.y - 14, Color("6a6353"))


func _row(ci: CanvasItem, i: int, skill: SkillData) -> void:
	var r := _row_rect(i)
	var maxed := PlayerProgress.is_maxed(skill)
	var can := PlayerProgress.can_buy(skill)
	ci.draw_rect(r, Color("241d10") if _hover == i and can else Color("14110b"), true)
	_frame(ci, r, Color("8a7343") if can else Color("3b382f"))
	PixelText.draw(ci, skill.display_name, r.position.x + 8, r.position.y + 6, Color("c9ab68"))
	PixelText.draw(ci, skill.description, r.position.x + 8, r.position.y + 18, Color("9a9078"))

	# rank pips
	var rank := PlayerProgress.rank_of(skill)
	for p in skill.max_rank:
		var col := Color("7ce8a4") if p < rank else Color("3a3a34")
		ci.draw_rect(Rect2(r.position.x + 8 + p * 10, r.position.y + r.size.y - 12, 7, 6), col, true)

	var tag := ""
	if maxed:
		tag = "MAXED"
	else:
		tag = "%d EMBERS" % PlayerProgress.cost_of(skill)
	var tcol := Color("c98a5a") if can else (Color("6a6a60") if maxed else Color("7a5a40"))
	PixelText.draw(ci, tag, r.position.x + r.size.x - 8 - PixelText.width(tag), r.position.y + r.size.y - 12, tcol)


func _frame(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), c, true)
	ci.draw_rect(Rect2(r.position.x + r.size.x - 2, r.position.y, 2, r.size.y), c, true)
