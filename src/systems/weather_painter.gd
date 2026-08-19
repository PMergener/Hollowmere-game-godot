# A CanvasLayer cannot draw; only a CanvasItem can. This is the brush the
# weather layer paints through, kept separate so weather.gd holds the state and
# this holds nothing at all.
extends Node2D


func _draw() -> void:
	var w := get_parent()
	if w and w.has_method("paint"):
		w.paint(self)
