class_name Herbert
extends Actor

## Herbert, the elder. He does not wander - he stands where the village still
## holds, and he is the hand that gives and takes back Nestor's tasks.
##
## Spoken to, he reads the state of his own quests and answers to match: hands
## one back if it is done, offers the next if one waits, or reminds you what is
## still out there. The quest logic lives in [QuestLog]; Herbert only chooses
## which words go with which state.

@export var interact_radius: float = 30.0

var _pal: Dictionary


func _ready() -> void:
	add_to_group(&"interactable")
	_pal = Figure.PAL_NPC[0]


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


# --- Interactable -----------------------------------------------------------

func interact_prompt() -> String:
	return "Speak"


func can_interact() -> bool:
	return true


func interact(by: Node) -> void:
	if by is Node2D:
		face_toward((by as Node2D).global_position - global_position)

	var ready := QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.READY)
	if ready != null:
		QuestLog.hand_in(ready)
		_say(_hand_in_lines(ready))
		return

	var offer := QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.AVAILABLE)
	if offer != null:
		QuestLog.accept(offer)
		_say(_offer_lines(offer))
		return

	var active := QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.ACTIVE)
	if active != null:
		_say(_reminder_lines(active))
		return

	_say(["Keep the lamp full, Nestor. The nights are only getting longer."])


func _say(lines: Array) -> void:
	EventBus.dialogue_requested.emit("Herbert", PackedStringArray(lines))


func _offer_lines(q: QuestData) -> Array:
	if q.id == &"shades":
		return [
			"Nestor. You came. I did not let myself hope.",
			"The dead will not rest. Wraiths drift between the houses where the graves used to be - ten of them, more some nights.",
			"Raise the lamp on them. It is the one thing that still frightens them. Banish ten, and give us a single quiet night.",
		]
	if q.id == &"undercroft":
		return [
			"Something stirs beneath the church. It was not there before the wraiths.",
			"Take the stair down into the undercroft and clear what you find. I fear what is waking under us.",
		]
	return ["There is work, if you will take it: %s." % q.objective]


func _reminder_lines(q: QuestData) -> Array:
	var left: int = q.required_count - QuestLog.count_of(q)
	if q.id == &"shades":
		return ["%d shades still walk. The lamp, Nestor - hold it on them until they burn." % left]
	return ["%s - %d still to do." % [q.objective, left]]


func _hand_in_lines(q: QuestData) -> Array:
	if q.id == &"shades":
		return [
			"It is done. I felt the air change - the first still night in a season.",
			"Hollowmere thanks you, for what our thanks is worth now.",
			"But there is worse below. When you have the stomach for it, ask me of the undercroft.",
		]
	return ["It is done. You have my thanks, Nestor."]


func _draw() -> void:
	Figure.draw_body(self, facing, 0.0, false, _pal, {"eyes": "pale"}, t)
	_quest_marker()


# A ! when he has a task to give, a ? when one is ready to hand back - the same
# language the HTML build used to point the player at him.
func _quest_marker() -> void:
	var mark := ""
	if QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.READY) != null:
		mark = "?"
	elif QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.AVAILABLE) != null:
		mark = "!"
	if mark == "":
		return
	var bob := sin(t * 2.4) * 1.5
	var y := -40.0 + bob
	var col := Color("f0d070") if mark == "!" else Color("70c0f0")
	if mark == "!":
		draw_rect(Rect2(-1, y, 2, 6), col, true)
		draw_rect(Rect2(-1, y + 7, 2, 2), col, true)
	else:
		draw_rect(Rect2(-2, y, 4, 2), col, true)
		draw_rect(Rect2(1, y + 2, 2, 2), col, true)
		draw_rect(Rect2(-1, y + 4, 2, 2), col, true)
		draw_rect(Rect2(-1, y + 7, 2, 2), col, true)
