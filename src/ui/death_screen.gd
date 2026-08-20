extends CanvasLayer

## The dark taking you. When Nestor falls, the screen fades to black, holds on
## "THE DARK TAKES YOU", then he wakes back at the plaza with his vigour restored
## and the wraiths pacified - the HTML build's death and respawn.

const FADE := 1.0
const HOLD := 1.4

var _t := -1.0
var _respawned := false
var _fade: ColorRect
var _label: Label


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label.text = "THE DARK TAKES YOU"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", 22)
	_label.add_theme_color_override(&"font_color", Color("9c2a22"))
	_label.modulate.a = 0.0
	add_child(_label)
	visible = false
	EventBus.player_died.connect(_on_death)


func _on_death() -> void:
	if _t >= 0.0:
		return
	_t = 0.0
	_respawned = false
	visible = true
	get_tree().paused = true


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t < FADE:
		_fade.color.a = _t / FADE
		_label.modulate.a = clampf((_t - 0.3) / 0.6, 0.0, 1.0)
	elif _t < FADE + HOLD:
		_fade.color.a = 1.0
		_label.modulate.a = 1.0
	elif _t < FADE + HOLD + FADE:
		if not _respawned:
			_respawn()
		var k := (_t - FADE - HOLD) / FADE
		_fade.color.a = 1.0 - k
		_label.modulate.a = 1.0 - k
	else:
		_t = -1.0
		visible = false
		get_tree().paused = false


func _respawn() -> void:
	_respawned = true
	var p := get_tree().get_first_node_in_group(&"player")
	if p != null:
		p.hp = p.hp_max
		p.dead = false
		p.held_light = ""
	# Wake at the plaza no matter where you fell - the village rebuilds fresh, so
	# the wraiths come back passive, which is the HTML's pacify-on-death.
	EventBus.travel_requested.emit(&"village", WorldData.PLAYER_START)
	EventBus.player_respawned.emit()
