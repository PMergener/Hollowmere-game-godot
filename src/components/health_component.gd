@icon("res://icon.svg")
class_name HealthComponent
extends Node

## Gives whatever it is attached to something to lose.
##
## Drag one onto any node and it can be killed. It holds no opinion about what
## dying looks like - it announces [signal died] and the actor decides whether
## that means a ragdoll, a puff of soul powder or a game-over screen.

signal damaged(info: DamageInfo, remaining: int)
signal healed(amount: int, remaining: int)
signal died(info: DamageInfo)
signal health_changed(current: int, maximum: int)

@export var max_health: int = 20:
	set(value):
		max_health = max(1, value)
		current = min(current, max_health)

## Subtracted from every blow. The player keeps this in step with what is worn;
## an enemy takes it from its EnemyData.
@export var armor: int = 0

## However hard a blow, at least this much always gets through. Without it,
## enough armour makes a creature untouchable by accident.
@export var minimum_damage: int = 1

## Seconds of immunity after being hit. Stops a single overlapping swing from
## landing on every physics frame.
@export var invulnerable_seconds: float = 0.25

var current: int = 0
var _invulnerable_until: float = 0.0


func _ready() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func is_alive() -> bool:
	return current > 0


func is_invulnerable() -> bool:
	return _time() < _invulnerable_until


func fraction() -> float:
	return clampf(float(current) / float(max_health), 0.0, 1.0)


## Applies a blow. Returns the damage that actually landed, which is 0 when the
## hit was ignored - useful for deciding whether to play a clang or a squelch.
func take_damage(info: DamageInfo) -> int:
	if not is_alive() or is_invulnerable() or info == null:
		return 0

	var landed := info.amount
	if not info.ignores_armor:
		landed = max(minimum_damage, info.amount - armor)
	landed = max(0, landed)
	if landed == 0:
		return 0

	current = max(0, current - landed)
	_invulnerable_until = _time() + invulnerable_seconds

	damaged.emit(info, current)
	health_changed.emit(current, max_health)
	if current == 0:
		died.emit(info)
	return landed


func heal(amount: int) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var before := current
	current = min(max_health, current + amount)
	var gained := current - before
	if gained > 0:
		healed.emit(gained, current)
		health_changed.emit(current, max_health)
	return gained


## Raises the ceiling and, by default, the floor with it - levelling up should
## feel like a reward, not like being handed a bigger empty bar.
func set_max_health(value: int, heal_the_difference: bool = true) -> void:
	var before := max_health
	max_health = value
	if heal_the_difference and max_health > before:
		current = min(max_health, current + (max_health - before))
	health_changed.emit(current, max_health)


func refill() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func _time() -> float:
	return Time.get_ticks_msec() / 1000.0
