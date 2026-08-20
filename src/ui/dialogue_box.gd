extends CanvasLayer

## The box at the bottom that people talk through. An NPC emits
## [signal EventBus.dialogue_requested] with who is speaking and their lines;
## this shows them one at a time and advances on the interact key or a click.
##
## While it is open the player cannot move or swing - talking is its own moment,
## and being chipped at by a wraith mid-sentence would undercut it. The box only
## shows plain lines; branching trees are a DialogueData concern for later.

var _lines: PackedStringArray = []
var _index := 0
var _speaker := ""
var _open := false
var _player: Node = null

var _panel: Panel
var _speaker_label: Label
var _body: Label
var _prompt: Label


func _ready() -> void:
	layer = 25
	_build()
	visible = false
	EventBus.dialogue_requested.connect(_on_requested)


func _build() -> void:
	_panel = Panel.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 40
	_panel.offset_right = -40
	_panel.offset_top = -104
	_panel.offset_bottom = -40
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.05, 0.95)
	sb.border_color = Color("574f3b")
	sb.set_border_width_all(2)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override(&"panel", sb)
	add_child(_panel)

	_speaker_label = Label.new()
	_speaker_label.position = Vector2(12, 6)
	_speaker_label.add_theme_font_size_override(&"font_size", 11)
	_speaker_label.add_theme_color_override(&"font_color", Color("c9ab68"))
	_panel.add_child(_speaker_label)

	_body = Label.new()
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 12
	_body.offset_top = 24
	_body.offset_right = -12
	_body.offset_bottom = -8
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override(&"font_size", 12)
	_body.add_theme_color_override(&"font_color", Color("d8d0c0"))
	_panel.add_child(_body)

	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_prompt.offset_left = -70
	_prompt.offset_top = -18
	_prompt.offset_right = -8
	_prompt.offset_bottom = -2
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.add_theme_font_size_override(&"font_size", 9)
	_prompt.add_theme_color_override(&"font_color", Color("7a7263"))
	_prompt.text = "E ▸"
	_panel.add_child(_prompt)


func is_open() -> bool:
	return _open


func _on_requested(speaker: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	_speaker = speaker
	_lines = lines
	_index = 0
	_open = true
	visible = true
	_speaker_label.text = speaker
	_body.text = lines[0]
	_freeze_player(true)
	EventBus.dialogue_started.emit(null, speaker)


func _unhandled_input(e: InputEvent) -> void:
	if not _open:
		return
	var advance := false
	if e is InputEventKey and e.pressed and not e.echo and e.is_action_pressed(&"interact"):
		advance = true
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if advance:
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
		return
	_body.text = _lines[_index]


func _close() -> void:
	_open = false
	visible = false
	_freeze_player(false)
	EventBus.dialogue_finished.emit()


func _freeze_player(frozen: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
	if _player != null and "can_act" in _player:
		_player.can_act = not frozen
