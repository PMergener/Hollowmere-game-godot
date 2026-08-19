extends Node

## How far the player has come: level, experience, purse, and skills bought.
##
## Deliberately does NOT know about health, the pack, or quests. Those belong to
## the health component, to Inventory and to QuestLog. Progress only answers
## "how strong am I, and what can I afford".

const DEFAULT_PROGRESSION := "res://data/progression.tres"

var progression: ProgressionData

var level: int = 1
var xp: int = 0
var xp_to_next: int = 50
var gold: int = 0
var embers: int = 0

## skill id -> ranks owned
var _skill_ranks: Dictionary = {}


func _ready() -> void:
	if ResourceLoader.exists(DEFAULT_PROGRESSION):
		progression = load(DEFAULT_PROGRESSION) as ProgressionData
	if progression == null:
		push_warning("No progression.tres found; using built-in defaults.")
		progression = ProgressionData.new()
	reset()


## Back to a new game. Called on start and on death-with-restart.
func reset() -> void:
	level = 1
	xp = 0
	gold = progression.starting_gold
	embers = progression.starting_embers
	xp_to_next = progression.xp_to_reach(1)
	_skill_ranks.clear()
	EventBus.currency_changed.emit()


# --- Experience -------------------------------------------------------------

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	EventBus.xp_gained.emit(amount)
	while xp >= xp_to_next and level < progression.max_level:
		xp -= xp_to_next
		level += 1
		xp_to_next = progression.xp_to_reach(level)
		EventBus.level_gained.emit(level)


## 0 to 1, for the experience bar.
func xp_fraction() -> float:
	if xp_to_next <= 0:
		return 1.0
	return clampf(float(xp) / float(xp_to_next), 0.0, 1.0)


## Bonus damage the player carries into any weapon. Lives here rather than on
## the blade, so swapping weapons never loses it.
func damage_bonus() -> int:
	return progression.damage_bonus_at(level)


func max_health() -> int:
	return progression.max_health_at(level)


func lamp_bonus() -> int:
	return (level - 1) * progression.lamp_charge_per_level


# --- Purse ------------------------------------------------------------------

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	EventBus.currency_changed.emit()


func can_afford(cost: int) -> bool:
	return gold >= cost


## Returns false and changes nothing when the player is short.
func spend_gold(cost: int) -> bool:
	if not can_afford(cost):
		return false
	add_gold(-cost)
	return true


func add_embers(amount: int) -> void:
	embers = max(0, embers + amount)
	EventBus.currency_changed.emit()


# --- Skills -----------------------------------------------------------------

func rank_of(skill: SkillData) -> int:
	if skill == null:
		return 0
	return _skill_ranks.get(skill.id, 0)


func total_ranks() -> int:
	var sum := 0
	for ranks: int in _skill_ranks.values():
		sum += ranks
	return sum


## Every rank already owned makes the next purchase dearer, compounding, so the
## third skill costs the same whichever order they are bought in.
func cost_of(skill: SkillData) -> int:
	if skill == null:
		return 0
	return int(ceil(skill.base_cost * pow(skill.cost_inflation, total_ranks())))


func is_maxed(skill: SkillData) -> bool:
	return skill != null and rank_of(skill) >= skill.max_rank


func can_buy(skill: SkillData) -> bool:
	return skill != null and not is_maxed(skill) and embers >= cost_of(skill)


func buy_skill(skill: SkillData) -> bool:
	if not can_buy(skill):
		return false
	add_embers(-cost_of(skill))
	_skill_ranks[skill.id] = rank_of(skill) + 1
	EventBus.emit_event(&"skill_bought", { "skill": skill.id, "rank": rank_of(skill) })
	return true


## Total magnitude of a named effect across every skill that provides it.
## Ask for "lamp_radius" and get the sum of every rank that widens the lamp.
func effect_total(effect: StringName, skills: Array[SkillData]) -> float:
	var total := 0.0
	for skill in skills:
		if skill != null and skill.effect == effect:
			total += skill.magnitude_per_rank * rank_of(skill)
	return total
