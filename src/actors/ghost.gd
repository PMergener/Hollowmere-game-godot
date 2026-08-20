class_name Ghost
extends Enemy

## The wraith, and the whole point of the lamp.
##
## You cannot see it, cannot touch it, in the dark. Raise the green lamp and it
## fades into view within the light - and can be cut. But hold the light on it
## and it WAKES: exposure builds, and past the limit it turns and comes for you,
## fast, hitting harder than anything else in the village. That is the wager the
## game is built on. Every reveal is also an alarm.

const HP := 15.0
const EXPOSE_LIMIT := 3.6
const DMG_MIN := 24
const DMG_MAX := 40
const XP := 5
# Reveal rides the lamp's own radius (LAMP_R 93 * 0.88), so widening the lamp
# widens what you can see AND what you wake - the skill cannot lie about that.
const REVEAL := 93.0 * 0.88

var ph: float = 0.0
var seed_i: int = 0
var spd: float = 20.0
var exp_time: float = 0.0
var atk_cd: float = 0.0
var wait: float = 0.0
var respawn: float = 0.0
var _wander: Wander


func _ready() -> void:
	super()
	max_hp = HP
	hp = HP
	xp_reward = XP
	enemy_id = &"wraith"
	body_radius = 12.0
	move_speed = spd
	ph = randf() * TAU
	_wander = Wander.new(position)


func melee_hit_offset() -> float:
	return 18.0


# The shriek is the alarm, and it has to sound whether the wraith wakes by being
# HELD in the lamp past the limit or by being CUT - and cutting it is the common
# case, so the old code (which only shrieked on the exposure path) meant most
# wraiths went hostile in silence. Waking is one place now, reached from both.
func _wake() -> void:
	spd = 39.0 + randf() * 15.0
	Sfx.play(&"shriek")
	Sfx.play(&"growl", -6.0)
	EventBus.toast("It has seen you.")


func take_melee_hit(damage: int, from_position: Vector2) -> void:
	if not is_hittable():
		return
	var was_hostile := hostile
	super(damage, from_position)
	if not was_hostile and not gone:
		_wake()


func is_hittable() -> bool:
	return not gone and dying <= 0.0 and alpha() > 0.15


## The lamp light on this wraith, 0 to 1. Zero unless the green lamp is raised
## and this one is inside its reveal radius.
func lamp_alpha() -> float:
	if gone or player == null or player.held_light != "lamp":
		return 0.0
	var d := position.distance_to(player.position)
	var reveal := REVEAL * _light_scale()
	if d > reveal:
		return 0.0
	return minf(1.0, (reveal - d) / 33.0)


## What actually gets drawn: the lamp reveal, plus a faint shape when it is on
## top of you enraged, plus the bright flare of dying.
func alpha() -> float:
	if gone:
		return 0.0
	var a := lamp_alpha()
	if hostile and player != null:
		var d := position.distance_to(player.position)
		if d < 45.0:
			a = maxf(a, 0.42 * (1.0 - d / 45.0))
	if dying > 0.0:
		a = maxf(a, 0.8) * (dying / 0.55)
	return a


func _light_scale() -> float:
	# Thy Flame widens the reveal exactly as it widens the light - a bigger lamp
	# that revealed no more wraiths would be a lie about the skill.
	return 1.0 + SkillDb.effect_total(&"light_radius")


func _death_seconds() -> float:
	return 0.55


func _think(delta: float) -> void:
	var lit := lamp_alpha()
	if lit > 0.35:
		exp_time += delta * lit
	else:
		exp_time = maxf(0.0, exp_time - delta * 0.4)

	if not hostile and exp_time >= EXPOSE_LIMIT:
		hostile = true
		_wake()

	if atk_cd > 0.0:
		atk_cd -= delta

	if hostile and player != null and not player.dead:
		var to := player.position - position
		var d := to.length()
		if d > 0.001:
			facing = dir_from_vector(to)
		if d > 16.0:
			position += to / maxf(d, 0.001) * spd * delta
		elif atk_cd <= 0.0:
			atk_cd = 1.5 + randf() * 0.5
			Sfx.play(&"growl")
			player.take_damage(DMG_MIN + randi() % (DMG_MAX - DMG_MIN + 1))
		return

	# At rest: a slow, aimless drift between open points.
	if wait > 0.0:
		wait -= delta
		return
	var d := position.distance_to(_wander.target)
	if d < 6.0:
		wait = 1.5 + randf() * 4.0
		_wander.pick(position, 150.0, 7.0, WorldData.WORLD)
		return
	var step_v := (_wander.target - position).normalized() * spd * delta
	position += step_v
	facing = dir_from_vector(step_v)


func _on_vanished() -> void:
	# A soul-powder mote always, and a crystalized tear to carry off.
	_drop(&"soul", 1, Vector2(-4, 6))
	_drop(&"tear", 1, Vector2(11, 5))
	respawn = 15.0 + randf() * 12.0


func _drop(id: StringName, amount: int, offset: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var p := Pickup.new()
	p.item_id = id
	p.amount = amount
	p.position = position + offset
	parent.add_child(p)


func _while_gone(delta: float) -> void:
	respawn -= delta
	if respawn > 0.0:
		return
	for k in range(40):
		var a := randf() * TAU
		var r := 240.0 + randf() * 250.0
		var nx := 600.0 + cos(a) * r
		var ny := 600.0 + sin(a) * r
		if nx < 70.0 or ny < 70.0 or nx > WorldData.WORLD - 70.0 or ny > WorldData.WORLD - 70.0:
			continue
		if CollisionMap.blocked(nx, ny, 12.0):
			continue
		if player != null and Vector2(nx, ny).distance_to(player.position) < 260.0:
			continue
		position = Vector2(nx, ny)
		_wander.home = position
		_wander.target = position
		gone = false
		hp = HP
		exp_time = 0.0
		hostile = false
		hurt = 0.0
		atk_cd = 0.0
		wait = 1.0 + randf() * 3.0
		spd = 14.0 + randf() * 10.0
		return
	respawn = 3.0


func _draw() -> void:
	var a := alpha()
	if a <= 0.01:
		return
	var fl := sin(t * 1.5 + ph) * 3.0
	var rage := hostile
	var hit := hurt > 0.0

	var shade := func(v: float) -> Color:
		var r := v
		var g := v
		var b := v
		if rage:
			r = minf(255.0, v * 1.05 + 40.0); g = v * 0.60; b = v * 0.56
		if hit:
			r = minf(255.0, v + 60.0); g = minf(255.0, v * 0.8 + 40.0); b = minf(255.0, v * 0.8 + 40.0)
		return Color(r / 255.0, g / 255.0, b / 255.0, a * 0.94)

	var HI: Color = shade.call(214.0)
	var MD: Color = shade.call(178.0)
	var SH: Color = shade.call(140.0)
	var DK: Color = shade.call(104.0)
	var OUT := Color(10.0 / 255, 10.0 / 255, 12.0 / 255, a * 0.92)
	var BLK := Color(8.0 / 255, 8.0 / 255, 10.0 / 255, a * 0.96)
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), ceilf(w), ceilf(h)), c, true)

	# feet shadow, unfloated
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, a * 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var y := fl  # the body floats; everything below is local to the feet
	R.call(-7, y - 38, 14, 3, OUT)
	R.call(-10, y - 36, 3, 4, OUT)
	R.call(7, y - 36, 3, 4, OUT)
	R.call(-12, y - 33, 3, 20, OUT)
	R.call(9, y - 33, 3, 20, OUT)

	R.call(-9, y - 35, 18, 24, MD)
	R.call(-9, y - 35, 7, 24, HI)
	R.call(5, y - 35, 4, 24, SH)
	R.call(-7, y - 37, 14, 3, MD)
	R.call(-7, y - 37, 6, 3, HI)
	R.call(-4, y - 38, 8, 1, HI)
	R.call(-11, y - 33, 2, 20, SH)
	R.call(9, y - 33, 2, 20, DK)

	var tips := [-9, -4, 1, 6]
	for i in range(tips.size()):
		var tx: float = tips[i]
		var wob := sin(t * 2.4 + i * 1.35 + ph)
		var length := 8.0 + wob * 3.0 + (3.0 if (i == 1 or i == 2) else 0.0)
		var w := 4.0
		var j := 0
		while j < length:
			var ww := maxf(1.0, w - floorf(j / 3.0))
			var ox := roundf(wob * j * 0.16)
			var col: Color = (MD if j < length * 0.5 else SH) if i < 2 else (SH if j < length * 0.5 else DK)
			R.call(tx + ox, y - 12 + j, ww, 1, col)
			R.call(tx + ox - 1, y - 12 + j, 1, 1, OUT)
			R.call(tx + ox + ww, y - 12 + j, 1, 1, OUT)
			j += 1
		R.call(tx + roundf(wob * length * 0.16), y - 12 + length, maxf(1.0, w - 2.0), 1, OUT)

	var blink := sin(t * 0.9 + seed_i) > -0.92
	if blink:
		R.call(-6, y - 31, 5, 6, BLK)
		R.call(-7, y - 30, 1, 4, BLK)
		R.call(-5, y - 32, 3, 1, BLK)
		R.call(2, y - 31, 5, 6, BLK)
		R.call(7, y - 30, 1, 4, BLK)
		R.call(3, y - 32, 3, 1, BLK)
		if rage:
			R.call(-5, y - 30, 2, 2, Color(226.0 / 255, 72.0 / 255, 52.0 / 255, a))
			R.call(3, y - 30, 2, 2, Color(226.0 / 255, 72.0 / 255, 52.0 / 255, a))
	R.call(-2, y - 23, 5, 4, BLK)
	R.call(-1, y - 24, 3, 1, BLK)
	R.call(-1, y - 19, 3, 1, BLK)
