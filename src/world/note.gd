class_name Note
extends Node2D

## A lore scrap lying in the world. Read it - by walking onto it and pressing E -
## and it is yours for good, kept in the journal's Notes tab. Like everything else
## it obeys the dark: you find these by carrying light over them.

@export var note_id: StringName = &"note1"
@export var interact_radius: float = 20.0

var _t := 0.0


func _ready() -> void:
	add_to_group(&"interactable")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func interact_prompt() -> String:
	return "Read"


func can_interact() -> bool:
	return not NotesLog.is_found(note_id)


func interact(_by: Node) -> void:
	if NotesLog.collect(note_id):
		Sfx.play(&"pickup")
		EventBus.toast("You found a note - read it in your journal (J)")
	queue_free()


func _draw() -> void:
	# a small curled scrap of paper, lifting slightly
	var lift := sin(_t * 1.6) * 1.0
	draw_rect(Rect2(-5, 1, 11, 3), Color(0, 0, 0, 0.4), true)
	var y := -7.0 + lift
	draw_rect(Rect2(-5, y, 10, 8), Color("cabf9a"), true)
	draw_rect(Rect2(-5, y, 10, 1), Color("ddd2ad"), true)
	draw_rect(Rect2(-5, y + 7, 10, 1), Color("a89a72"), true)
	# a couple of ink lines
	draw_rect(Rect2(-3, y + 2, 6, 1), Color("4a4030"), true)
	draw_rect(Rect2(-3, y + 4, 4, 1), Color("4a4030"), true)
