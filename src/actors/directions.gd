class_name Directions
extends Object

## The four facings, and the one place that turns a vector into one of them.
##
## Every actor - the player following the mouse, an enemy following the player -
## needs the same "which of four ways am I pointing" answer, and it must be the
## same answer everywhere or a sprite faces one way while its sword swings
## another. So it lives here and nowhere else.

enum Dir { DOWN, UP, LEFT, RIGHT }

## Suffixes used to build animation names: "walk_" + this.
const NAMES := {
	Dir.DOWN: "down",
	Dir.UP: "up",
	Dir.LEFT: "left",
	Dir.RIGHT: "right",
}

const VECTORS := {
	Dir.DOWN: Vector2.DOWN,
	Dir.UP: Vector2.UP,
	Dir.LEFT: Vector2.LEFT,
	Dir.RIGHT: Vector2.RIGHT,
}


## The facing that best matches a movement or aim vector. Vertical wins ties, to
## match the original: the body reads as facing up or down unless clearly aside.
static func from_vector(v: Vector2, fallback: Dir = Dir.DOWN) -> Dir:
	if v.length_squared() < 0.0001:
		return fallback
	if absf(v.x) > absf(v.y):
		return Dir.RIGHT if v.x > 0.0 else Dir.LEFT
	return Dir.DOWN if v.y > 0.0 else Dir.UP


static func to_name(dir: Dir) -> String:
	return NAMES[dir]


static func to_vector(dir: Dir) -> Vector2:
	return VECTORS[dir]
