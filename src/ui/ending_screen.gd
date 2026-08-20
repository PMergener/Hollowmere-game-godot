extends CanvasLayer

## The end of the road. When Nestor walks north through the unbarred gate, Yotan
## takes him and the screen this is - "THE ROAD ENDS HERE" - replaces the world.
## It is the terminus of the parity mission (up to the Yotan gate) and mirrors the
## HTML build's ENDING panel: the closing words, the author's contact, and two
## choices - leave it standing, or begin again.

const PANEL_W := 420.0
const PANEL_H := 236.0

const GOLD := Color("e8d49a")
const AMBER := Color("c9ab68")
const DIM := Color("8a7a5a")
const GREEN := Color("7f9a6a")
const CYAN := Color("a8dcec")
const INK := Color("6a5f48")

var _root: Control


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.016, 0.016, 0.024, 0.86)
	_root.add_child(dim)

	# the framed card, centred
	var frame := _rect(_root, Color("0b0906"), PANEL_W + 8.0, PANEL_H + 8.0)
	var body := _rect(frame, Color("241d10"), PANEL_W, PANEL_H)
	_rect(body, Color("3a2f1a"), PANEL_W - 12.0, PANEL_H - 12.0)
	var page := _rect(body, Color("47391f"), PANEL_W - 20.0, PANEL_H - 20.0)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 22.0
	col.offset_right = -22.0
	col.offset_top = 20.0
	col.add_theme_constant_override(&"separation", 6)
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	page.add_child(col)

	_line(col, "THE ROAD ENDS HERE", 17, GOLD)
	_spacer(col, 8)
	_line(col, "Yotan stands. The rest of this tale is not written yet.", 12, AMBER)
	_line(col, "Thank you for playing.", 12, DIM)
	_spacer(col, 6)
	_divider(col)
	_spacer(col, 4)
	_line(col, "Found a bug, or want to suggest something?", 11, GREEN)
	_line(col, "pedro.mergener@gmail.com", 12, CYAN)
	_line(col, "subject:  Bugs or suggestions", 10, INK)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 16)
	_spacer(col, 10)
	col.add_child(row)
	_button(row, "Close - thanks again", _on_close)
	_button(row, "Start over", _on_restart)

	EventBus.game_event.connect(_on_event)


func _on_event(name: StringName, _payload: Dictionary) -> void:
	if name == &"reached_yotan":
		_open()


func _open() -> void:
	if _root.visible:
		return
	_root.visible = true
	_root.modulate.a = 0.0
	Sfx.play(&"quest")
	get_tree().paused = true
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.6)


func _on_close() -> void:
	_root.visible = false
	get_tree().paused = false
	Sfx.play(&"pickup")


func _on_restart() -> void:
	_root.visible = false
	get_tree().paused = false
	PlayerProgress.reset()
	QuestLog.reset()
	Inventory.clear()
	var p := get_tree().get_first_node_in_group(&"player")
	if p != null:
		p.hp_max = float(PlayerProgress.max_health())     # level is 1 again after reset
		p.lamp_max = 100.0 + float(PlayerProgress.lamp_bonus())
		p.hp = p.hp_max
		p.dead = false
	EventBus.travel_requested.emit(&"village", WorldData.PLAYER_START)


# --- little builders --------------------------------------------------------

func _rect(parent: Control, colour: Color, w: float, h: float) -> Control:
	var r := ColorRect.new()
	r.color = colour
	r.custom_minimum_size = Vector2(w, h)
	r.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	r.offset_left = -w / 2.0
	r.offset_right = w / 2.0
	r.offset_top = -h / 2.0
	r.offset_bottom = h / 2.0
	parent.add_child(r)
	return r


func _line(col: VBoxContainer, text: String, size: int, colour: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", colour)
	l.add_theme_color_override(&"font_outline_color", Color(0.04, 0.03, 0.02, 0.9))
	l.add_theme_constant_override(&"outline_size", 3)
	col.add_child(l)


func _divider(col: VBoxContainer) -> void:
	var d := ColorRect.new()
	d.color = Color("3f3116")
	d.custom_minimum_size = Vector2(0, 1)
	d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	d.custom_minimum_size.x = PANEL_W - 100.0
	col.add_child(d)


func _spacer(col: VBoxContainer, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	col.add_child(s)


func _button(row: HBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(176, 27)
	b.add_theme_font_size_override(&"font_size", 11)
	b.add_theme_color_override(&"font_color", Color("a8925e"))
	b.add_theme_color_override(&"font_hover_color", Color("f0dca8"))
	b.pressed.connect(cb)
	row.add_child(b)
