@tool
class_name Chest
extends PropSprite

## A chest - a lootable container, never a crate. Drop it in a map, set what is
## inside, and it opens once when the player acts on it, paying out its coins and
## items. It blocks like any prop, and dims when emptied so a looted chest reads
## as spent at a glance.

## Coins paid straight into the purse on opening.
@export var coins: int = 5
## Items dropped into the pack on opening. Leave empty for a coins-only chest.
@export var contents: Array[ItemData] = []
## How close the player must be to open it.
@export var interact_radius: float = 24.0

var _opened := false


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	add_to_group(&"interactable")


func interact_prompt() -> String:
	return "Open"


func can_interact() -> bool:
	return not _opened


func interact(_by: Node) -> void:
	if _opened:
		return
	_opened = true
	if coins > 0:
		PlayerProgress.add_gold(coins)
	for item in contents:
		Inventory.add(item, 1)
	Sfx.play(&"coin")
	var what := "%d coins" % coins if coins > 0 else "something"
	if not contents.is_empty():
		what = contents[0].display_name
	EventBus.toast("Opened the chest - %s" % what)
	modulate = Color(0.55, 0.55, 0.55)  # spent
