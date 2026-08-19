class_name MeleeAttack
extends Node2D

## A sword swing: the wind-up, the strike, the recovery, and the arc it sweeps.
##
## Attached as a child of whatever swings - the player now, and any enemy later.
## It owns the swing STATE and the swing GEOMETRY; the body that carries it asks
## for [method blade_angle] and [method swing_extension] to draw the sword, and
## this queries who the strike lands on. Keeping it off the actor keeps the actor
## from turning into the every-system dumping ground the HTML player became.
##
## Anything hittable joins the group in [member target_group] and answers
## [code]take_melee_hit(damage, from_position)[/code].

signal strike_began()
signal target_hit(target: Node)

# The three phases, in seconds. They read as the weight of the weapon: a slow
# wind, a fast bite, a heavier recovery you can be punished during.
const WIND := 0.13
const STRIKE := 0.10
const RECOVER := 0.17

# Where the blade sits through the swing, as angle offsets from the facing.
const WIND_OFF := -1.52
const END_OFF := 1.34
const REST_TILT := 0.42

# The arc the cleave sweeps. Radius grows with the swing; the cone is ~1.6rad.
const ARC_BASE := 20.0
const ARC_SPAN := 4.0

## Default cooldown between swings, before stamina slows it.
@export var cooldown_seconds: float = 0.44
## Damage a landed hit deals. The player keeps this in step with its weapon.
@export var damage: int = 8
## Added to the blade's reach, in pixels. 0 for a short sword, 5 for a long one.
@export var reach: float = 0.0
## Everything hittable is in this group.
@export var target_group: StringName = &"hurtable"

var active: bool = false
var phase: String = "idle"
var t: float = 0.0
var cd: float = 0.0
var dir: int = 0
var lean: Vector2 = Vector2.ZERO

var _hits: Array = []
var _actor: Actor


func _ready() -> void:
	_actor = get_parent() as Actor
	set_notify_transform(false)


## True when a new swing may begin.
func can_swing() -> bool:
	return not active and cd <= 0.0


## Starts a swing in [param facing]. [param rate] below 1 stretches the whole
## swing - an exhausted attack is slower to wind, land AND recover, not merely
## slower to start.
func swing(facing: int) -> bool:
	if not can_swing():
		return false
	active = true
	phase = "wind"
	t = 0.0
	dir = facing
	_hits.clear()
	return true


## Advances the swing. [param rate] is the stamina multiplier (1 rested, 0.7
## tired). Returns a camera-shake strength to apply this frame, or 0.
func step(delta: float, rate: float, moving: bool, walk_phase: float) -> float:
	if cd > 0.0:
		cd = maxf(0.0, cd - delta)
	lean = Vector2.ZERO
	var shake := 0.0
	if not active:
		return shake

	t += delta * rate
	var a: float = Figure.DIRA[dir]
	var cs := cos(a)
	var sn := sin(a)
	match phase:
		"wind":
			var p := t / WIND
			lean = Vector2(-cs, -sn) * 2.4 * p
			if t >= WIND:
				phase = "strike"
				t = 0.0
				shake = 1.0
		"strike":
			var p := t / STRIKE
			lean = Vector2(cs, sn) * 3.3 * p
			_query_hits(moving, walk_phase)
			if t >= STRIKE:
				phase = "recover"
				t = 0.0
		_:
			var p := 1.0 - t / RECOVER
			lean = Vector2(cs, sn) * 3.3 * p * 0.6
			if t >= RECOVER:
				phase = "idle"
				active = false
	queue_redraw()
	return shake


func swing_extension() -> float:
	if not active:
		return 0.0
	if phase == "wind":
		return 0.55 * _ease_out(t / WIND)
	if phase == "strike":
		return 0.55 + 0.45 * (t / STRIKE)
	return maxf(0.0, 1.0 - t / RECOVER)


func rest_angle(d: int) -> float:
	return PI / 2.0 + (REST_TILT if Figure.SIDE[d] < 0 else -REST_TILT)


## The angle the drawn sword points, for the body to render the blade.
func blade_angle(cur_dir: int) -> float:
	var d := dir if active else cur_dir
	var a: float = Figure.DIRA[d]
	var r := rest_angle(d)
	if not active:
		return r
	if phase == "wind":
		return r + (a + WIND_OFF - r) * _ease_out(t / WIND)
	if phase == "strike":
		return a + WIND_OFF + (END_OFF - WIND_OFF) * _ease_in(t / STRIKE)
	var e := a + END_OFF
	return e + (r - e) * _ease_out(t / RECOVER)


func arc_radius() -> float:
	return ARC_BASE + ARC_SPAN * swing_extension() + reach


func _cleave_lead() -> float:
	var a: float = Figure.DIRA[dir]
	if phase == "strike":
		return a + WIND_OFF + (END_OFF - WIND_OFF) * _ease_in(t / STRIKE)
	return a + END_OFF


## Returns {span, fade}, or an empty dict when nothing should draw.
func _cleave_span() -> Dictionary:
	if phase == "strike":
		return {"span": 0.30 + 1.30 * (t / STRIKE), "fade": 1.0}
	if phase == "recover":
		return {"span": 1.60, "fade": maxf(0.0, 1.0 - (t / RECOVER) / 0.55)}
	return {}


## The pivot the arc sweeps around, in the actor's local space (feet at origin).
func pivot_local(moving: bool, walk_phase: float) -> Vector2:
	var bob := 1.0 if (moving and sin(walk_phase * 18.0) > 0.4) else 0.0
	return lean + Vector2(Figure.SIDE[dir], -bob - 16.0)


func _query_hits(moving: bool, walk_phase: float) -> void:
	if _actor == null:
		return
	var pv := pivot_local(moving, walk_phase) + _actor.position
	var lead := _cleave_lead()
	var span_data := _cleave_span()
	if span_data.is_empty():
		return
	var span: float = span_data.span
	var reach_r := arc_radius() + 14.0
	for node in get_tree().get_nodes_in_group(target_group):
		if node in _hits or not node.has_method(&"take_melee_hit"):
			continue
		var off := 18.0
		if node.has_method(&"melee_hit_offset"):
			off = node.melee_hit_offset()
		var target_pos: Vector2 = node.global_position if node is Node2D else Vector2.ZERO
		var d := Vector2(target_pos.x - pv.x, (target_pos.y - off) - pv.y)
		var dist := d.length()
		if dist < 7.0 or dist > reach_r:
			continue
		var ad := wrapf(atan2(d.y, d.x) - lead, -PI, PI)
		if ad > 0.30 or ad < -(span + 0.30):
			continue
		_hits.append(node)
		node.take_melee_hit(damage, _actor.position)
		target_hit.emit(node)


func begin_cooldown(rate: float) -> void:
	cd = cooldown_seconds / maxf(0.01, rate)


func _draw() -> void:
	var span_data := _cleave_span()
	if span_data.is_empty():
		return
	var span: float = span_data.span
	var fade: float = span_data.fade
	var moving := _actor.moving if _actor != null else false
	var walk_phase := _actor.step if _actor != null else 0.0
	var pv := pivot_local(moving, walk_phase)
	var lead := _cleave_lead()
	var ar := arc_radius()
	var n := 40
	for i in range(n + 1):
		var f := float(i) / n
		var ang := lead - span * (1.0 - f)
		var taper := sin(PI * pow(f, 0.62))
		var half := 0.5 + taper * 4.0
		var a := (0.10 + 0.90 * pow(f, 1.7)) * fade
		if a < 0.03:
			continue
		var cs := cos(ang)
		var sn := sin(ang)
		var d := -half
		while d <= half:
			var edge := absf(d) / (half + 0.001)
			var br := 1.0 - edge * 0.55
			var col := Color(
				(214.0 + 41.0 * br) / 255.0,
				(226.0 + 29.0 * br) / 255.0,
				(240.0 + 15.0 * br) / 255.0,
				a * br)
			draw_rect(Rect2(roundf(pv.x + cs * (ar + d)), roundf(pv.y + sn * (ar + d)), 1, 1), col, true)
			d += 1.0
	if phase == "strike":
		var cs := cos(lead)
		var sn := sin(lead)
		draw_rect(Rect2(roundf(pv.x + cs * ar - 1), roundf(pv.y + sn * ar - 1), 3, 3), Color.WHITE, true)
		draw_rect(Rect2(roundf(pv.x + cs * (ar + 4)), roundf(pv.y + sn * (ar + 4)), 1, 1), Color(1, 1, 1, 0.5), true)


func _ease_out(p: float) -> float:
	return 1.0 - pow(1.0 - p, 2.4)


func _ease_in(p: float) -> float:
	return p * p
