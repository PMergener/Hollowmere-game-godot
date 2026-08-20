extends Node

## Every skill, loaded from res://data/skills, plus the one query the game asks of
## them: how much of a given effect the player has bought. A skill names an effect
## (light_radius, lamp_regen, soul_steal) and a magnitude per rank; this sums the
## ranks owned so the lamp, the regen and the kill-heal read one number each.

var _skills: Dictionary = {}


func _ready() -> void:
	_skills = ResourceDir.load_by_id("res://data/skills")


func all() -> Array:
	return _skills.values()


func by_id(id: StringName) -> SkillData:
	return _skills.get(id)


## Total magnitude of an effect across every skill that grants it, weighted by the
## ranks the player owns. 0 when nothing granting it has been bought.
func effect_total(effect: StringName) -> float:
	var total := 0.0
	for s: SkillData in _skills.values():
		if s.effect == effect:
			total += PlayerProgress.rank_of(s) * s.magnitude_per_rank
	return total
