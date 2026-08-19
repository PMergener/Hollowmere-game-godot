class_name Actor
extends Node2D

## Anything that walks the world: the player, a villager, a skeleton.
##
## Movement goes through [CollisionMap], not Godot physics, so every mover obeys
## the one collision authority ported from the HTML build. The base owns only
## position, facing and the walk phase; what an actor WANTS to do is decided by
## the player's input or an enemy's brain, never here.

## Pixels per second at a walk.
@export var move_speed: float = 60.0
## Collision radius passed to [CollisionMap]. Feet-sized, not body-sized.
@export var body_radius: float = 6.0

## 0 down, 1 up, 2 left, 3 right - the HTML build's facing indices, kept so the
## art code (Figure) needs no translation.
var facing: int = 0
var moving: bool = false
var step: float = 0.0
var t: float = 0.0


## Slides in a direction this frame, stopped by walls. Returns distance covered,
## which a brain can watch to notice it has run into something.
func walk(dir: Vector2, delta: float, speed_scale: float = 1.0) -> float:
	if dir.length_squared() <= 0.0001:
		moving = false
		return 0.0
	dir = dir.normalized()
	facing = dir_from_vector(dir)
	moving = true
	step += delta
	var res := CollisionMap.move_entity(position, dir, move_speed * speed_scale * delta, body_radius)
	position = res.pos
	return res.gained


## Turns to face a vector without moving. Vertical wins a tie, which stops the
## sprite flickering between facings on a clean diagonal.
static func dir_from_vector(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return 3 if v.x > 0.0 else 2
	return 0 if v.y > 0.0 else 1


func face_toward(v: Vector2) -> void:
	facing = dir_from_vector(v)


func face_direction(v: Vector2) -> void:
	face_toward(v)
