class_name DamageInfo
extends RefCounted

## One blow, on its way from whatever swung to whatever is about to be hit.
##
## Passed as an object rather than a bare number so that adding knockback, or a
## damage type, or "this one ignores armour" later does not mean changing every
## function between the sword and the health bar.

var amount: int = 0
## The node that caused it. May be null for the world hurting you.
var source: Node = null
## Where the blow came from, for knockback and for the direction of the flinch.
var origin: Vector2 = Vector2.ZERO
var knockback: float = 0.0
## Ticked, armour does not reduce it. Drowning, falling, a curse.
var ignores_armor: bool = false


static func make(damage_amount: int, from: Node = null, at: Vector2 = Vector2.ZERO) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = damage_amount
	info.source = from
	info.origin = at
	return info
