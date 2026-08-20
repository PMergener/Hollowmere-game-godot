class_name Villager
extends Actor

## The people still left in Hollowmere. They wander their patch of the village
## and, spoken to, give you one line of what the nights have done to them.
##
## A villager is not an Enemy - it has no health and joins no hurt group. It is
## an [Interactable]: stand near it, press the interact key, and it speaks. What
## it says is data ([member line]), so a designer writes new townsfolk without
## touching this file.

@export_multiline var line: String = ""
@export var palette_index: int = 0
@export var interact_radius: float = 26.0

## How long a villager stops and faces you after being spoken to, matching how
## long its line stays on screen.
const INTERACT_HOLD := 3.2

var _wander: Wander
var _pal: Dictionary
var _hold := 0.0
var _speaker: Node2D


func _ready() -> void:
	add_to_group(&"interactable")
	add_to_group(&"villagers")
	move_speed = 24.0 + randf() * 12.0
	body_radius = 7.0
	_pal = Figure.PAL_NPC[palette_index % Figure.PAL_NPC.size()]
	_wander = Wander.new(position)
	_wander.wait = randf() * 3.0


func _process(delta: float) -> void:
	t += delta

	# While engaged, stop wandering and keep facing whoever is speaking - the
	# villager holds still and answers, then resumes its rounds. This is a state,
	# not a slowdown: it never takes a wander step until the hold runs out.
	if _hold > 0.0:
		_hold -= delta
		moving = false
		if _speaker != null and is_instance_valid(_speaker):
			face_toward(_speaker.global_position - global_position)
		queue_redraw()
		return

	_wander.wait -= delta
	if _wander.wait > 0.0:
		moving = false
		queue_redraw()
		return
	var to := _wander.target - position
	var d := to.length()
	if d < 4.0:
		_wander.wait = 1.0 + randf() * 4.0
		_wander.pick(position, 110.0, 7.0, WorldData.WORLD)
		moving = false
		queue_redraw()
		return
	var gained := walk(to, delta)
	if gained < move_speed * delta * 0.35:
		_wander.pick(position, 110.0, 7.0, WorldData.WORLD)
	queue_redraw()


# --- Interactable contract --------------------------------------------------

func interact_prompt() -> String:
	return "Speak"


func can_interact() -> bool:
	return true


func interact(by: Node) -> void:
	# Stop, turn to whoever is speaking, and hold there while we answer.
	if by is Node2D:
		_speaker = by
		face_toward((by as Node2D).global_position - global_position)
	_hold = INTERACT_HOLD
	moving = false
	if line.strip_edges().is_empty():
		EventBus.toast("They only stare at you.")
	else:
		EventBus.toast(line)


func _draw() -> void:
	Figure.draw_body(self, facing, step * 9.0, moving, _pal,
		{"eyes": "pale"}, t)
