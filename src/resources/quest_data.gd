class_name QuestData
extends Resource

## One entry in the journal.
##
## A quest counts one kind of thing. What it counts is decided by the Event it
## listens for: an enemy of the right id dying, an item being picked up, a
## trigger being walked into. Anything that emits that event advances it, so a
## designer can hook a quest to a new thing without touching quest code.

enum StartState {
	## Not in the journal, and not offered. Something must reveal it.
	HIDDEN,
	## Visible as unavailable. Use for the second half of a chain.
	LOCKED,
	## Offered by its giver the first time they are spoken to.
	AVAILABLE,
}

@export var id: StringName = &""
@export var title: String = "Untitled quest"
## The name shown as the source in the journal.
@export var giver: String = ""
## The single line under the title. Keep it short: the scroll wraps it, but a
## long objective still reads as a paragraph the player must decode.
@export_multiline var objective: String = ""

@export_group("Progress")
## The event that counts toward this quest, for example wraith_killed. Anything
## in the game that emits this name will advance it.
@export var counts_event: StringName = &""
## How many before it is done.
@export var required_count: int = 1

@export_group("Rewards")
@export var xp_reward: int = 0
@export var gold_reward: int = 0
@export var item_rewards: Array[ItemData] = []

@export_group("Chain")
@export var start_state: StartState = StartState.AVAILABLE
## Quests revealed when this one is handed in.
@export var unlocks: Array[QuestData] = []
