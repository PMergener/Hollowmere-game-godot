class_name ProgressionData
extends Resource

## The levelling curve and what each level is worth.
##
## Kept as a resource so the curve can be retuned without touching code. The
## original game used 50 experience for level two and multiplied by 1.85 each
## level after; those are the defaults here.

@export_group("Curve")
@export var xp_for_level_two: int = 50
## Each level costs this much more than the last, compounding.
@export var xp_multiplier: float = 1.85
@export_range(1, 99) var max_level: int = 10

@export_group("Per level")
@export var health_per_level: int = 12
@export var lamp_charge_per_level: int = 4
## A point of weapon damage every N levels.
@export var damage_every_n_levels: int = 2

@export_group("Starting values")
@export var starting_health: int = 150
@export var starting_gold: int = 0
@export var starting_embers: int = 0


## Experience needed to go from the given level to the next one.
func xp_to_reach(level: int) -> int:
	if level < 1:
		return 0
	var need := float(xp_for_level_two)
	for _i in range(level - 1):
		need = ceil(need * xp_multiplier)
	return int(need)


## Bonus weapon damage earned by reaching this level.
func damage_bonus_at(level: int) -> int:
	if damage_every_n_levels <= 0:
		return 0
	return (level - 1) / damage_every_n_levels


func max_health_at(level: int) -> int:
	return starting_health + (level - 1) * health_per_level
