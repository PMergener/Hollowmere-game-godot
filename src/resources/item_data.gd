@icon("res://icon.svg")
class_name ItemData
extends Resource

## Anything that can sit in a backpack slot.
##
## Create one of these per item (Right-click in FileSystem -> New Resource ->
## ItemData) and save it under res://data/items/. Nothing about an item is
## written in code: the name shown to the player, its icon, what it sells for
## and whether it stacks all live on this file.

## Internal name. Must be unique, lowercase, no spaces. Quests and shops refer
## to items by this, so renaming one breaks the things that point at it.
@export var id: StringName = &""

## The name the player reads, in the pack and in the shop.
@export var display_name: String = "Unnamed item"

## Shown under the name when the item is examined. Keep it to a line or two.
@export_multiline var description: String = ""

## Extra line that appears above the item when the mouse rests on it. Leave
## empty for most things; use it when an item should feel like it is watching
## back, e.g. "It pulses with a strange energy".
@export_multiline var hover_hint: String = ""

@export_group("Appearance")
@export var icon: Texture2D
## Drawn on the ground before it is picked up. Falls back to the icon.
@export var world_texture: Texture2D

@export_group("Stacking")
## 1 means every one takes its own slot. Coins and powders should stack.
@export_range(1, 999) var max_stack: int = 1

@export_group("Trade")
## What Ondrick pays for it. 0 and the shop will not take it.
@export var sell_price: int = 0
## What he charges. 0 means it is not for sale.
@export var buy_price: int = 0
## Off for story items that must never leave the player's hands.
@export var can_sell: bool = true

@export_group("Behaviour")
## Ticked, using the item removes one from the stack.
@export var consume_on_use: bool = false
## Health restored on use. 0 for anything that is not a remedy.
@export var heal_amount: int = 0


## True when two stacks are the same thing and may be merged.
func matches(other: ItemData) -> bool:
	return other != null and other.id == id


func is_stackable() -> bool:
	return max_stack > 1
