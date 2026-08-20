@tool
class_name Box
extends PropSprite

## A crate - breakable scenery, never a chest. It blocks the way until a swing
## smashes it, and then it is gone, sometimes with a coin or two spilling out.
## Kept apart from [Chest] on purpose: one is looted by opening, one by breaking.

## A coin drop, if the roll lands. 0 for an empty crate.
@export var coin_drop: int = 2
@export_range(0.0, 1.0, 0.05) var coin_chance: float = 0.5

var _solid: Rect2
var _has_solid := false


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	add_to_group(&"hurtable")
	if blocks and texture != null:
		_solid = footprint()
		_has_solid = true


func melee_hit_offset() -> float:
	return 10.0


func take_melee_hit(_damage: int, _from_position: Vector2) -> void:
	Sfx.play(&"hit")
	if _has_solid:
		CollisionMap.remove_solid(_solid)
	if coin_drop > 0 and randf() < coin_chance:
		PlayerProgress.add_gold(coin_drop)
		EventBus.toast("%d coins" % coin_drop)
	queue_free()
