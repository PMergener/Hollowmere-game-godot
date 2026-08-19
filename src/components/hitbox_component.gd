class_name HitboxComponent
extends Area2D

## The part of a swing that does the striking.
##
## Off by default and switched on for the length of a blow, so a sword resting
## in a hand is not quietly killing things. Each activation remembers who it has
## already hit, which is what stops one swing from landing four times as the
## shapes keep overlapping.

signal hit_landed(target: HurtboxComponent, landed: int)

## Who swung. Passed along so nothing can hit itself and so the killer is known.
@export var source: Node

@export_group("Damage")
@export var damage: int = 5
@export var knockback: float = 0.0
@export var ignores_armor: bool = false

## Turned on and off by whatever owns the swing.
var is_active: bool = false

var _already_hit: Array[HurtboxComponent] = []


func _ready() -> void:
	monitoring = false
	if source == null:
		source = get_parent()
	area_entered.connect(_on_area_entered)


## Opens the window. Call at the moment of contact, not at the wind-up.
func activate() -> void:
	_already_hit.clear()
	is_active = true
	monitoring = true
	# Anything already overlapping when the window opens will not emit
	# area_entered, so sweep once by hand.
	for area in get_overlapping_areas():
		_try_hit(area)


func deactivate() -> void:
	is_active = false
	monitoring = false
	_already_hit.clear()


## Opens the window for a fixed time. Convenient for simple attacks.
func strike_for(seconds: float) -> void:
	activate()
	await get_tree().create_timer(seconds).timeout
	deactivate()


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)


func _try_hit(area: Area2D) -> void:
	if not is_active:
		return
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or _already_hit.has(hurtbox):
		return
	# Never let a swing land on the thing that swung it.
	if source != null and hurtbox.is_ancestor_of(source):
		return
	if source != null and source.is_ancestor_of(hurtbox):
		return

	_already_hit.append(hurtbox)

	var info := DamageInfo.make(damage, source, global_position)
	info.knockback = knockback
	info.ignores_armor = ignores_armor

	var landed := hurtbox.take_hit(info)
	if landed > 0:
		hit_landed.emit(hurtbox, landed)
