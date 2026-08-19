extends Node

## What the player is carrying: the pack, what is worn, and what is held.
##
## Two rules are worth knowing before changing anything here.
##
## First, the hotbar is not a separate container. Belt slots 1 to 9 ARE pack
## slots 0 to 8, the same array, so dragging between them needs no code at all
## and the player can see which pack slots the number keys are bound to.
##
## Second, bare hands are the ABSENCE of a weapon, not a weapon you own. The
## original minted a fresh "Bare hands" object every time the player unequipped,
## and because that object claimed to be a sword, the swap routine put it in the
## pack - which duplicated swords endlessly. Here [member weapon] is simply null
## when nothing is held, and the fallback lives on the attack component where it
## can never be stored.

const PACK_SIZE := 50
## Belt slots. The first this many pack slots are bound to the number keys.
const BELT_SIZE := 9

var pack: Array[ItemStack] = []
var weapon: ItemStack = null
var secondary: ItemStack = null

## ArmorData.Slot -> ItemStack
var worn: Dictionary = {}


func _ready() -> void:
	clear()
	_give_starting_kit()


## What Nestor sets out with: the lamp and torch on the belt, one dose of soul
## powder, and the short sword in hand. All by id, so a designer re-kits the
## start by editing which items exist, not this code.
func _give_starting_kit() -> void:
	var lamp := ItemDb.get_item(&"lamp")
	var torch := ItemDb.get_item(&"torch")
	var soul := ItemDb.get_item(&"soul")
	if lamp != null:
		pack[0] = ItemStack.of(lamp, 1)
	if torch != null:
		pack[1] = ItemStack.of(torch, 1)
	if soul != null:
		pack[2] = ItemStack.of(soul, 3)
	var sword := ItemDb.get_item(&"sword")
	if sword is WeaponData:
		weapon = ItemStack.of(sword, 1)
	_changed()


func clear() -> void:
	pack.clear()
	pack.resize(PACK_SIZE)
	weapon = null
	secondary = null
	worn.clear()
	_changed()


# --- Reading ----------------------------------------------------------------

func slot(index: int) -> ItemStack:
	if index < 0 or index >= pack.size():
		return null
	return pack[index]


func is_belt_slot(index: int) -> bool:
	return index >= 0 and index < BELT_SIZE


func first_free_slot() -> int:
	for i in range(pack.size()):
		if pack[i] == null:
			return i
	return -1


func is_full() -> bool:
	return first_free_slot() == -1


func count_of(item_id: StringName) -> int:
	var total := 0
	for stack in pack:
		if stack != null and stack.item != null and stack.item.id == item_id:
			total += stack.amount
	return total


func has_item(item_id: StringName) -> bool:
	return count_of(item_id) > 0


## Total armour from every worn piece.
func armor_total() -> int:
	var total := 0
	for stack: ItemStack in worn.values():
		if stack != null and stack.item is ArmorData:
			total += (stack.item as ArmorData).armor
	return total


func worn_in(armor_slot: ArmorData.Slot) -> ItemStack:
	return worn.get(armor_slot, null)


# --- Adding and removing ----------------------------------------------------

## Adds as many as will fit. Returns the number that did NOT fit, so 0 means the
## whole pickup was taken. Refusing loudly is better than silently eating items.
func add(item: ItemData, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return amount
	var remaining := amount

	if item.is_stackable():
		for stack in pack:
			if remaining <= 0:
				break
			if stack != null and stack.item != null and stack.item.matches(item):
				var moved: int = min(stack.room_left(), remaining)
				stack.amount += moved
				remaining -= moved

	while remaining > 0:
		var free := first_free_slot()
		if free == -1:
			break
		var taken: int = min(item.max_stack, remaining)
		pack[free] = ItemStack.of(item, taken)
		remaining -= taken

	if remaining < amount:
		EventBus.item_picked_up.emit(item, amount - remaining)
		_changed()
	if remaining > 0:
		EventBus.pickup_refused.emit(item)
	return remaining


## Removes up to [param amount]. Returns how many were actually removed.
func remove(item_id: StringName, amount: int = 1) -> int:
	var removed := 0
	for i in range(pack.size()):
		if removed >= amount:
			break
		var stack := pack[i]
		if stack == null or stack.item == null or stack.item.id != item_id:
			continue
		var take: int = min(stack.amount, amount - removed)
		stack.amount -= take
		removed += take
		if stack.amount <= 0:
			pack[i] = null
	if removed > 0:
		_changed()
	return removed


func clear_slot(index: int) -> void:
	if index < 0 or index >= pack.size():
		return
	pack[index] = null
	_changed()


# --- Moving things about ----------------------------------------------------

## Swaps two pack slots, merging instead when they hold the same stackable item.
## This is the whole of drag-and-drop, belt included, because the belt is part
## of the pack.
func move(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or from_index >= pack.size():
		return
	if to_index < 0 or to_index >= pack.size():
		return

	var source := pack[from_index]
	var target := pack[to_index]
	if source == null:
		return

	if target != null and target.can_merge_with(source):
		target.merge_from(source)
		if source.amount <= 0:
			pack[from_index] = null
	else:
		pack[from_index] = target
		pack[to_index] = source
	_changed()


# --- Wearing and holding ----------------------------------------------------

## Puts the stack in the given pack slot into the slot it belongs in. Whatever
## was there goes back to the pack slot it came from, so nothing is ever lost
## and nothing is ever duplicated.
func equip_from_pack(index: int) -> bool:
	var stack := slot(index)
	if stack == null or stack.item == null:
		return false

	var item := stack.item
	if item is WeaponData:
		pack[index] = weapon
		weapon = stack
	elif item is ArmorData:
		var armor_slot: ArmorData.Slot = (item as ArmorData).slot
		pack[index] = worn.get(armor_slot, null)
		worn[armor_slot] = stack
	else:
		return false

	_changed()
	EventBus.equipment_changed.emit()
	return true


## Takes the held weapon off and puts it in the pack. Does nothing when the pack
## is full, rather than dropping it on the floor.
func unequip_weapon() -> bool:
	if weapon == null:
		return false
	var free := first_free_slot()
	if free == -1:
		EventBus.toast("Your pack is full.")
		return false
	pack[free] = weapon
	weapon = null
	_changed()
	EventBus.equipment_changed.emit()
	return true


func unequip_worn(armor_slot: ArmorData.Slot) -> bool:
	var stack: ItemStack = worn.get(armor_slot, null)
	if stack == null:
		return false
	var free := first_free_slot()
	if free == -1:
		EventBus.toast("Your pack is full.")
		return false
	pack[free] = stack
	worn.erase(armor_slot)
	_changed()
	EventBus.equipment_changed.emit()
	return true


## The weapon currently held, or null for bare hands. Callers that need a
## weapon to swing should fall back to their own unarmed definition.
func held_weapon() -> WeaponData:
	if weapon == null or weapon.item == null:
		return null
	return weapon.item as WeaponData


func swap_weapons() -> void:
	var held := weapon
	weapon = secondary
	secondary = held
	_changed()
	EventBus.equipment_changed.emit()


# --- Using ------------------------------------------------------------------

## Uses whatever is in a pack slot: wears it, holds it, or drinks it.
func use_slot(index: int) -> bool:
	var stack := slot(index)
	if stack == null or stack.item == null:
		return false

	var item := stack.item
	if item is WeaponData or item is ArmorData:
		return equip_from_pack(index)

	if item.heal_amount > 0:
		EventBus.emit_event(&"item_consumed", { "item": item.id, "heal": item.heal_amount })
	if item.use_event != &"":
		EventBus.emit_event(item.use_event, { "item": item.id })

	if item.consume_on_use:
		stack.amount -= 1
		if stack.amount <= 0:
			pack[index] = null
		_changed()
	return true


func _changed() -> void:
	EventBus.inventory_changed.emit()
