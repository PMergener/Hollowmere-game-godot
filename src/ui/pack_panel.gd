extends CanvasLayer

## The backpack, opened with I. Fifty slots, nine wide, so the top row IS the
## belt you already see at the bottom of the screen. Click a slot to use what is
## in it - a light lights, a remedy heals, a weapon is equipped - and the line
## along the bottom names whatever the mouse is resting on.
##
## Drawing is a painter child, like the HUD; the panel freezes the game while it
## is open so the dark is not creeping up on you while you read.

const COLS := 9
const ROWS := 6            # 54 cells for a 50-slot pack, last four unused
const SLOT := 30
const PITCH := 34

var open := false
var t := 0.0
var _player: Node2D
var _hover := -1

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	painter.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"open_pack"):
		_toggle()
	if not open:
		return
	t += delta
	if Input.is_action_just_pressed(&"pause"):
		_toggle()
	_hover = _slot_at(get_viewport().get_mouse_position())
	painter.queue_redraw()


func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node2D


func _unhandled_input(e: InputEvent) -> void:
	if not open:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := _slot_at(e.position)
		if i >= 0 and _player != null:
			_player.use_item_slot(i)
		get_viewport().set_input_as_handled()


# --- geometry ---------------------------------------------------------------

func _grid_origin() -> Vector2:
	var w := COLS * PITCH
	var h := ROWS * PITCH
	return Vector2((576 - w) / 2.0, (360 - h) / 2.0 + 12.0)


func _slot_rect(i: int) -> Rect2:
	var o := _grid_origin()
	var col := i % COLS
	var row := i / COLS
	return Rect2(o.x + col * PITCH, o.y + row * PITCH, SLOT, SLOT)


func _slot_at(mouse: Vector2) -> int:
	for i in range(COLS * ROWS):
		if i < Inventory.PACK_SIZE and _slot_rect(i).has_point(mouse):
			return i
	return -1


# --- drawing ----------------------------------------------------------------

func paint(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 576, 360), Color(0.02, 0.02, 0.03, 0.72), true)
	var o := _grid_origin()
	var panel := Rect2(o.x - 16, o.y - 40, COLS * PITCH + 32, ROWS * PITCH + 64)
	ci.draw_rect(panel, Color(0.07, 0.065, 0.055, 0.96), true)
	_frame(ci, panel, Color("3b382f"))

	_label(ci, "PACK", o.x - 8, o.y - 32, Color("c9ab68"))

	for i in range(COLS * ROWS):
		if i >= Inventory.PACK_SIZE:
			continue
		_slot(ci, i)

	# the examine line
	var line := ""
	if _hover >= 0:
		var st: ItemStack = Inventory.slot(_hover)
		if st != null and st.item != null:
			line = st.item.display_name
			if st.item.hover_hint != "":
				line += "  -  " + st.item.hover_hint
	_label(ci, line if line != "" else "click an item to use or equip it",
		o.x - 8, o.y + ROWS * PITCH + 12, Color("9a9078"))


func _slot(ci: CanvasItem, i: int) -> void:
	var r := _slot_rect(i)
	var st: ItemStack = Inventory.slot(i)
	var is_belt := i < Inventory.BELT_SIZE
	var bg := Color(0.11, 0.10, 0.08, 0.9) if is_belt else Color(0.05, 0.05, 0.06, 0.9)
	if i == _hover:
		bg = Color(0.16, 0.15, 0.11, 0.95)
	ci.draw_rect(r, bg, true)
	_frame(ci, r, Color("574f3b") if is_belt else Color("332f28"))

	if is_belt:
		_digit(ci, (i + 1) % 10, r.position.x + 2, r.position.y + 2, Color("6a6350"))

	if st == null or st.item == null:
		return
	var key := String(st.item.id)
	var cx := r.position.x + SLOT / 2.0
	var cy := r.position.y + SLOT / 2.0
	if ItemIcons.has_live_icon(key):
		ItemIcons.draw_live_icon(ci, key, cx, cy, false, t)
	else:
		ItemIcons.draw_icon(ci, key, cx, cy, 0.82)
	if st.amount > 1:
		var n := str(st.amount)
		for d in n.length():
			_digit(ci, int(n[d]), r.position.x + SLOT - 4 - (n.length() - d) * 4,
				r.position.y + SLOT - 8, Color("cfe6c2"))


func _frame(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), c, true)
	ci.draw_rect(Rect2(r.position.x + r.size.x - 2, r.position.y, 2, r.size.y), c, true)


# A tiny 3x5 label, hand-plotted so it stays crisp under the upscale.
const GLYPHS := {
	"A": [0b010, 0b101, 0b111, 0b101, 0b101], "C": [0b111, 0b100, 0b100, 0b100, 0b111],
	"E": [0b111, 0b100, 0b110, 0b100, 0b111], "I": [0b111, 0b010, 0b010, 0b010, 0b111],
	"K": [0b101, 0b110, 0b100, 0b110, 0b101], "P": [0b111, 0b101, 0b111, 0b100, 0b100],
	"U": [0b101, 0b101, 0b101, 0b101, 0b111], "L": [0b100, 0b100, 0b100, 0b100, 0b111],
	"S": [0b111, 0b100, 0b111, 0b001, 0b111], "T": [0b111, 0b010, 0b010, 0b010, 0b010],
	"O": [0b111, 0b101, 0b101, 0b101, 0b111], "R": [0b111, 0b101, 0b111, 0b110, 0b101],
	"M": [0b101, 0b111, 0b111, 0b101, 0b101], "N": [0b101, 0b111, 0b111, 0b111, 0b101],
	"D": [0b110, 0b101, 0b101, 0b101, 0b110], "G": [0b111, 0b100, 0b101, 0b101, 0b111],
	"H": [0b101, 0b101, 0b111, 0b101, 0b101], "Q": [0b111, 0b101, 0b101, 0b111, 0b011],
	"V": [0b101, 0b101, 0b101, 0b101, 0b010], "W": [0b101, 0b101, 0b111, 0b111, 0b101],
	"Y": [0b101, 0b101, 0b010, 0b010, 0b010], "B": [0b110, 0b101, 0b110, 0b101, 0b110],
	"F": [0b111, 0b100, 0b110, 0b100, 0b100], " ": [0, 0, 0, 0, 0], "-": [0, 0, 0b111, 0, 0],
}

func _label(ci: CanvasItem, text: String, x: float, y: float, c: Color) -> void:
	var cx := x
	for ch in text.to_upper():
		var g: Array = GLYPHS.get(ch, GLYPHS[" "])
		for row in 5:
			for b in 3:
				if int(g[row]) & (1 << (2 - b)):
					ci.draw_rect(Rect2(cx + b, y + row, 1, 1), c, true)
		cx += 4.0


const DIGITS := [
	[0b111, 0b101, 0b101, 0b101, 0b111], [0b010, 0b110, 0b010, 0b010, 0b111],
	[0b111, 0b001, 0b111, 0b100, 0b111], [0b111, 0b001, 0b111, 0b001, 0b111],
	[0b101, 0b101, 0b111, 0b001, 0b001], [0b111, 0b100, 0b111, 0b001, 0b111],
	[0b111, 0b100, 0b111, 0b101, 0b111], [0b111, 0b001, 0b001, 0b010, 0b010],
	[0b111, 0b101, 0b111, 0b101, 0b111], [0b111, 0b101, 0b111, 0b001, 0b111],
]

func _digit(ci: CanvasItem, n: int, x: float, y: float, c: Color) -> void:
	var g: Array = DIGITS[n % 10]
	for row in 5:
		for b in 3:
			if g[row] & (1 << (2 - b)):
				ci.draw_rect(Rect2(x + b, y + row, 1, 1), c, true)
