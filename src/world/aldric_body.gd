class_name AldricBody
extends Node2D

## Brother Aldric, at the end of the Drowned Run, beside a guttering lantern that
## is the only reason the body reads when you finally reach it. He is Herbert's
## brother. The letter is a confession - four water-stained pages - and taking it
## is the emotional core the report later pays off. Read once on the body, and
## again any time from the journal.

const PAGES := [
	"Herbert, brother... I have tried. You knew about my trouble - since Elina left me I could not bear to leave the house. But when he came, I thought I could see the light once more. Gods, I was wrong. I was so wrong.",
	"I am sorry, brother, but my mind was sent astray. I had to finish it before I hurt anyone else.",
	"I hope this message finds you, and I hope that in your heart you can forgive me.",
	"Your big brother, Aldric.",
]

@export var interact_radius: float = 30.0

var t: float = 0.0
var _taken: bool = false


func _ready() -> void:
	add_to_group(&"interactable")
	add_to_group(&"area_content")
	z_index = 3


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func interact_prompt() -> String:
	return "Read the letter" if _taken else "Brother Aldric"


func can_interact() -> bool:
	return true


func interact(_by: Node) -> void:
	if not _taken:
		_taken = true
		PlayerProgress.set_flag(&"aldric_found")
		var letter := ItemDb.get_item(&"letter")
		if letter != null:
			Inventory.add(letter, 1)
		Sfx.play(&"pickup")
		EventBus.toast("Aldric's Letter - four pages, in his hand. Re-read it in the journal.")
	EventBus.dialogue_requested.emit("Aldric's Letter", PackedStringArray(PAGES))


func _draw() -> void:
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)

	# ground shadow
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# a slumped robed body against the wall, knees up, head fallen to one side
	R.call(-9, -6, 18, 6, Color("2a2620"))       # legs/lap
	R.call(-8, -14, 15, 9, Color("352f24"))       # torso robe
	R.call(-8, -14, 3, 9, Color("40392c"))
	R.call(4, -14, 3, 9, Color("241f18"))
	R.call(-2, -16, 8, 7, Color("c9bfae"))        # skull, tilted
	R.call(-1, -14, 2, 2, Color("15110c"))        # eye socket
	R.call(3, -14, 2, 2, Color("15110c"))
	R.call(-3, -9, 9, 2, Color("b7ac9a"))         # jaw/collar bone
	# a bony hand resting on the pages
	R.call(-12, -3, 5, 3, Color("c4b9a7"))
	# the letter under the hand - pale against the dark floor
	R.call(-16, -2, 8, 5, Color("d8cba6"))
	R.call(-16, -2, 8, 1, Color("efe4c2"))
	R.call(-15, -1, 6, 1, Color("6a5f48"))
	R.call(-15, 1, 5, 1, Color("6a5f48"))

	# the guttering lantern beside him - self-drawn flicker so it reads as lit
	var lx := 13.0
	var fl := 0.6 + 0.4 * sin(t * 9.0) + 0.15 * sin(t * 23.0)
	R.call(lx, -16, 5, 10, Color("1c1a17"))        # iron case
	R.call(lx + 1, -14, 3, 6, Color((150 + 80 * fl) / 255.0, (70 + 60 * fl) / 255.0, 30 / 255.0))
	R.call(lx + 1, -12, 3, 2, Color((230 + 25 * fl) / 255.0, (170 + 40 * fl) / 255.0, 90 / 255.0))
	R.call(lx, -18, 5, 2, Color("2a2620"))
	R.call(lx + 2, -20, 1, 2, Color("40392c"))     # ring
