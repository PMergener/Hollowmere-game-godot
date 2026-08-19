class_name LootTable
extends Resource

## What a thing leaves behind when it dies or breaks.
##
## Every entry rolls independently, so a table can drop several things at once.
## Give a barrel a table with one entry at 0.25 and it behaves exactly like the
## barrels in the original game.

@export var entries: Array[LootEntry] = []
## Experience granted on top of the items.
@export var xp: int = 0
## Soul embers, the currency skills are bought with.
@export var embers: int = 0
@export var coin_min: int = 0
@export var coin_max: int = 0


## Returns an array of { "item": ItemData, "amount": int }.
func roll_items(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in entries:
		if entry == null:
			continue
		var amount := entry.roll(rng)
		if amount > 0:
			out.append({ "item": entry.item, "amount": amount })
	return out


func roll_coins(rng: RandomNumberGenerator) -> int:
	if coin_max <= 0:
		return 0
	return rng.randi_range(coin_min, max(coin_min, coin_max))
