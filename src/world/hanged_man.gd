class_name HangedMan
extends Node2D

## The hanged man at the crooked tree, southwest, where no one likes to look. He
## only appears once the shades are seen to (the village has to be calm enough to
## notice him), and the rope around his neck is the one thing long enough to lower
## yourself into the well. Cut him down, take the rope, descend. This is the gate
## the HTML put on the undercroft, restored: no rope, no well.
##
## Two acts on one prompt: the first cut drops him, the second takes the rope.

const BONE := Color("cdc3b0")
const BONE_HI := Color("e6ddca")
const BONE_MID := Color("a89e8c")

@export var interact_radius: float = 34.0

var t: float = 0.0
var cut: bool = false
var fall: float = 0.0
var taken: bool = false


func _ready() -> void:
	add_to_group(&"interactable")
	add_to_group(&"area_content")
	z_index = 3


func _process(delta: float) -> void:
	t += delta
	if cut and fall < 1.0:
		fall = minf(1.0, fall + delta * 1.25)
	queue_redraw()


# Only here once the shades are banished - before that the village has too much
# else to fear to have noticed him.
func _active() -> bool:
	var shades := QuestLog.by_id(&"shades")
	return shades != null and QuestLog.state_of(shades) == QuestLog.State.DONE


func can_interact() -> bool:
	return _active() and not taken


func interact_prompt() -> String:
	return "Take the rope" if cut else "Cut him down"


func interact(_by: Node) -> void:
	if not cut:
		cut = true
		fall = 0.0
		Sfx.play(&"swing")
		Sfx.play(&"hit", -4.0)
		EventBus.toast("You cut the rope. He comes down in a clatter of bone.")
		return
	if not taken:
		taken = true
		var rope := ItemDb.get_item(&"rope")
		if rope != null:
			Inventory.add(rope, 1)
		Sfx.play(&"pickup")
		EventBus.banner("THE FRAYED ROPE", "LONG ENOUGH FOR THE WELL", true)


func _draw() -> void:
	if not _active():
		return
	var R := func(x, y, w, h, c): draw_rect(Rect2(roundf(x), roundf(y), w, h), c, true)
	# the branch stub the rope hangs from, up and to the side
	R.call(-1, -62, 3, 5, Color("171309"))

	if not cut:
		var sway := sin(t * 0.42) * 1.6
		var sx := roundf(sway)
		# rope
		R.call(-1 + roundf(sway * 0.25), -58, 3, 12, Color("54432a"))
		R.call(-1 + roundf(sway * 0.6), -46, 3, 8, Color("4a3a22"))
		# noose knot
		R.call(sx - 3, -40, 7, 3, Color("6b5a3e"))
		R.call(sx - 3, -40, 7, 1, Color("8a7550"))
		# skull
		R.call(sx - 5, -38, 11, 10, BONE)
		R.call(sx - 5, -38, 4, 10, BONE_HI)
		R.call(sx - 4, -35, 3, 3, Color("2a2a2e"))
		R.call(sx + 1, -35, 3, 3, Color("2a2a2e"))
		R.call(sx - 3, -30, 7, 2, BONE)
		# ribs
		R.call(sx - 6, -24, 12, 2, Color("c9a24e"))
		R.call(sx - 5, -22, 10, 12, Color("9a9080"))
		for i in 4:
			R.call(sx - 5, -21 + i * 3, 10, 1, BONE_MID)
		# dangling arms
		R.call(sx - 8, -22, 3, 15, BONE_MID)
		R.call(sx + 5, -22, 3, 15, BONE_MID)
		# legs
		R.call(sx - 4, -10, 3, 14, BONE_MID)
		R.call(sx + 1, -10, 3, 14, BONE_MID)
		R.call(sx - 5, 4, 5, 2, BONE)
		R.call(sx, 4, 5, 2, BONE)
	else:
		# a short cut rope-end still on the branch
		R.call(-1, -58, 3, 9, Color("54432a"))
		var f := fall
		var drop := f * f * 30.0
		# the heap of bone on the ground
		var gy := -4.0 + drop
		R.call(-8, gy, 16, 4, Color("9a9080"))
		R.call(-6, gy - 3, 6, 4, BONE)              # skull in the pile
		R.call(-1, gy - 2, 2, 2, Color("2a2a2e"))
		R.call(3, gy - 1, 7, 2, BONE_MID)           # a splayed arm
		R.call(-10, gy + 1, 6, 2, BONE_MID)
		if not taken and f > 0.7:
			# the coil of rope on top of him, there to take
			R.call(-4, gy - 5, 9, 4, Color("6b5a3e"))
			R.call(-4, gy - 5, 9, 1, Color("8a7550"))
			R.call(-2, gy - 4, 5, 2, Color("54432a"))
