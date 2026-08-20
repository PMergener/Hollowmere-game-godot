class_name Ondrick
extends Actor

## Ondrick, the only commerce in Hollowmere. He stands at his counter; spoken to
## the first time he says his piece, then opens the shop. After that, E opens it
## straight away - the HTML build's behaviour.

@export var interact_radius: float = 30.0

var _pal: Dictionary
var _met := false


func _ready() -> void:
	add_to_group(&"interactable")
	_pal = Figure.PAL_NPC[2]


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func interact_prompt() -> String:
	return "Trade"


func can_interact() -> bool:
	return true


func interact(by: Node) -> void:
	if by is Node2D:
		face_toward((by as Node2D).global_position - global_position)
	if not _met:
		_met = true
		EventBus.dialogue_requested.emit("Ondrick", PackedStringArray([
			"Careful where you tread, sword. The mud in here is mostly people.",
			"I buy what the dead leave behind and I sell what keeps you breathing. No credit, no questions, no refunds.",
		]))
		EventBus.dialogue_finished.connect(_open_once, CONNECT_ONE_SHOT)
	else:
		EventBus.shop_requested.emit()


func _open_once() -> void:
	EventBus.shop_requested.emit()


func _draw() -> void:
	Figure.draw_body(self, facing, 0.0, false, _pal, {"eyes": "pale"}, t)
