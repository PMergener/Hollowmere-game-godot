class_name Wander
extends RefCounted

## Idle wandering, shared by villagers and by ghosts at rest.
##
## Ported from the HTML build's pickTarget: it aims at open, reachable ground
## near home rather than a random point that might sit behind a wall, so a
## wanderer never grinds into a house for a minute trying to reach the far side
## of it. The actual stepping is the caller's - this only chooses where to go.

var home: Vector2
var target: Vector2
var wait: float = 0.0


func _init(home_pos: Vector2) -> void:
	home = home_pos
	target = home_pos


## Chooses a new reachable target within [param radius] of home. Returns false
## only when nowhere open could be found, which effectively never happens.
func pick(from: Vector2, radius: float, body_radius: float = 7.0,
		bounds: float = 1200.0) -> bool:
	var fallback := Vector2.INF
	for k in range(18):
		var a := randf() * TAU
		var r := 30.0 + randf() * radius
		var tx := clampf(home.x + cos(a) * r, 24.0, bounds - 24.0)
		var ty := clampf(home.y + sin(a) * r, 24.0, bounds - 24.0)
		if CollisionMap.blocked(tx, ty, 8.0):
			continue
		if fallback == Vector2.INF:
			fallback = Vector2(tx, ty)
		if CollisionMap.los_clear(from, Vector2(tx, ty), body_radius):
			target = Vector2(tx, ty)
			return true
	if fallback != Vector2.INF:
		target = fallback
		return true
	# Last resort: somewhere we can definitely reach from right here.
	for k in range(24):
		var a := randf() * TAU
		var r := 16.0 + randf() * 70.0
		var tx := clampf(from.x + cos(a) * r, 24.0, bounds - 24.0)
		var ty := clampf(from.y + sin(a) * r, 24.0, bounds - 24.0)
		if not CollisionMap.blocked(tx, ty, 8.0) and CollisionMap.los_clear(from, Vector2(tx, ty), body_radius):
			target = Vector2(tx, ty)
			return true
	target = from
	return false
