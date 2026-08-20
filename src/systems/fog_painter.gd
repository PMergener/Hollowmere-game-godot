extends Node2D

## The fog's own canvas, carrying a CanvasItemMaterial in ADD blend so five soft
## radial blobs LIFT the dark the way the HTML's `globalCompositeOperation =
## 'lighter'` did, instead of stacking as opaque pale balls. It sits under the rain
## and the vignette; the parent (Weather) owns the actual draw.

func _draw() -> void:
	get_parent().paint_fog(self)
