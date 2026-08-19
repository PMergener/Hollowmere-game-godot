class_name NpcData
extends Resource

## A villager, a shopkeeper, a quest giver.

@export var id: StringName = &""
@export var display_name: String = "Villager"

@export_group("Appearance")
@export var sprite_frames: SpriteFrames
@export var modulate_color: Color = Color.WHITE

@export_group("Conversation")
## Played when the player presses interact. Quest givers usually leave this
## empty and let the quest system choose the line instead.
@export var dialogue: DialogueData
## Short lines spoken unprompted when the player walks past. One is picked at
## random.
@export_multiline var ambient_lines: PackedStringArray = []
## Seconds between ambient lines. 0 turns them off.
@export var ambient_interval: float = 0.0

@export_group("Movement")
## 0 keeps it standing still.
@export var wander_radius: float = 0.0
@export var walk_speed: float = 22.0
## Seconds spent standing before choosing a new spot.
@export var pause_seconds: float = 2.0
