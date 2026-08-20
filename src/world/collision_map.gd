extends Node

## The one place that answers "can something stand here?".
##
## Ported directly from the HTML build's blocked() / moveEntity() / losClear()
## rather than rebuilt on Godot physics, and kept as an autoload so the player,
## every enemy and every wanderer ask the SAME authority the SAME way. That is
## what stops the player and a skeleton disagreeing about where a wall is.
##
## Each area rebuilds the solids when it loads. The rectangles are the houses'
## footprints and anything else that blocks - the drawn walls need none, because
## the world edge is refused by bounds below.

var solids: Array[Rect2] = []
var world_size: float = 1200.0
var edge: float = 36.0


func set_solids(rects: Array[Rect2], size: float = 1200.0, edge_margin: float = 36.0) -> void:
	solids = rects
	world_size = size
	edge = edge_margin


## Drops every solid, for when a new area is about to register its own. Props
## and walls in the arriving scene add themselves back through [method add_solid].
func clear_solids(size: float = 1200.0, edge_margin: float = 36.0) -> void:
	solids = []
	world_size = size
	edge = edge_margin


## Adds one blocking rectangle - a placed tree's trunk, a chest's footprint. The
## rectangle is in world space; a prop computes it from where it was dropped.
func add_solid(rect: Rect2) -> void:
	solids.append(rect)


## Removes a rectangle a prop added, for a crate that has just been smashed. The
## prop passes back the exact rect it registered, so the match is precise.
func remove_solid(rect: Rect2) -> void:
	solids.erase(rect)


## blocked(x, y, r) from the HTML build, including the asymmetric vertical test.
## The 0.7 and the -3 push the collision box down to the figure's FEET, so a
## top-down sprite reads as standing behind what it overlaps, not floating in it.
func blocked(x: float, y: float, r: float = 6.0) -> bool:
	for s in solids:
		if x + r > s.position.x and x - r < s.position.x + s.size.x \
		   and y + r * 0.7 > s.position.y and y - 3.0 < s.position.y + s.size.y:
			return true
	return x < edge or y < edge or x > world_size - edge or y > world_size - edge


## Straight-line walkability, sampled every ~10px. Not pathfinding - just enough
## to keep a wanderer from choosing a spot behind a house and grinding the wall.
func los_clear(a: Vector2, b: Vector2, r: float) -> bool:
	var d := a.distance_to(b)
	var steps := int(maxf(2.0, d / 10.0))
	for i in range(1, steps + 1):
		var p := a.lerp(b, float(i) / steps)
		if blocked(p.x, p.y, r):
			return false
	return true


## Steps toward a target and returns how far it ACTUALLY got, sliding along
## whatever it hits. Measuring displacement rather than trusting the move is what
## makes an enemy notice it is stuck against a corner.
func move_entity(pos: Vector2, dir: Vector2, step: float, r: float) -> Dictionary:
	var start := pos
	var p := pos
	if not blocked(p.x + dir.x * step, p.y, r):
		p.x += dir.x * step
	if not blocked(p.x, p.y + dir.y * step, r):
		p.y += dir.y * step
	var gained := start.distance_to(p)
	if gained < step * 0.35:
		p = start
		for slide: Vector2 in [Vector2(-dir.y, dir.x), Vector2(dir.y, -dir.x)]:
			var s: Vector2 = start + slide * step * 1.15
			if not blocked(s.x, s.y, r):
				p = s
				gained = start.distance_to(p)
				break
	return {"pos": p, "gained": gained}


## Failsafe: if something ends up inside geometry, spiral out to open ground.
func unstick(pos: Vector2, r: float) -> Vector2:
	if not blocked(pos.x, pos.y, r):
		return pos
	var ring := 4.0
	while ring <= 64.0:
		for k in range(16):
			var a := k * 0.3927 + ring * 0.7
			var p := pos + Vector2(cos(a), sin(a)) * ring
			if not blocked(p.x, p.y, r):
				return p
		ring += 4.0
	return pos
