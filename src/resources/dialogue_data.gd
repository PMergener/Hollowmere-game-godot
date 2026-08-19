class_name DialogueData
extends Resource

## A conversation: a run of pages, optionally ending in a choice.

@export var pages: Array[DialoguePage] = []

@export_group("Choice")
## Leave empty for a conversation that simply ends. Two entries give the player
## a yes or no at the last page.
@export var choices: Array[DialogueChoice] = []


func page_count() -> int:
	return pages.size()


func has_choice() -> bool:
	return not choices.is_empty()
