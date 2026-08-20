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
## Soul embers dropped on death, the currency skills are bought with. Wraith 3,
## skeleton and zombie 5, per the HTML.
@export var ember_reward: int = 3
## The id announced on death, so quests can count "wraith_killed" without code.
@export var enemy_id: StringName = &"enemy"
## An extra event fired on death, for a quest that counts a MIX of foes - the
## undercroft's "clear it" vow counts skeletons and zombies alike, so both carry
## "undercroft_kill". Left empty for most enemies.
@export var death_event_extra: StringName = &""

@export_group("Melee AI")
## Used by the default chase-and-strike brain (skeletons, zombies, the boss). The
## wraith ignores all of this and overrides _think with its own drift logic.
@export var chase_speed: float = 42.0
@export var attack_range: float = 22.0
## The tell: how long the blow is wound up before it lands. Longer = easier to
## read and step out of - the zombie's 0.95 vs the skeleton's 0.32.
@export var attack_windup: float = 0.32
@export var attack_recover: float = 0.22
@export var attack_cooldown: float = 2.2
@export var damage_min: int = 28
@export var damage_max: int = 40

var hp: float = 15.0
var hurt: float = 0.0
var hostile: bool = false
var dying: float = 0.0
var gone: bool = false
## 0 at rest, rising through the wind-up and strike so a body can draw its tell.
var swing: float = 0.0
## The lunge, in pixels along the facing: the HTML's skelLean. It pulls the whole
## body BACK on the wind-up, then drives it FORWARD through the strike, then eases
## home on the recover. A draw offset only - the hit itself is the take_damage call.
var body_lean: float = 0.0

var _atk_state := "idle"
var _atk_t := 0.0
var _atk_cd := 0.0


## The unit direction the body faces, for the lunge and anything else that needs it.
func facing_vec() -> Vector2:
	match facing:
		1: return Vector2(0, -1)
		2: return Vector2(-1, 0)
		3: return Vector2(1, 0)
		_: return Vector2(0, 1)


## The lunge offset the draw applies to the whole body, sword and all.
func lunge_offset() -> Vector2:
	return facing_vec() * body_lean

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
	PlayerProgress.add_embers(ember_reward)
	EventBus.enemy_died.emit(enemy_id, position)
	EventBus.emit_event(StringName("%s_killed" % enemy_id), {"position": position})
	if death_event_extra != &"":
		EventBus.emit_event(death_event_extra, {"position": position})
	died.emit()


# --- overridable ------------------------------------------------------------

## What this foe does each live frame. The default is the chase-and-telegraphed-
## strike brain; the wraith overrides it entirely.
func _think(delta: float) -> void:
	_chase_attack(delta)


## Walk toward the player; in range, wind the blow up (the tell), land it, then
## recover and cool down. Shared by every foe that fights with a swing.
func _chase_attack(delta: float) -> void:
	if player == null or player.dead:
		moving = false
		return
	if _atk_cd > 0.0:
		_atk_cd -= delta
	var to := player.position - position
	var d := to.length()
	if d > 0.001:
		facing = dir_from_vector(to)

	const STRIKE_T := 0.12
	match _atk_state:
		"idle":
			body_lean = 0.0
			if d <= attack_range and _atk_cd <= 0.0:
				_atk_state = "wind"
				_atk_t = 0.0
				moving = false
			elif d > attack_range:
				step += delta
				var res := CollisionMap.move_entity(position, to / d, chase_speed * delta, body_radius)
				position = res.pos
				moving = true
			else:
				moving = false
		"wind":
			_atk_t += delta
			swing = clampf(_atk_t / attack_windup, 0.0, 1.0)
			body_lean = -4.0 * swing               # haul the body back as the blade rises
			if _atk_t >= attack_windup:
				_atk_state = "strike"
				_atk_t = 0.0
				EventBus.shake_requested.emit(1.0, 0.2)
		"strike":
			_atk_t += delta
			var sp := clampf(_atk_t / STRIKE_T, 0.0, 1.0)
			body_lean = -4.0 + 11.0 * (sp * sp)    # drive forward through the swing
			# the blow lands at the far point of the lunge, not the instant it starts
			if _atk_t < delta and position.distance_to(player.position) <= attack_range + 10.0:
				player.take_damage(float(randi_range(damage_min, damage_max)))
				_on_attack_land()
			if _atk_t >= STRIKE_T:
				_atk_state = "recover"
				_atk_t = 0.0
		_:
			_atk_t += delta
			var rp := clampf(_atk_t / attack_recover, 0.0, 1.0)
			swing = maxf(0.0, 1.0 - rp)
			body_lean = 7.0 * (1.0 - rp)           # ease home
			if _atk_t >= attack_recover:
				_atk_state = "idle"
				_atk_cd = attack_cooldown
				swing = 0.0
				body_lean = 0.0


## Hook for a body to sound its attack or shake the screen. Base does nothing.
func _on_attack_land() -> void:
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
