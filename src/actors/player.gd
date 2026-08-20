class_name Player
extends Actor

## Nestor. Movement, the lamp, stamina, and the hand that holds the sword.
##
## Everything with real behaviour of its own lives elsewhere - the swing is a
## [MeleeAttack] child, collision is [CollisionMap], the light is a PointLight2D.
## What stays here is only translating input into calls on those, which is the
## discipline the HTML build's all-knowing player never had.

const SPD := 78.0
const AIM_DEAD_ZONE := 6.0

var lamp_max := 100.0
const LAMP_DRAIN := 2.0
const LAMP_REGEN := 1.0

# Stamina: ten nuggets, held as a float. Empty makes you slow, never helpless.
const STAM_N := 10.0
const STAM_ATTACK := 1.0 / 3.0
const STAM_RUN := 1.0
const RUN_MULT := 1.5
const TIRED_MULT := 0.7
const STAM_DELAY := 3.0
const STAM_RATE := 1.0 / 1.5

var hp := 150.0
var hp_max := 150.0
var hurt := 0.0
var heal := 0.0
var denied := 0.0
var dead := false

var lamp_on := false
var lamp := 100.0
var held_light := ""

var stam := STAM_N
var tired := false
var _stam_idle := STAM_DELAY

var can_act := true

var tex_lamp: Texture2D
var tex_torch: Texture2D

var _aim := Vector2.DOWN
var _shake := 0.0
var _steal_t := 0.0

@onready var light: PointLight2D = $Light
@onready var melee: MeleeAttack = $Melee


func _ready() -> void:
	add_to_group(&"player")
	move_speed = SPD
	# A landed blow bites the camera harder than the swing alone and rings the
	# steel; the swing whoosh is fired when the swing starts.
	melee.target_hit.connect(func(_target):
		_shake = maxf(_shake, 1.3)
		Sfx.play(&"hit"))
	# Soul Steal: a kill starts 3 seconds of healing (5 HP/s), refreshing.
	EventBus.enemy_died.connect(func(_id, _pos):
		if SkillDb.effect_total(&"soul_steal") > 0.0:
			_steal_t = 3.0)
	# Vigour and lamp capacity grow with the level. The progression already knows
	# the numbers (+12 HP, +4 lamp a level); the player just has to apply them, and
	# a level's worth of each is healed on the way up - the HTML's applyLevelReward.
	hp_max = float(PlayerProgress.max_health())
	lamp_max = 100.0 + float(PlayerProgress.lamp_bonus())
	EventBus.level_gained.connect(_on_level_gained)
	EventBus.player_spawned.emit(self)


func _on_level_gained(_new_level: int) -> void:
	var old_hp_max := hp_max
	var old_lamp_max := lamp_max
	hp_max = float(PlayerProgress.max_health())
	lamp_max = 100.0 + float(PlayerProgress.lamp_bonus())
	hp = minf(hp_max, hp + (hp_max - old_hp_max))
	lamp = minf(lamp_max, lamp + (lamp_max - old_lamp_max))


func _process(delta: float) -> void:
	t += delta
	if hurt > 0.0:
		hurt = maxf(0.0, hurt - delta * 1.6)
	if heal > 0.0:
		heal = maxf(0.0, heal - delta * 1.4)
	if denied > 0.0:
		denied = maxf(0.0, denied - delta * 2.0)
	if _steal_t > 0.0 and not dead:
		_steal_t -= delta
		hp = minf(hp_max, hp + 5.0 * delta)  # Soul Steal, 5 HP/s

	_update_aim()
	var running := _handle_movement(delta)
	_update_stamina(delta, running)

	var shake := melee.step(delta, stamina_rate(), moving, step)
	if shake > 0.0:
		_shake = maxf(_shake, shake)
	_apply_shake(delta)

	if can_act and Input.is_action_just_pressed(&"attack"):
		_try_swing()
	if can_act and Input.is_action_just_pressed(&"toggle_lamp"):
		_toggle_light("lamp")
	if Input.is_action_just_pressed(&"toggle_mute"):
		Sfx.toggle_mute()

	_update_lamp(delta)
	_update_light()
	queue_redraw()


func _handle_movement(delta: float) -> bool:
	if not can_act or melee.active:
		moving = false
		return false
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if input.length_squared() <= 0.01:
		moving = false
		return false

	var running := Input.is_action_pressed(&"run") and not tired and stam > 0.0
	var scale := (RUN_MULT if running else 1.0) * stamina_rate()
	walk(input, delta, scale)
	# The mouse aims the facing, not the direction of travel - it makes lining a
	# swing up far easier.
	facing = dir_from_vector(_aim)
	return running


func _try_swing() -> void:
	if not melee.can_swing():
		return
	_spend_stamina(STAM_ATTACK)
	# The swing carries the equipped weapon's damage plus levelled edge - not the
	# component's own default. Without this the sword dealt the MeleeAttack default
	# (8) instead of the short sword's 5, and wraiths (15 HP) died in 2 hits, not 3.
	melee.damage = _swing_damage()
	melee.swing(facing)
	melee.begin_cooldown(stamina_rate())
	Sfx.play(&"swing")


## Damage a swing deals: the held weapon (or 1 for bare hands) plus levelled edge.
## Mirrors the HTML's weaponDmg() = EQUIP.weapon.dmg + edgeBonus.
func _swing_damage() -> int:
	var weapon := Inventory.held_weapon()
	var base := weapon.damage if weapon != null else 1
	return base + PlayerProgress.damage_bonus()


func _update_aim() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() >= AIM_DEAD_ZONE:
		_aim = to_mouse


func stamina_rate() -> float:
	return TIRED_MULT if tired else 1.0


func _spend_stamina(n: float) -> void:
	stam = maxf(0.0, stam - n)
	_stam_idle = 0.0
	if stam <= 0.0:
		tired = true


func _update_stamina(delta: float, running: bool) -> void:
	if running:
		_spend_stamina(STAM_RUN * delta)
	# Exhaustion clears only once a WHOLE nugget is back, or it strobes.
	if tired and stam >= 1.0:
		tired = false
	_stam_idle += delta
	if _stam_idle >= STAM_DELAY and stam < STAM_N:
		stam = minf(STAM_N, stam + STAM_RATE * delta)


func _update_lamp(delta: float) -> void:
	if held_light == "lamp":
		lamp = maxf(0.0, lamp - LAMP_DRAIN * delta)
		if lamp <= 0.0:
			lamp_on = false
			held_light = ""
	elif lamp < lamp_max:
		# Perseverance adds to the stowed regen rate (1/s base, +2 per rank).
		var regen := LAMP_REGEN + SkillDb.effect_total(&"lamp_regen")
		lamp = minf(lamp_max, lamp + regen * delta)


func _update_light() -> void:
	if held_light == "":
		light.enabled = false
		return
	light.enabled = true
	# Thy Flame widens what the light reaches (+25% per rank), scaling the pool.
	light.texture_scale = 1.0 + SkillDb.effect_total(&"light_radius")
	if held_light == "lamp":
		if tex_lamp != null and light.texture != tex_lamp:
			light.texture = tex_lamp
		light.color = Color(0.78, 0.98, 0.86)
		var low := clampf(lamp / 25.0, 0.35, 1.0)
		var flick := 1.0 + sin(t * 2.6) * 0.045 + sin(t * 5.9) * 0.022
		light.energy = 1.05 * low * flick
	else:
		if tex_torch != null and light.texture != tex_torch:
			light.texture = tex_torch
		light.color = Color(1.00, 0.80, 0.52)
		light.energy = 1.02 * (1.0 + sin(t * 8.3) * 0.035 + sin(t * 17.1) * 0.02
			+ sin(t * 3.3) * 0.03)


func _apply_shake(delta: float) -> void:
	if _shake <= 0.0:
		return
	var cam := get_node_or_null(^"Camera") as Camera2D
	if cam != null:
		# A fast coherent tremor, exactly as the HTML build: a high-frequency
		# sine on each axis. Coherent back-and-forth reads as a shake where
		# per-frame random noise just reads as a blur.
		cam.offset = Vector2(sin(t * 97.0) * _shake * 2.0, cos(t * 83.0) * _shake * 1.6)
	_shake = maxf(0.0, _shake - delta * 7.0)
	if _shake <= 0.0 and cam != null:
		cam.offset = Vector2.ZERO


## Using any pack slot: the lamp and torch toggle the light, soul powder heals,
## anything else (a weapon, armour) falls through to the pack's own use. The
## branching lives here because a "use" acts on the player - its light, its
## health - not on the pack. Shared by the belt keys and the pack panel.
func use_item_slot(index: int) -> void:
	var st := Inventory.slot(index)
	if st == null or st.item == null:
		return
	var id := st.item.id
	if id == &"soul":
		consume_soul()
	elif id == &"lamp" or id == &"torch":
		_toggle_light(String(id))
	else:
		Inventory.use_slot(index)


func _toggle_light(kind: String) -> void:
	if held_light == kind:
		held_light = ""
	elif kind == "torch" or lamp > 1.0:
		held_light = kind
	lamp_on = held_light == "lamp"


func consume_soul() -> bool:
	if dead or Inventory.count_of(&"soul") <= 0:
		return false
	if hp >= hp_max:
		denied = 0.5
		Sfx.play(&"denied")
		return false
	Inventory.remove(&"soul", 1)
	hp = minf(hp_max, hp + 40.0)
	heal = 0.7
	Sfx.play(&"heal")
	return true


func take_damage(dmg: float, _armour: float = 0.0) -> void:
	if dead:
		return
	# Armour subtracts flat from every blow, floor of 1 - the HTML's hurtPlayer.
	# A 24-40 wraith hit lands 19-35 through the base kit's 5; plate makes it hurt
	# less, but nothing ever makes you immune.
	hp = maxf(0.0, hp - maxf(1.0, dmg - Inventory.armor_total()))
	hurt = 0.55
	_shake = maxf(_shake, 1.7)
	Sfx.play(&"hurt")
	if hp <= 0.0:
		dead = true
		EventBus.player_died.emit()


func _draw() -> void:
	# The lean is the lunge: the body pushes into the wind-up and drives through
	# the strike, so a swing reads as weight thrown, not an arm waved.
	Figure.draw_body(self, facing, step * 9.0, moving, Figure.PAL_PLAYER, {
		"eyes": "red",
		"light": held_light,
		"blade": true,
		"blade_angle": melee.blade_angle(facing),
		"swing_ext": melee.swing_extension(),
		"reach": melee.reach,
	}, t, melee.lean)
	# A red wash over the body the instant a blow lands on you.
	if hurt > 0.0:
		draw_rect(Rect2(-9, -38, 18, 40), Color(0.85, 0.1, 0.1, hurt * 0.5), true)
