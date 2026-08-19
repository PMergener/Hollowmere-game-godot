extends CanvasLayer

## The words the game says to you: the "[E] Speak" prompt, and the toast line
## that surfaces when something happens - a villager's answer, a wraith waking.
##
## Its own layer above the world and the weather so darkness and rain never touch
## it. Purely a listener on [EventBus]; it decides nothing, it only shows.

const TOAST_HOLD := 3.2
const TOAST_FADE := 0.6

var _prompt: Label
var _toast: Label
var _toast_time: float = 0.0


func _ready() -> void:
	layer = 20
	_prompt = _make_label(330.0)
	_prompt.add_theme_color_override(&"font_color", Color(0.83, 0.78, 0.62))
	_toast = _make_label(300.0)
	_toast.add_theme_color_override(&"font_color", Color(0.92, 0.88, 0.78))
	EventBus.interaction_prompt.connect(_on_prompt)
	EventBus.toast_requested.connect(_on_toast)


func _make_label(y: float) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = y
	l.offset_bottom = y + 20.0
	l.add_theme_font_size_override(&"font_size", 12)
	# A dark outline so pale text stays readable over the pale-grey ground.
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override(&"outline_size", 4)
	l.text = ""
	add_child(l)
	return l


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		var a := clampf(_toast_time / TOAST_FADE, 0.0, 1.0)
		_toast.modulate.a = a
		if _toast_time <= 0.0:
			_toast.text = ""


func _on_prompt(text: String) -> void:
	_prompt.text = text


func _on_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_time = TOAST_HOLD + TOAST_FADE
