class_name DialogueChoice
extends Resource

## One button at the end of a conversation.

@export var text: String = "Yes"
## Emitted when the player picks this. Quests accept, doors open, and so on.
@export var event: StringName = &""
## Played straight after. Leave empty to close the box.
@export var follow_up: DialogueData
