class_name LootComponent
extends Node2D

## What a thing leaves behind.
##
## Attach to an enemy, a barrel, a chest. It does not care why it was asked to
## pay out, so the same component covers a skeleton dying and a crate being
## smashed.

## What may drop. Leave empty for something that drops nothing but experience.
@export var loot: LootTable

## The thing spawned per item. One scene serves every item; which item it is
## comes from the ItemData handed to it.
@export var pickup_scene: PackedScene
## The thing spawned for coins.
@export var coin_scene: PackedScene

@export_group("Scatter")
## Drops land within this many pixels, so a full table does not stack into one
## unreadable pile.
@export var scatter_radius: float = 12.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## Pays out. [param into] is the node the drops are added to - normally the
## area, so they survive the thing that dropped them being freed.
func drop(into: Node = null) -> void:
	if loot == null:
		return

	var parent := into if into != null else get_tree().current_scene
	if parent == null:
		push_warning("LootComponent on '%s' has nowhere to put its drops." % name)
		return

	if loot.xp > 0:
		PlayerProgress.add_xp(loot.xp)
	if loot.embers > 0:
		PlayerProgress.add_embers(loot.embers)

	for entry in loot.roll_items(_rng):
		_spawn(pickup_scene, parent, entry["item"], entry["amount"])

	var coins := loot.roll_coins(_rng)
	if coins > 0:
		_spawn(coin_scene, parent, null, coins)


func _spawn(scene: PackedScene, parent: Node, item: ItemData, amount: int) -> void:
	if scene == null:
		push_warning("LootComponent on '%s' has no scene set for one of its drops." % name)
		return
	var node := scene.instantiate()
	parent.add_child(node)
	if node is Node2D:
		var offset := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
		(node as Node2D).global_position = global_position + offset * scatter_radius
	if node.has_method(&"configure"):
		node.call(&"configure", item, amount)
