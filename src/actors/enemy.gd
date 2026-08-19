class_name Enemy
extends Actor

## The shared spine of everything that wants Nestor dead.
##
## It carries what every foe has - health, a hurt flash, a dying fade, the memory
## of who is chasing - and the two things combat needs from it: it joins the
## "hurtable" group so a swing can find it, and it answers take_melee_hit. What a
## particular foe DOES each frame is left to _think, and how it LOOKS to _draw,
## so a skeleton and a wraith share this and disagree only where they should.

signal died()

@export var max_hp: float = 15.0
@export var xp_reward: int = 5
## The id announced on death, so quests can count "wraith_killed" without code.
@export var enemy_id: StringName = &"enemy"

var hp: float = 15.0
var hurt: float = 0.0
var hostile: bool = false
var dying: float = 0.0
var gone: bool = false

var player: Player


func _ready() -> void:
	hp = max_hp
	add_to_group(&"hurtable")
	add_to_group(&"enemies")
	player = get_tree().get_first_node_in_group(&"player") as Player


func _process(delta: float) -> void:
	t += delta
	if hurt > 0.0:
		hurt = maxf(0.0, hurt - delta * 3.0)
	if dying > 0.0:
		dying -= delta
		if dying <= 0.0 and not gone:
			gone = true
			_on_vanished()
		queue_redraw()
		return
	if gone:
		_while_gone(delta)
		return
	if player != null and not is_instance_valid(player):
		player = null
	_think(delta)
	queue_redraw()


## How far a swing has to reach up from the feet to strike this foe's middle.
func melee_hit_offset() -> float:
	return 18.0


## Whether a landed swing counts right now. Overridden by the wraith, which can
## only be cut while the lamp is revealing it.
func is_hittable() -> bool:
	return not gone and dying <= 0.0


func take_melee_hit(damage: int, from_position: Vector2) -> void:
	if not is_hittable():
		return
	hp -= damage
	hurt = 0.34
	hostile = true
	_apply_knockback(from_position, 11.0)
	EventBus.emit_event(&"enemy_struck", {"id": enemy_id})
	if hp <= 0.0:
		_die()


func _apply_knockback(from_position: Vector2, force: float) -> void:
	var away := position - from_position
	var d := away.length()
	if d < 0.001:
		return
	var to := position + away / d * force
	if not CollisionMap.blocked(to.x, to.y, body_radius + 2.0):
		position = to


func _die() -> void:
	hp = 0.0
	dying = _death_seconds()
	hostile = false
	PlayerProgress.add_xp(xp_reward)
	EventBus.enemy_died.emit(enemy_id, position)
	EventBus.emit_event(StringName("%s_killed" % enemy_id), {"position": position})
	died.emit()


# --- overridable ------------------------------------------------------------

## What this foe does each live frame. The base just stands there.
func _think(_delta: float) -> void:
	pass

## Seconds the death animation runs before the body vanishes.
func _death_seconds() -> float:
	return 0.6

## Called once when the dying fade completes. Drops belong here.
func _on_vanished() -> void:
	pass

## Called each frame while gone, for foes that respawn.
func _while_gone(_delta: float) -> void:
	pass
