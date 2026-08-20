extends CanvasLayer

## The box people talk through, matched to the HTML build. The advance logic is a
## straight port of advanceDialogue(): the input is POLLED each frame (not taken
## through _unhandled_input, which the box's own Control nodes were eating - that
## was why E did nothing), gated by age>0.35 so the same press that opens the box
## cannot advance it, and the box CLOSES the instant the page index passes the last
## page. A page may carry choices, picked with the number keys or a click.
##
## E (interact) or a click reveals the rest while it is typing, then advances; the
## last advance ends the conversation. The player is frozen while it is open.

const CHARS_PER_SEC := 44.0
const OPEN_GUARD := 0.35
const BASE_TOP := -116.0
const CHOICE_ROW := 15.0

# each page: {"text": String} or {"text": String, "choices": [{"label", "fn"}]}
var _pages: Array = []
var _index := 0
var _open := false
var _age := 0.0
var _player: Node = null
var _unfreeze_next := false
var _hover_choice := -1

var _panel: Panel
var _speaker: Label
var _body: RichTextLabel
var _prompt: Label
var _choice_labels: Array[Label] = []


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build()
	visible = false
	EventBus.dialogue_requested.connect(_on_requested)
	EventBus.dialogue_pages_requested.connect(_on_pages)


func _build() -> void:
	_panel = Panel.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 28
	_panel.offset_right = -28
	_panel.offset_top = BASE_TOP
	_panel.offset_bottom = -34
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.035, 0.96)
	sb.border_color = Color("6a5423")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override(&"panel", sb)
	add_child(_panel)

	_speaker = Label.new()
	_speaker.position = Vector2(12, 4)
	_speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker.add_theme_font_size_override(&"font_size", 12)
	_speaker.add_theme_color_override(&"font_color", Color("e5cd8c"))
	_speaker.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_speaker.add_theme_constant_override(&"outline_size", 4)
	_panel.add_child(_speaker)

	_body = RichTextLabel.new()
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 12
	_body.offset_top = 26
	_body.offset_right = -12
	_body.offset_bottom = -6
	_body.scroll_active = true
	_body.bbcode_enabled = false
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_theme_font_size_override(&"normal_font_size", 13)
	_body.add_theme_color_override(&"default_color", Color("ece3cf"))
	_body.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	_body.add_theme_constant_override(&"outline_size", 3)
	_panel.add_child(_body)

	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_prompt.offset_left = -26
	_prompt.offset_top = -18
	_prompt.offset_right = -6
	_prompt.offset_bottom = -2
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_font_size_override(&"font_size", 12)
	_prompt.add_theme_color_override(&"font_color", Color("c9ab68"))
	_prompt.text = "▸"
	_panel.add_child(_prompt)

	for i in 3:
		var l := Label.new()
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override(&"font_size", 12)
		l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override(&"outline_size", 3)
		l.visible = false
		_panel.add_child(l)
		_choice_labels.append(l)


func is_open() -> bool:
	return _open


# --- opening ----------------------------------------------------------------

func _on_requested(speaker: String, lines: PackedStringArray) -> void:
	var pages: Array = []
	for line in lines:
		pages.append({"text": line})
	_start(speaker, pages)


func _on_pages(speaker: String, pages: Array) -> void:
	_start(speaker, pages)


func _start(speaker: String, pages: Array) -> void:
	if pages.is_empty():
		return
	_pages = pages
	_index = 0
	_open = true
	visible = true
	_speaker.text = speaker
	_show_page(0)
	_freeze_player(true)
	EventBus.dialogue_started.emit(null, speaker)


func _current_choices() -> Array:
	if _index < 0 or _index >= _pages.size():
		return []
	var c = _pages[_index].get("choices", [])
	return c if c is Array else []


func _show_page(i: int) -> void:
	_body.text = String(_pages[i].get("text", ""))
	_age = 0.0
	_body.visible_characters = 0
	_body.scroll_to_line(0)
	_hover_choice = -1
	var choices := _current_choices()
	_panel.offset_top = BASE_TOP - CHOICE_ROW * choices.size() if not choices.is_empty() else BASE_TOP
	for k in _choice_labels.size():
		var lab := _choice_labels[k]
		if k < choices.size():
			lab.text = "%d.  %s" % [k + 1, choices[k].get("label", "")]
		lab.visible = false


# --- running (all input polled here, HTML-style) ----------------------------

func _process(delta: float) -> void:
	if _unfreeze_next:
		_unfreeze_next = false
		_freeze_player(false)
	if not _open:
		return

	_age += delta
	var total := _body.get_total_character_count()
	if _age * CHARS_PER_SEC < total:
		_body.visible_characters = int(_age * CHARS_PER_SEC)
		_body.scroll_to_line(_body.get_line_count())
	else:
		_body.visible_characters = -1
	var done := _age * CHARS_PER_SEC >= total

	var choices := _current_choices()
	if not choices.is_empty() and done:
		_layout_choices()
		_prompt.visible = false
	else:
		_prompt.visible = done and (int(Time.get_ticks_msec() / 400) % 2 == 0)


# Input goes through _input, which fires BEFORE the GUI - so the box always sees E
# even though its own Panel/RichTextLabel would otherwise eat the event (that was
# the "E does nothing" bug). The opening press never reaches here because the box
# is opened later, during _process. The age guard is a belt-and-braces.
func _input(event: InputEvent) -> void:
	if not _open or _age <= OPEN_GUARD:
		return
	var choices := _current_choices()
	var done := _age * CHARS_PER_SEC >= _body.get_total_character_count()

	# number keys pick a choice
	if not choices.is_empty() and done and event is InputEventKey and event.pressed and not event.echo:
		var n: int = (event as InputEventKey).keycode - KEY_1
		if n >= 0 and n < choices.size():
			_pick(n)
			get_viewport().set_input_as_handled()
			return

	var mouse_click: bool = event is InputEventMouseButton \
		and (event as InputEventMouseButton).pressed \
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	var act: bool = event.is_action_pressed(&"interact") or event.is_action_pressed(&"attack") or mouse_click
	if not act:
		return
	get_viewport().set_input_as_handled()
	if not choices.is_empty() and done:
		if _hover_choice >= 0:
			_pick(_hover_choice)   # click on a choice row; otherwise wait for a number
	else:
		_advance()


func _layout_choices() -> void:
	var choices := _current_choices()
	_update_hover()
	var bottom := _panel.size.y - 8.0
	for k in choices.size():
		var lab := _choice_labels[k]
		lab.position = Vector2(16, bottom - CHOICE_ROW * (choices.size() - k))
		lab.visible = true
		lab.add_theme_color_override(&"font_color",
			Color("f0dca8") if k == _hover_choice else Color("b79b5f"))


func _update_hover() -> void:
	var choices := _current_choices()
	_hover_choice = -1
	var m := get_viewport().get_mouse_position()
	for k in choices.size():
		var lab := _choice_labels[k]
		var r := Rect2(lab.global_position, Vector2(_panel.size.x - 32.0, CHOICE_ROW))
		if r.has_point(m):
			_hover_choice = k


func _advance() -> void:
	var total := _body.get_total_character_count()
	if _age * CHARS_PER_SEC < total:
		_age = total / CHARS_PER_SEC + 0.05   # first press: reveal the rest
		return
	_index += 1
	if _index >= _pages.size():
		_close()
	else:
		_show_page(_index)


func _pick(k: int) -> void:
	var choices := _current_choices()
	if k < 0 or k >= choices.size():
		return
	var fn = choices[k].get("fn")
	_close()
	if fn is Callable and (fn as Callable).is_valid():
		fn.call()


func _close() -> void:
	_open = false
	visible = false
	for lab in _choice_labels:
		lab.visible = false
	_panel.offset_top = BASE_TOP
	_unfreeze_next = true
	EventBus.dialogue_finished.emit()


func _freeze_player(frozen: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
	if _player != null and "can_act" in _player:
		_player.can_act = not frozen
