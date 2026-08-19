extends Node

## Watches for the nearest thing the player can act on and, when they press the
## interact key, acts on it.
##
## Kept off the player so the player does not grow a fourth job. Anything in the
## "interactable" group that answers interact_prompt / can_interact / interact is
## eligible; the closest one inside its own radius wins, and its prompt is shown.

var _current: Node = null
var _player: Node2D


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
		if _player == null:
			return

	var best: Node = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"interactable"):
		if not (node is Node2D) or not node.has_method(&"interact"):
			continue
		if node.has_method(&"can_interact") and not node.can_interact():
			continue
		var radius: float = node.interact_radius if "interact_radius" in node else 26.0
		var d: float = (node as Node2D).global_position.distance_to(_player.global_position)
		if d <= radius and d < best_d:
			best_d = d
			best = node

	if best != _current:
		_current = best
		var prompt := ""
		if _current != null and _current.has_method(&"interact_prompt"):
			prompt = "[E] %s" % _current.interact_prompt()
		EventBus.interaction_prompt.emit(prompt)

	if _current != null and Input.is_action_just_pressed(&"interact"):
		_current.interact(_player)
