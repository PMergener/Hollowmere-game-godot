# The brush the HUD layer paints through. Same split as the weather layer: a
# CanvasLayer holds state and cannot draw, a CanvasItem draws and holds nothing.
extends Node2D


func _draw() -> void:
	var h := get_parent()
	if h and h.has_method("paint"):
		h.paint(self)
