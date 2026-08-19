class_name DialoguePage
extends Resource

## One box of text.

## Shown in the name plate. Leave empty to keep the previous speaker.
@export var speaker: String = ""
@export_multiline var text: String = ""
## Optional face beside the text.
@export var portrait: Texture2D
## Emitted when this page is reached. Use it to hand over an item or open a
## gate partway through a conversation.
@export var event_on_show: StringName = &""
