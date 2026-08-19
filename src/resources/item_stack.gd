class_name ItemStack
extends Resource

## A quantity of one item sitting in one slot.
##
## Items themselves (ItemData) are shared, read-only definitions - there is one
## Short sword resource in the whole game. A stack is the mutable thing that
## says how many of it are here.

@export var item: ItemData
@export var amount: int = 1


static func of(source_item: ItemData, count: int = 1) -> ItemStack:
	var stack := ItemStack.new()
	stack.item = source_item
	stack.amount = count
	return stack


func is_empty() -> bool:
	return item == null or amount <= 0


func room_left() -> int:
	if item == null:
		return 0
	return max(0, item.max_stack - amount)


func can_merge_with(other: ItemStack) -> bool:
	return (
		other != null
		and item != null
		and item.is_stackable()
		and item.matches(other.item)
		and room_left() > 0
	)


## Moves as much as will fit out of [param other] into this stack and returns
## how many moved.
func merge_from(other: ItemStack) -> int:
	if not can_merge_with(other):
		return 0
	var moved: int = min(room_left(), other.amount)
	amount += moved
	other.amount -= moved
	return moved


func duplicate_stack() -> ItemStack:
	return ItemStack.of(item, amount)
