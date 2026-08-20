extends Node

## The whispers. The dark has things to say, and it says them a little at a time -
## one line for every twenty seconds you spend walking, in a shuffled order so it
## is never the same four in the same sequence. Each is a breathy, wordless hiss
## and a line of pale text that surfaces and fades, the same four the HTML used.

const LINES := [
	"Follow me...",
	"I'm... lost... help... me...",
	"They did it to me... they did it",
	"Darkness... only... darkness",
]
const INTERVAL := 20.0

var _order: Array = []
var _idx: int = 0
var _walk: float = 0.0
var _player: Node2D


func _ready() -> void:
	_order = range(LINES.size())
	_order.shuffle()


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
		return
	# only walking feeds the dark; standing still buys quiet
	if _player.moving and not _player.dead:
		_walk += delta
	if _walk >= INTERVAL:
		_walk = 0.0
		var line: String = LINES[_order[_idx % _order.size()]]
		_idx += 1
		EventBus.toast(line)
		Sfx.play(&"whisper", -5.0)
