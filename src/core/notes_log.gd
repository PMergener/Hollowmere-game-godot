extends Node

## The lore scraps Nestor finds and can re-read from the journal. Four across the
## game (two in the village, one in each sewer level); each is picked up once and
## kept for good. This holds the text and which have been found - the journal only
## reads from here, and a note can never be collectable in an area it does not
## belong to.

var _notes := [
	{"id": &"note1", "area": &"village", "pos": Vector2(254, 700),
	 "title": "A scrap, pressed into the mud",
	 "text": "He came when the crops withered...Promisses...Now I cant eat, everything tastes like dirt...What have I done? Gods, forgive me..."},
	{"id": &"note2", "area": &"village", "pos": Vector2(176, 632),
	 "title": "A page torn from a dream-book",
	 "text": "When I dream, I can see them...Dark figures with golden eyes...They whisper of a world which came before. They say...This world is ours, we came first..."},
	{"id": &"note3", "area": &"sewer", "pos": Vector2(620, 250),
	 "title": "A charcoal hand, hurried",
	 "text": "The red storms...Once I saw them, they wounded the skies...Dark figures came through them...The world ever since, grows darker by the hour."},
	{"id": &"note4", "area": &"sewer2", "pos": Vector2(420, 230),
	 "title": "A confession, unfinished",
	 "text": "I have a token. i wanted her for me...I loved her...Oh gods. I have her now, well, what remained of ther...Gods, why? What have I done?"},
]

var _found: Dictionary = {}


func all() -> Array:
	return _notes


func in_area(area: StringName) -> Array:
	return _notes.filter(func(n): return n.area == area)


func total() -> int:
	return _notes.size()


func found_count() -> int:
	return _found.size()


func is_found(id: StringName) -> bool:
	return _found.has(id)


func get_note(id: StringName) -> Dictionary:
	for n in _notes:
		if n.id == id:
			return n
	return {}


## Marks a note found. Returns true the first time, false if already taken.
func collect(id: StringName) -> bool:
	if _found.has(id):
		return false
	_found[id] = true
	EventBus.emit_event(&"note_found", {"id": id})
	return true
