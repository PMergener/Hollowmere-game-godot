extends Node

## The one place systems talk to each other. Holds no state and knows nothing
## about the game - it only carries messages.
##
## Why this exists: the original was 618 globals that all reached into one
## another, so moving anything broke something else. Here, a wraith dying does
## not call the quest log. It announces that it died, and whatever cares is
## listening. Nothing needs to know who else is in the room.
##
## The important one is [signal game_event]. It is deliberately generic so a
## designer can invent a new thing to count without anyone writing code for it:
## a trigger volume, a broken barrel and a dead skeleton all announce themselves
## the same way, and a quest that counts that name will advance.

## Something happened that other systems may care about. [param name] is a free
## label, e.g. "wraith_killed", "entered_graveyard", "sigil_taken".
signal game_event(name: StringName, payload: Dictionary)

@warning_ignore_start("unused_signal")

# --- The player -------------------------------------------------------------

signal player_spawned(player: Node)
signal player_damaged(amount: int, remaining: int)
signal player_healed(amount: int, remaining: int)
signal player_died()
signal player_respawned()
## Fired when the player has no stamina left, and again when it recovers.
signal player_exhausted(is_exhausted: bool)

# --- Progression ------------------------------------------------------------

signal xp_gained(amount: int)
signal level_gained(new_level: int)
## Gold or soul embers changed. Read the current values off PlayerProgress.
signal currency_changed()

# --- Carrying things --------------------------------------------------------

signal inventory_changed()
signal equipment_changed()
signal item_picked_up(item: ItemData, amount: int)
## The pack was full and the pickup was refused.
signal pickup_refused(item: ItemData)

# --- Quests -----------------------------------------------------------------

signal quest_offered(quest: QuestData)
signal quest_accepted(quest: QuestData)
signal quest_progressed(quest: QuestData, count: int)
signal quest_ready_to_hand_in(quest: QuestData)
signal quest_completed(quest: QuestData)

# --- The world --------------------------------------------------------------

signal enemy_died(enemy_id: StringName, world_position: Vector2)
signal area_entered(area_id: StringName)
signal area_exited(area_id: StringName)
## Asks the camera for a knock. Amount is in pixels.
signal shake_requested(amount: float, seconds: float)

# --- Talking and reading ----------------------------------------------------

signal dialogue_started(dialogue: DialogueData, speaker_name: String)
signal dialogue_finished()
signal note_read(title: String, body: String)
## A line of feedback across the middle of the screen.
signal toast_requested(text: String)
## The action available on whatever the player is standing next to, or "" when
## there is nothing to act on. Drives the little "[E] Speak" prompt.
signal interaction_prompt(text: String)

@warning_ignore_restore("unused_signal")


## Announce something. Prefer this over inventing a new signal: a name costs
## nothing and anything can listen for it.
func emit_event(name: StringName, payload: Dictionary = {}) -> void:
	if name == &"":
		push_warning("EventBus.emit_event called with an empty name; ignored.")
		return
	game_event.emit(name, payload)


## Convenience for the commonest piece of feedback.
func toast(text: String) -> void:
	toast_requested.emit(text)
