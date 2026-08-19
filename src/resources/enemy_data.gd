class_name EnemyData
extends Resource

## Everything that makes one enemy different from another.
##
## The scene decides HOW an enemy thinks; this file decides HOW MUCH. To make a
## tougher skeleton, duplicate the skeleton .tres and raise the numbers - you do
## not need a new scene. To make something think differently, give it a
## different Brain.

@export var id: StringName = &""
@export var display_name: String = "Unnamed"

@export_group("Vitals")
@export var max_health: int = 20
## Damage is rolled between these two on every hit, so blows do not feel
## identical. Set them equal for a flat number.
@export var damage_min: int = 28
@export var damage_max: int = 40
## Subtracted from incoming damage.
@export var armor: int = 0

@export_group("Movement")
@export var move_speed: float = 42.0
## Pixels from the player before it notices. Beyond this it idles.
@export var detect_radius: float = 200.0
## How close it wants to be to swing.
@export var attack_radius: float = 22.0
## Beyond this it gives up and returns home. 0 means it never gives up.
@export var leash_radius: float = 0.0

@export_group("Attack")
## Seconds between swings.
@export var attack_cooldown: float = 2.2
## Seconds of telegraph before the blow lands. This is the player's window to
## read the attack and step out. Short windups feel cheap.
@export var attack_windup: float = 0.4
@export var attack_recover: float = 0.22

@export_group("Rewards")
@export var loot: LootTable

@export_group("Appearance")
@export var sprite_frames: SpriteFrames
## Tint applied over the sprite. Leave white for none.
@export var modulate_color: Color = Color.WHITE
## Height in pixels, used to place the health bar and the name.
@export var body_height: float = 29.0

@export_group("Light")
## Ticked, standing in lamp light burns it. This is what makes the wraiths a
## wager rather than an obstacle: the lamp is both the weapon and the timer.
@export var hurt_by_light: bool = false
## Seconds of continuous lamp light before it dies.
@export var light_expose_seconds: float = 3.6
## Ticked, it fades out of sight when it is not lit.
@export var fades_in_darkness: bool = false

@export_group("Brain")
## The AI. Leave empty for the default: walk at the player and swing.
## Swap it for a stalker, an archer or a boss brain.
@export var brain: PackedScene

@export_group("Sound")
@export var sounds: SoundBank


## Rolls a single blow.
func roll_damage(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(damage_min, max(damage_min, damage_max))
