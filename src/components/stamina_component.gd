class_name StaminaComponent
extends Node

## The green bar. Ten squares, held as a float so a third of a square reads as a
## third of a square.
##
## The rule that matters: running out never refuses an action. An empty bar
## makes you slow, not helpless, which keeps the sword in the player's hands
## when things have gone wrong. Take that away and the game punishes panic
## twice.

signal changed(current: float, maximum: float)
## Fired when the bar empties, and again when it has recovered.
signal exhausted_changed(is_exhausted: bool)

@export var max_nuggets: float = 10.0
## Cost of one swing. A third means three swings to a square.
@export var attack_cost: float = 1.0 / 3.0
## Nuggets a second while running.
@export var run_drain: float = 1.0
## Speed multiplier while running.
@export var run_multiplier: float = 1.5
## Speed AND swing multiplier once the bar is empty.
@export var tired_multiplier: float = 0.7
## Seconds after the last spend before any of it comes back.
@export var recover_delay: float = 3.0
## Seconds to regain one nugget.
@export var seconds_per_nugget: float = 1.5

var current: float = 0.0
var is_exhausted: bool = false
var _idle_seconds: float = 0.0


func _ready() -> void:
	current = max_nuggets
	_idle_seconds = recover_delay


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_idle_seconds += delta
	if _idle_seconds < recover_delay or current >= max_nuggets:
		return
	if seconds_per_nugget <= 0.0:
		return

	current = min(max_nuggets, current + delta / seconds_per_nugget)
	# Exhaustion clears only once a WHOLE nugget is back. Clearing it the
	# instant regeneration ticked would strobe the penalty on and off several
	# times a second, which looks like a bug.
	if is_exhausted and current >= 1.0:
		_set_exhausted(false)
	changed.emit(current, max_nuggets)


func fraction() -> float:
	return clampf(current / max_nuggets, 0.0, 1.0)


func spend(nuggets: float) -> void:
	if nuggets <= 0.0:
		return
	current = max(0.0, current - nuggets)
	_idle_seconds = 0.0
	if current <= 0.0 and not is_exhausted:
		_set_exhausted(true)
	changed.emit(current, max_nuggets)


func spend_for_attack() -> void:
	spend(attack_cost)


## Drains at the running rate. Returns false when there is nothing left to
## spend, which is how the mover knows to drop back to a walk.
func drain_for_run(delta: float) -> bool:
	if is_exhausted or current <= 0.0:
		return false
	spend(run_drain * delta)
	return true


func has_any() -> bool:
	return current > 0.0 and not is_exhausted


## Multiplier to apply to movement speed and to swing timing.
func effort_multiplier() -> float:
	return tired_multiplier if is_exhausted else 1.0


func refill() -> void:
	current = max_nuggets
	_idle_seconds = recover_delay
	if is_exhausted:
		_set_exhausted(false)
	changed.emit(current, max_nuggets)


func _set_exhausted(value: bool) -> void:
	is_exhausted = value
	exhausted_changed.emit(value)
