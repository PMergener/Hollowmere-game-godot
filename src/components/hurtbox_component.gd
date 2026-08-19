class_name HurtboxComponent
extends Area2D

## The part of a body that can be struck.
##
## Separate from the collision shape that stops it walking through walls,
## because they want different sizes: a wraith should be easy to hit and hard to
## bump into. Point it at a HealthComponent and anything that lands here is
## passed along.

signal hit_taken(info: DamageInfo, landed: int)

@export var health: HealthComponent
## Ticked, blows are ignored entirely. For a boss in a cutscene, or a corpse.
@export var immune: bool = false


func _ready() -> void:
	if health == null:
		# Nearly always the right guess, and saves wiring it by hand on every
		# enemy. A warning rather than an error: some hurtboxes are decorative.
		health = _find_sibling_health()
	if health == null:
		push_warning("Hurtbox on '%s' has no HealthComponent; hits will do nothing." % owner_name())


func take_hit(info: DamageInfo) -> int:
	if immune or health == null:
		return 0
	var landed := health.take_damage(info)
	if landed > 0:
		hit_taken.emit(info, landed)
	return landed


func _find_sibling_health() -> HealthComponent:
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is HealthComponent:
			return child
	return null


func owner_name() -> String:
	return get_parent().name if get_parent() != null else name
