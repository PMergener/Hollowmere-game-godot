class_name Herbert
extends Actor

## Herbert, the elder. He does not wander - he stands where the village still
## holds, and he is the hand that gives and takes back Nestor's tasks.
##
## Spoken to, he reads the state of his own quests and answers to match: hands
## one back if it is done, offers the next if one waits, or reminds you what is
## still out there. The quest logic lives in [QuestLog]; Herbert only chooses
## which words go with which state.

@export var interact_radius: float = 30.0

var _pal: Dictionary


func _ready() -> void:
	add_to_group(&"interactable")
	add_to_group(&"herbert")
	_pal = Figure.PAL_NPC[0]


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


# --- Interactable -----------------------------------------------------------

func interact_prompt() -> String:
	return "Speak"


func can_interact() -> bool:
	return true


# The whole of Herbert's talk, ported branch-for-branch from the HTML's
# talkToHerbert - the exact lines, and the Yes/No where the HTML offered one. He
# does not auto-take a vow any more; he offers it, and you answer.
func interact(by: Node) -> void:
	if by is Node2D:
		face_toward((by as Node2D).global_position - global_position)

	var shades := QuestLog.by_id(&"shades")
	var under := QuestLog.by_id(&"undercroft")
	var elphric := QuestLog.by_id(&"elphric")
	var S := QuestLog.State

	# the report, once the Fallen Hunter is down
	if elphric != null and QuestLog.state_of(elphric) == S.ACTIVE:
		_report_elphric(elphric)
		return

	# --- the shades vow --------------------------------------------------------
	if QuestLog.state_of(shades) == S.AVAILABLE:
		_pages([
			{"text": "So you are the one they hired, very well...Folks are restless...Our nights are filled with the remains of those whose essence lingers among the living. We have a lot of needs for your talents, but first, aid us...Send them back to the veil"},
			{"text": "Can you help us?", "choices": [
				{"label": "Yes. I will send them back.", "fn": func() -> void: _take(shades)},
				{"label": "Not yet.", "fn": func() -> void: {}},
			]},
		])
		return
	if QuestLog.state_of(shades) == S.READY:
		# turn-in pays out (banner + XP), then he offers the undercroft
		QuestLog.hand_in(shades)
		QuestLog.reveal(under)
		_pages([
			{"text": "We can rest tonight...For now"},
			{"text": "Actually, theres something else...Something foul lurks beneath our village. I believe it has somehow...Disturbed the spirits. If you want some extra coin, you could take a look. What do you think?", "choices": [
				{"label": "Yes. I will go below.", "fn": func() -> void: _take_under(under)},
				{"label": "No. Not for any coin.", "fn": func() -> void: {}},
			]},
		])
		return
	if QuestLog.state_of(shades) == S.ACTIVE:
		var left: int = shades.required_count - QuestLog.count_of(shades)
		_say(["The veil still thins. %d of them yet walk. Take the green lamp to them." % left])
		return

	# --- shades is done from here ---------------------------------------------
	# the sigil: he recoils, but gives his brother's key
	if Inventory.has_item(&"sigil") and not PlayerProgress.has_flag(&"sewer_key_given"):
		_deliver_sigil()
		return

	match QuestLog.state_of(under):
		S.AVAILABLE:   # offered, declined once - he asks again
			_pages([
				{"text": "Have you reconsidered? Something foul still lurks beneath us.", "choices": [
					{"label": "Yes. I will go below.", "fn": func() -> void: _take_under(under)},
					{"label": "Still no.", "fn": func() -> void: {}},
				]},
			])
		S.ACTIVE:
			_say(["The well is the only way down. You will need rope. There is some...where no one likes to look. Southwest, past the crooked tree."])
		S.READY:
			QuestLog.hand_in(under)
			_say(["Bones, you say. Old bones, put back down. Take your coin, and my thanks."])
		_:
			_say(["Be gone, leave me to my thoughts."])


# Take the shades vow.
func _take(q: QuestData) -> void:
	QuestLog.accept(q)
	Sfx.play(&"quest")


# Take the undercroft vow, with his blessing after.
func _take_under(q: QuestData) -> void:
	QuestLog.accept(q)
	Sfx.play(&"quest")
	_say(["Well...Good luck down here"])


func _say(lines: Array) -> void:
	EventBus.dialogue_requested.emit("Herbert", PackedStringArray(lines))


func _pages(pages: Array) -> void:
	EventBus.dialogue_pages_requested.emit("Herbert", pages)


# He names the sigil and pushes it away, then gives you his dead brother's key.
# The key lands when the dialogue closes, not while it is still open - the HTML
# paid it out in the same onEnd beat, and it reads better as the last word of the
# exchange rather than a banner over his shoulder mid-sentence.
func _deliver_sigil() -> void:
	_say([
		"A sigil? Yes, yes, I knew one of these...Keep it away from me",
		"Do not bring it into my house. Do not set it on my table. I have seen its like before and I have no wish to learn any more than I already know.",
		"You have done what was asked and more. The bones are down. Whatever that thing is, it is yours to carry, and I am sorry for it.",
		"Take this. It was my brothers, and it opens the old grate below the undercroft - the run beneath the run. He went down there once. He came back up wrong, and then he did not come back up at all.",
		"If you go, go with the lamp lit. And do not take anything that is offered to you down there.",
	])
	EventBus.dialogue_finished.connect(_on_sigil_end, CONNECT_ONE_SHOT)


var _pending_report: QuestData = null


# Herbert hears the report. He never met Elphric, but he has met the thing that
# keeps people, and he is not surprised it kept one of the Order's. On the last
# line the two vows close and the north gate is unbarred.
func _report_elphric(elphric: QuestData) -> void:
	_pending_report = elphric
	_say([
		"You have the look of a man who found what he was looking for and wishes he had not.",
		"Elphric. I never met him. But I have met the thing that keeps people, and I am not surprised it kept one of yours.",
		"Write it down. Send it north with the rest. Whatever is under this village has been collecting for longer than any of us has been alive, and your Order should stop pretending otherwise.",
		"So go. Yotan, and the archive, and people who will believe you because you are carrying a dead man's name.",
		"I will have the north gate unbarred by the time you reach it. Nobody has walked that road in a long while. Mind that you are the one who chooses to.",
	])
	EventBus.dialogue_finished.connect(_on_report_end, CONNECT_ONE_SHOT)


func _on_report_end() -> void:
	if _pending_report != null:
		QuestLog.add_progress(_pending_report, 1)   # -> READY
		QuestLog.hand_in(_pending_report)            # 80 XP, DONE
		_pending_report = null
	var yotan := QuestLog.by_id(&"yotan")
	if yotan != null and QuestLog.state_of(yotan) != QuestLog.State.DONE:
		QuestLog.begin(yotan)                        # reveal + accept
		QuestLog.add_progress(yotan, 1)              # -> READY
		QuestLog.hand_in(yotan)                      # 100 XP, DONE
	PlayerProgress.set_flag(&"north_gate_unbarred")
	Sfx.play(&"quest")
	# Fired last, so it wins over the two auto QUEST COMPLETE banners the hand-ins raise.
	EventBus.banner("WHAT BECAME OF ELPHRIC", "THE NORTH GATE IS UNBARRED", true)
	EventBus.toast("The road to Yotan can be walked now.")


func _on_sigil_end() -> void:
	PlayerProgress.set_flag(&"sigil_known")
	if PlayerProgress.has_flag(&"sewer_key_given"):
		return
	var key := ItemDb.get_item(&"key")
	if key != null and Inventory.add(key, 1) == 0:
		PlayerProgress.set_flag(&"sewer_key_given")
		Sfx.play(&"quest")
		Sfx.play(&"shriek", -6.0)
		EventBus.banner("THE SEWER KEY", "HIS BROTHER WENT DOWN THERE", true)
		EventBus.toast("It opens the old grate below the undercroft.")
	else:
		EventBus.toast("Make room in your pack, then speak to Herbert again.")


func _draw() -> void:
	_draw_elder()
	_quest_marker()


# Herbert, ported from the HTML build's drawElder: a hunched, hooded elder with a
# grey beard and pale eyes, leaning on a staff whose head glows faintly. He does
# not use the shared Figure body - the stoop and the staff are what make him read
# as old rather than as another villager.
func _draw_elder() -> void:
	var by := -1.0 if sin(t * 0.9) > 0.4 else 0.0
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)
	# ground shadow, squashed to an ellipse
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 3.4 / 9.0))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# feet
	R.call(-5, by - 5, 4, 5, Color("2b2519")); R.call(2, by - 5, 4, 5, Color("2b2519"))
	R.call(-5, by - 2, 5, 2, Color("0d0b08")); R.call(2, by - 2, 5, 2, Color("0d0b08"))
	# robe body
	R.call(-7, by - 17, 14, 12, Color("3b3527"))
	R.call(-7, by - 17, 3, 12, Color("474030"))
	R.call(4, by - 17, 3, 12, Color("2e291e"))
	R.call(-2, by - 16, 1, 10, Color("2e291e"))
	R.call(-8, by - 8, 16, 3, Color("292418"))
	R.call(-7, by - 11, 14, 2, Color("5a4a2c"))
	R.call(-8, by - 19, 16, 3, Color("474030"))
	# stooped shoulders / sleeves
	R.call(-10, by - 16, 3, 8, Color("3b3527"))
	R.call(7, by - 16, 3, 7, Color("3b3527"))
	R.call(-11, by - 9, 3, 3, Color("141210"))
	# hood
	R.call(-7, by - 27, 14, 10, Color("4a4335"))
	R.call(-6, by - 29, 12, 2, Color("4a4335"))
	R.call(-7, by - 27, 3, 10, Color("565040"))
	R.call(-5, by - 24, 10, 7, Color("0b0a08"))
	# pale eyes
	R.call(-4, by - 22, 3, 2, Color("8a8272"))
	R.call(2, by - 22, 3, 2, Color("8a8272"))
	# grey beard
	R.call(-4, by - 19, 8, 8, Color("b8b2a2"))
	R.call(-3, by - 17, 6, 6, Color("a8a294"))
	R.call(-1, by - 13, 3, 4, Color("c4beae"))
	R.call(-4, by - 20, 8, 1, Color("cac4b6"))
	# the staff, with a faintly glowing head
	R.call(10, by - 34, 3, 34, Color("3a2b18"))
	R.call(10, by - 34, 1, 34, Color("4a3a24"))
	R.call(9, by - 36, 5, 3, Color("4a3a24"))
	R.call(10, by - 38, 3, 3, Color("6b5a3e"))
	var gl := 0.5 + 0.5 * sin(t * 1.8)
	R.call(10, by - 37, 2, 2, Color((120 + 70 * gl) / 255, (96 + 60 * gl) / 255, (40 + 30 * gl) / 255))


# A ! when he has a task to give, a ? when one is ready to hand back - the same
# language the HTML build used to point the player at him.
func _quest_marker() -> void:
	var mark := ""
	var elphric := QuestLog.by_id(&"elphric")
	if QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.READY) != null:
		mark = "?"
	elif elphric != null and QuestLog.state_of(elphric) == QuestLog.State.ACTIVE:
		mark = "?"  # a report to make
	elif Inventory.has_item(&"sigil") and not PlayerProgress.has_flag(&"sewer_key_given"):
		mark = "?"  # he has something to say about what you are carrying
	elif QuestLog.giver_quest_in(&"Herbert" as String, QuestLog.State.AVAILABLE) != null:
		mark = "!"
	if mark == "":
		return
	var bob := sin(t * 2.4) * 1.5
	var y := -40.0 + bob
	var col := Color("f0d070") if mark == "!" else Color("70c0f0")
	if mark == "!":
		draw_rect(Rect2(-1, y, 2, 6), col, true)
		draw_rect(Rect2(-1, y + 7, 2, 2), col, true)
	else:
		draw_rect(Rect2(-2, y, 4, 2), col, true)
		draw_rect(Rect2(1, y + 2, 2, 2), col, true)
		draw_rect(Rect2(-1, y + 4, 2, 2), col, true)
		draw_rect(Rect2(-1, y + 7, 2, 2), col, true)
