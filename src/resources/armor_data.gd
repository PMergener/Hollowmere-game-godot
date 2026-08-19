class_name ArmorData
extends ItemData

## A piece of kit that sits in one of the equipment slots.

enum Slot {
	HEAD,
	TORSO,
	LEGS,
	BOOTS,
	## The over-armour slot: mail, plate. Separate from TORSO on purpose, so
	## the starting clothes are never taken off to wear armour.
	BODY,
}

@export var slot: Slot = Slot.BODY
## Subtracted from every hit before it reaches health.
@export var armor: int = 0
## Multiplies movement speed. Leave at 1.0 unless the piece should feel heavy.
@export_range(0.5, 1.5, 0.05) var move_multiplier: float = 1.0
