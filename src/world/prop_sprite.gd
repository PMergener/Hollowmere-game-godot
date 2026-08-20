@tool
class_name PropSprite
extends Node2D

## A thing standing in the world: a tree, a rock, a crate. Drop the scene into a
## map, move it, and it is placed - where you drag it IS where it is, which is
## the whole point of building maps in the editor instead of in coordinate tables.
##
## The sprite is anchored at its FEET (bottom-centre), so the node's own y is its
## sort key and it slots correctly in front of or behind the player. At run time
## it plants a blocking rectangle at its base so you cannot walk through it; in
## the editor it just shows the art, updating live as you swap the texture.

## The art. Swap this in the inspector to change which tree or rock this is.
@export var texture: Texture2D:
	set(value):
		texture = value
		_refresh()

## Ticked, the base blocks movement. Clear it for pure decoration.
@export var blocks: bool = true
## Footprint of the blocking rectangle, in pixels, at the sprite's feet - roughly
## the trunk or base, not the whole canopy: you walk behind the top of a tree.
@export var collision_size: Vector2 = Vector2(16.0, 10.0)
## Nudges the feet up or down if the art's base is not at its very bottom edge.
@export var foot_trim: float = 0.0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	if blocks and texture != null:
		CollisionMap.add_solid(footprint())


func _refresh() -> void:
	var art := get_node_or_null(^"Art") as Sprite2D
	if art == null:
		return
	art.texture = texture
	if texture != null:
		# Anchor by the feet: shift the sprite up half its height so its bottom
		# edge sits on the node origin.
		art.centered = true
		art.offset = Vector2(0.0, -texture.get_height() * 0.5 + foot_trim)


## The blocking rectangle in world space, centred on the feet.
func footprint() -> Rect2:
	var w := collision_size.x
	var h := collision_size.y
	return Rect2(global_position.x - w * 0.5, global_position.y - h, w, h)
