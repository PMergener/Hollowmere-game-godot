extends Node

## The journal: which quests exist, where each one stands, and what advances it.
##
## Quests are loaded from res://data/quests/ - drop a .tres in that folder and it
## is in the game. Nothing here knows what a wraith is. A quest names an event
## it counts, and anything at all that emits that event advances it, so hooking
## a quest to a new kind of thing never means editing quest code.

enum State {
	## Not in the journal at all.
	HIDDEN,
	## Known to exist but not yet offerable.
	LOCKED,
	## The giver will offer it.
	AVAILABLE,
	## Taken, and counting.
	ACTIVE,
	## Count reached; go and hand it in.
	READY,
	## Handed in.
	DONE,
}

const QUEST_FOLDER := "res://data/quests"

## id -> QuestData
var _quests: Dictionary = {}
## id -> State
var _state: Dictionary = {}
## id -> int
var _count: Dictionary = {}


func _ready() -> void:
	_quests = ResourceDir.load_by_id(QUEST_FOLDER)
	reset()
	EventBus.game_event.connect(_on_game_event)


func reset() -> void:
	_state.clear()
	_count.clear()
	for id: StringName in _quests:
		var quest: QuestData = _quests[id]
		_state[id] = _initial_state(quest)
		_count[id] = 0


func _initial_state(quest: QuestData) -> State:
	match quest.start_state:
		QuestData.StartState.HIDDEN:
			return State.HIDDEN
		QuestData.StartState.LOCKED:
			return State.LOCKED
		_:
			return State.AVAILABLE


# --- Reading ----------------------------------------------------------------

func by_id(id: StringName) -> QuestData:
	return _quests.get(id, null)


func state_of(quest: QuestData) -> State:
	if quest == null:
		return State.HIDDEN
	return _state.get(quest.id, State.HIDDEN)


func count_of(quest: QuestData) -> int:
	if quest == null:
		return 0
	return _count.get(quest.id, 0)


func is_active(quest: QuestData) -> bool:
	var s := state_of(quest)
	return s == State.ACTIVE or s == State.READY


## Quests the journal should list, in load order.
func visible_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	for id: StringName in _quests:
		var s: State = _state[id]
		if s == State.ACTIVE or s == State.READY or s == State.DONE:
			out.append(_quests[id])
	return out


## The quests a given speaker can offer or take back right now.
func quests_for_giver(giver: String) -> Array[QuestData]:
	var out: Array[QuestData] = []
	for id: StringName in _quests:
		var quest: QuestData = _quests[id]
		if quest.giver != giver:
			continue
		var s: State = _state[id]
		if s == State.AVAILABLE or s == State.READY:
			out.append(quest)
	return out


# --- Changing state ---------------------------------------------------------

## Brings a hidden or locked quest into play.
func reveal(quest: QuestData) -> void:
	if quest == null:
		return
	var s := state_of(quest)
	if s != State.HIDDEN and s != State.LOCKED:
		return
	_state[quest.id] = State.AVAILABLE
	EventBus.quest_offered.emit(quest)


## Reveals AND starts a quest in one step, for things discovered in the world
## rather than handed out by a person - a sigil stirring at a warded door.
func begin(quest: QuestData) -> void:
	if quest == null or state_of(quest) == State.DONE:
		return
	reveal(quest)
	accept(quest)


func accept(quest: QuestData) -> void:
	if quest == null or state_of(quest) != State.AVAILABLE:
		return
	_state[quest.id] = State.ACTIVE
	_count[quest.id] = 0
	EventBus.quest_accepted.emit(quest)
	EventBus.toast("New task: %s" % quest.title)
	_check_ready(quest)


## Pays out and closes a quest. Returns false when it was not ready.
func hand_in(quest: QuestData) -> bool:
	if quest == null or state_of(quest) != State.READY:
		return false
	_state[quest.id] = State.DONE

	if quest.xp_reward > 0:
		PlayerProgress.add_xp(quest.xp_reward)
	if quest.gold_reward > 0:
		PlayerProgress.add_gold(quest.gold_reward)
	for item in quest.item_rewards:
		Inventory.add(item, 1)

	for next in quest.unlocks:
		reveal(next)

	EventBus.quest_completed.emit(quest)
	EventBus.emit_event(&"quest_completed", { "quest": quest.id })
	return true


## Adds to a quest's tally directly. Most progress arrives through events
## instead; this is for the odd case that has no natural event.
func add_progress(quest: QuestData, amount: int = 1) -> void:
	if quest == null or state_of(quest) != State.ACTIVE:
		return
	_count[quest.id] = count_of(quest) + amount
	EventBus.quest_progressed.emit(quest, count_of(quest))
	_check_ready(quest)


func _check_ready(quest: QuestData) -> void:
	if count_of(quest) < quest.required_count:
		return
	if state_of(quest) != State.ACTIVE:
		return
	_state[quest.id] = State.READY
	EventBus.quest_ready_to_hand_in.emit(quest)
	EventBus.toast("%s - return to %s" % [quest.title, quest.giver])


func _on_game_event(name: StringName, _payload: Dictionary) -> void:
	for id: StringName in _quests:
		var quest: QuestData = _quests[id]
		if quest.counts_event != &"" and quest.counts_event == name:
			add_progress(quest, 1)
