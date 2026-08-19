class_name LampComponent
extends Node2D

## The light the player carries, and the wager attached to it.
##
## Holding it up is the only way to see and the only way to burn a wraith, but
## it burns down while raised and only refills while stowed. That trade is the
## game: every moment of safety is bought with the thing that keeps you safe.
##
## The light itself is a PointLight2D child, so its texture, colour and energy
## are all set in the editor rather than in code.

signal charge_changed(current: float, maximum: float)
signal raised_changed(is_raised: bool)
## The lamp ran dry and dropped on its own.
signal burned_out()

@export var light: PointLight2D

@export_group("Charge")
@export var max_charge: float = 100.0
## Charge burned per second while raised.
@export var drain_per_second: float = 2.0
## Charge recovered per second while stowed.
@export var regen_per_second: float = 1.0
## Ticked, the lamp cannot be raised again until it has this much back. Stops
## the player from flickering it on for a frame at a time on an empty tank.
@export var relight_threshold: float = 5.0

@export_group("Reach")
## Radius in pixels when raised. The light texture is scaled to match, so this
## one number is the whole of how far you can see.
@export var radius: float = 93.0
## Radius while stowed. Not zero: total blindness is not tense, it is unplayable.
@export var stowed_radius: float = 26.0
@export var transition_seconds: float = 0.18

var charge: float = 0.0
var is_raised: bool = false
var _current_radius: float = 0.0


func _ready() -> void:
	charge = max_charge
	_current_radius = stowed_radius
	_apply_radius(_current_radius)


func _process(delta: float) -> void:
	if is_raised:
		charge = max(0.0, charge - drain_per_second * delta)
		if charge <= 0.0:
			set_raised(false)
			burned_out.emit()
	else:
		charge = min(max_charge, charge + regen_per_second * delta)
	charge_changed.emit(charge, max_charge)

	var target := radius if is_raised else stowed_radius
	if not is_equal_approx(_current_radius, target):
		var rate: float = absf(radius - stowed_radius) / maxf(0.01, transition_seconds)
		_current_radius = move_toward(_current_radius, target, rate * delta)
		_apply_radius(_current_radius)


func can_raise() -> bool:
	return charge >= relight_threshold


func set_raised(value: bool) -> void:
	if value and not can_raise():
		return
	if is_raised == value:
		return
	is_raised = value
	raised_changed.emit(value)


func toggle() -> void:
	set_raised(not is_raised)


func fraction() -> float:
	return clampf(charge / max_charge, 0.0, 1.0)


## True when a point in the world is inside the lit circle. Wraiths ask this to
## find out whether they are burning.
func lights(world_position: Vector2) -> bool:
	return global_position.distance_to(world_position) <= _current_radius


func current_radius() -> float:
	return _current_radius


func add_max_charge(amount: float) -> void:
	max_charge += amount
	charge = min(max_charge, charge + amount)
	charge_changed.emit(charge, max_charge)


func _apply_radius(value: float) -> void:
	if light == null or light.texture == null:
		return
	# The light texture is authored square; scale it so its half-width matches
	# the radius we want. Doing it here means the radius is the only number a
	# designer has to think about.
	var half := float(light.texture.get_width()) * 0.5
	if half <= 0.0:
		return
	light.texture_scale = value / half
