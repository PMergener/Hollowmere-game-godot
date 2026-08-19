class_name WeaponData
extends ItemData

## A weapon. Extends ItemData, so it also has a name, an icon and a price.
##
## Reach and arc are what make two swords feel different. Damage alone does not:
## a long sword that swings in the same place as a short one just reads as a
## bigger number. Change reach first.

enum SwingStyle {
	## Short arc in front of the body. The short sword.
	THRUST,
	## Wide arc that sweeps across the facing. The long sword.
	CLEAVE,
	## No arc at all; fires a projectile. The bow.
	RANGED,
}

@export_group("Damage")
@export var damage: int = 5
## Added to the swing arc, in pixels, measured from the hand. This is the
## number that decides whether a weapon feels long.
@export var reach: float = 21.0
## Seconds before it can swing again.
@export var cooldown: float = 0.44
## Nuggets of stamina a swing costs. The bar holds ten.
@export var stamina_cost: float = 0.333

@export_group("Swing")
@export var style: SwingStyle = SwingStyle.THRUST
## How wide the arc is, in degrees, centred on the facing.
@export_range(0.0, 360.0, 1.0) var arc_degrees: float = 90.0
## Wind-up, contact and recovery, in seconds. They read as weight.
@export var windup: float = 0.13
@export var strike: float = 0.10
@export var recover: float = 0.17

@export_group("Ranged", "ranged_")
## Only used when Style is RANGED.
@export var ranged_projectile: PackedScene
@export var ranged_speed: float = 190.0
@export var ranged_range: float = 220.0
## Movement multiplier while the weapon is drawn. Below 1 the player slows.
@export_range(0.1, 1.0, 0.05) var ranged_move_multiplier: float = 0.8


func total_swing_time() -> float:
	return windup + strike + recover


func is_ranged() -> bool:
	return style == SwingStyle.RANGED
