class_name LootEntry
extends Resource

## One line of a loot table: what may drop, and how often.

@export var item: ItemData
## 0.25 means a quarter of kills. 1.0 always drops.
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
@export var min_amount: int = 1
@export var max_amount: int = 1


## Rolls this entry. Returns 0 when it did not drop.
func roll(rng: RandomNumberGenerator) -> int:
	if item == null or rng.randf() > chance:
		return 0
	return rng.randi_range(min_amount, max(min_amount, max_amount))
