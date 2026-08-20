class_name PixelText
extends RefCounted

## Hand-plotted 3x5 glyphs for the panels. Small text drawn with a real font
## turns to mush under the pixelated upscale, so every letter and digit is a
## bitmap - the same discipline the HTML build used for anything below ~8px.

const G := {
	"A": [0b010, 0b101, 0b111, 0b101, 0b101], "B": [0b110, 0b101, 0b110, 0b101, 0b110],
	"C": [0b111, 0b100, 0b100, 0b100, 0b111], "D": [0b110, 0b101, 0b101, 0b101, 0b110],
	"E": [0b111, 0b100, 0b110, 0b100, 0b111], "F": [0b111, 0b100, 0b110, 0b100, 0b100],
	"G": [0b111, 0b100, 0b101, 0b101, 0b111], "H": [0b101, 0b101, 0b111, 0b101, 0b101],
	"I": [0b111, 0b010, 0b010, 0b010, 0b111], "J": [0b001, 0b001, 0b001, 0b101, 0b111],
	"K": [0b101, 0b110, 0b100, 0b110, 0b101], "L": [0b100, 0b100, 0b100, 0b100, 0b111],
	"M": [0b101, 0b111, 0b111, 0b101, 0b101], "N": [0b101, 0b111, 0b111, 0b111, 0b101],
	"O": [0b111, 0b101, 0b101, 0b101, 0b111], "P": [0b111, 0b101, 0b111, 0b100, 0b100],
	"Q": [0b111, 0b101, 0b101, 0b111, 0b011], "R": [0b111, 0b101, 0b111, 0b110, 0b101],
	"S": [0b111, 0b100, 0b111, 0b001, 0b111], "T": [0b111, 0b010, 0b010, 0b010, 0b010],
	"U": [0b101, 0b101, 0b101, 0b101, 0b111], "V": [0b101, 0b101, 0b101, 0b101, 0b010],
	"W": [0b101, 0b101, 0b111, 0b111, 0b101], "X": [0b101, 0b101, 0b010, 0b101, 0b101],
	"Y": [0b101, 0b101, 0b010, 0b010, 0b010], "Z": [0b111, 0b001, 0b010, 0b100, 0b111],
	"0": [0b111, 0b101, 0b101, 0b101, 0b111], "1": [0b010, 0b110, 0b010, 0b010, 0b111],
	"2": [0b111, 0b001, 0b111, 0b100, 0b111], "3": [0b111, 0b001, 0b111, 0b001, 0b111],
	"4": [0b101, 0b101, 0b111, 0b001, 0b001], "5": [0b111, 0b100, 0b111, 0b001, 0b111],
	"6": [0b111, 0b100, 0b111, 0b101, 0b111], "7": [0b111, 0b001, 0b001, 0b010, 0b010],
	"8": [0b111, 0b101, 0b111, 0b101, 0b111], "9": [0b111, 0b101, 0b111, 0b001, 0b111],
	" ": [0, 0, 0, 0, 0], "-": [0, 0, 0b111, 0, 0], "/": [0b001, 0b001, 0b010, 0b100, 0b100],
	"!": [0b010, 0b010, 0b010, 0b000, 0b010], ".": [0, 0, 0, 0, 0b010],
	",": [0, 0, 0, 0b010, 0b100], "?": [0b111, 0b001, 0b011, 0b000, 0b010],
	"'": [0b010, 0b010, 0, 0, 0], ":": [0, 0b010, 0, 0b010, 0],
}


## Draws [param text] in 3x5 caps at [param x],[param y]. Returns the width used,
## so a caller can right-align or place something after it.
static func draw(ci: CanvasItem, text: String, x: float, y: float, c: Color,
		spacing: float = 4.0) -> float:
	var cx := x
	for ch in text.to_upper():
		var g: Array = G.get(ch, G[" "])
		for row in 5:
			for b in 3:
				if int(g[row]) & (1 << (2 - b)):
					ci.draw_rect(Rect2(cx + b, y + row, 1, 1), c, true)
		cx += spacing
	return cx - x


static func width(text: String, spacing: float = 4.0) -> float:
	return text.length() * spacing
