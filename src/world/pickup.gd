class_name Pickup
extends Node2D

## Something lying on the ground waiting to be walked over: soul powder off a
## slain wraith, a coin, a tear. Walk within reach and it goes into the pack.
##
## The item it holds is named by id, so a designer drops "one soul, three coins"
## by id and this looks the metadata up in [ItemDb] - it hard-codes no item.

@export var item_id: StringName = &"soul"
@export var amount: int = 1
## How close Nestor must be to sweep it up.
@export var reach: float = 14.0

var age: float = 0.0
var ph: float = 0.0
var _player: Node2D
var _item: ItemData


func _ready() -> void:
	ph = randf() * TAU
	add_to_group(&"drops")
	_item = ItemDb.get_item(item_id)
	_player = get_tree().get_first_node_in_group(&"player") as Node2D


func _process(delta: float) -> void:
	age += delta
	if _player != null and is_instance_valid(_player):
		if global_position.distance_to(_player.global_position) <= reach:
			_collect()
			return
	queue_redraw()


func _collect() -> void:
	if _item == null:
		queue_free()
		return
	var left := Inventory.add(_item, amount)
	if left >= amount:
		return  # pack full - leave it lying, try again next frame
	Sfx.play(&"pickup")
	var got := amount - left
	EventBus.toast("%s%s" % [_item.display_name, ("  x%d" % got) if got > 1 else ""])
	queue_free()


func _draw() -> void:
	var pu := 0.55 + 0.45 * sin(age * 2.6 + ph)
	var lift := sin(age * 1.7 + ph) * 1.8
	draw_rect(Rect2(-5, 1, 11, 3), Color(0, 0, 0, 0.4), true)
	if item_id == &"soul":
		# The green mote, procedural like the HTML drop - it pulses, so it stays
		# procedural rather than an icon.
		draw_rect(Rect2(-3, -5 + lift, 6, 6), Color(150.0/255, 236.0/255, 182.0/255, 0.30 + 0.22 * pu), true)
		draw_rect(Rect2(-2, -4 + lift, 4, 4), Color(226.0/255, 1.0, 238.0/255, 0.65 + 0.35 * pu), true)
		for i in 4:
			var a := age * 1.9 + i * 1.57 + ph
			draw_rect(Rect2(cos(a) * 6, -2 + sin(a) * 3 + lift, 1, 1),
				Color(160.0/255, 240.0/255, 190.0/255, 0.25 + 0.3 * pu), true)
	else:
		ItemIcons.draw_icon(self, String(item_id), 0.0, -6.0 + lift * 0.5, 0.8)
		if amount > 1:
			draw_rect(Rect2(4, -9 + lift * 0.5, 2, 2), Color(0.9, 0.86, 0.5), true)
