extends CanvasLayer

## Ondrick's shop: BUY on the left, SELL on the right, gold in the header - the
## HTML build's panel. Buyables are every item with a buy price; sellables are
## whatever in the pack has a sell price and is allowed to be sold (Soul Powder
## never is). Click a row to trade. One-time stock (the Sewer Key) leaves the
## shelf for good once bought.

const PANEL := Rect2(80, 34, 416, 292)
const ROW_H := 42

var open := false
var t := 0.0
var _buy: Array = []          # ItemData
var _sell: Array = []         # {item, count}
var _sold_out: Array = []     # ids that will not restock
var _hover := -1              # >=0 buy row, <0 sell row (-(i+1))

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	painter.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.shop_requested.connect(_open)


func _open() -> void:
	open = true
	visible = true
	get_tree().paused = true
	_refresh()


func _close() -> void:
	open = false
	visible = false
	get_tree().paused = false


func _refresh() -> void:
	_buy.clear()
	for item in ItemDb.all():
		if item.buy_price > 0 and not (item.id in _sold_out):
			_buy.append(item)
	_buy.sort_custom(func(a, b): return a.buy_price < b.buy_price)
	_sell.clear()
	var seen := {}
	for i in range(Inventory.PACK_SIZE):
		var st := Inventory.slot(i)
		if st == null or st.item == null:
			continue
		if st.item.sell_price <= 0 or not st.item.can_sell:
			continue
		if st.item.id in seen:
			seen[st.item.id].count += st.amount
		else:
			var row := {"item": st.item, "count": st.amount}
			seen[st.item.id] = row
			_sell.append(row)


func _process(delta: float) -> void:
	if not open:
		return
	t += delta
	if Input.is_action_just_pressed(&"pause"):
		_close()
	_hover = _row_at(get_viewport().get_mouse_position())
	painter.queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if not open:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var r := _row_at(e.position)
		if r >= 0:
			_do_buy(r)
		elif r < -0:
			_do_sell(-(r + 1))
		get_viewport().set_input_as_handled()


func _do_buy(i: int) -> void:
	if i >= _buy.size():
		return
	var item: ItemData = _buy[i]
	if not PlayerProgress.can_afford(item.buy_price):
		Sfx.play(&"denied")
		EventBus.toast("Not enough gold")
		return
	if Inventory.is_full():
		Sfx.play(&"denied")
		EventBus.toast("PACK IS FULL")
		return
	PlayerProgress.spend_gold(item.buy_price)
	Inventory.add(item, 1)
	if not item.restock:
		_sold_out.append(item.id)
	Sfx.play(&"coin")
	EventBus.toast("Bought %s" % item.display_name)
	_refresh()


func _do_sell(i: int) -> void:
	if i >= _sell.size():
		return
	var item: ItemData = _sell[i].item
	Inventory.remove(item.id, 1)
	PlayerProgress.add_gold(item.sell_price)
	Sfx.play(&"coin")
	EventBus.toast("Sold %s - %dg" % [item.display_name, item.sell_price])
	_refresh()


# --- geometry / drawing -----------------------------------------------------

func _col_x(side: int) -> float:
	return PANEL.position.x + 16 + side * (PANEL.size.x / 2.0 - 8)


func _buy_rect(i: int) -> Rect2:
	return Rect2(_col_x(0) - 4, PANEL.position.y + 64 + i * ROW_H, PANEL.size.x / 2.0 - 20, ROW_H - 4)


func _sell_rect(i: int) -> Rect2:
	return Rect2(_col_x(1) - 4, PANEL.position.y + 64 + i * ROW_H, PANEL.size.x / 2.0 - 20, ROW_H - 4)


func _row_at(m: Vector2) -> int:
	for i in _buy.size():
		if _buy_rect(i).has_point(m):
			return i
	for i in _sell.size():
		if _sell_rect(i).has_point(m):
			return -(i + 1)
	return 999


func paint(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 576, 360), Color(0.016, 0.02, 0.031, 0.78), true)
	ci.draw_rect(PANEL, Color(0.09, 0.075, 0.047, 0.97), true)
	_frame(ci, PANEL, Color("6a5423"))
	var title := "ONDRICK'S"
	PixelText.draw(ci, title, PANEL.position.x + PANEL.size.x / 2.0 - PixelText.width(title) / 2.0, PANEL.position.y + 10, Color("e5cd8c"))
	var g := "GOLD %d" % PlayerProgress.gold
	PixelText.draw(ci, g, PANEL.position.x + PANEL.size.x - 36 - PixelText.width(g), PANEL.position.y + 10, Color("d6b45e"))

	# column headers, underlines, and the divider between them
	var cw := PANEL.size.x / 2.0 - 20.0
	PixelText.draw(ci, "BUY", PANEL.position.x + 12, PANEL.position.y + 46, Color("c2a86e"))
	PixelText.draw(ci, "SELL", PANEL.position.x + 24 + cw, PANEL.position.y + 46, Color("c2a86e"))
	ci.draw_rect(Rect2(PANEL.position.x + 12, PANEL.position.y + 60, cw, 1), Color("3f3116"), true)
	ci.draw_rect(Rect2(PANEL.position.x + 24 + cw, PANEL.position.y + 60, cw, 1), Color("3f3116"), true)
	ci.draw_rect(Rect2(PANEL.position.x + 18 + cw, PANEL.position.y + 44, 1, PANEL.size.y - 70), Color("2a2113"), true)

	if _buy.is_empty():
		PixelText.draw(ci, "SHELVES ARE BARE.", PANEL.position.x + 20, PANEL.position.y + 76, Color("6a5f48"))
	for i in _buy.size():
		var item: ItemData = _buy[i]
		var afford := PlayerProgress.can_afford(item.buy_price)
		_row(ci, _buy_rect(i), item, item.buy_price, _hover == i, afford, "you carry", 0)

	if _sell.is_empty():
		PixelText.draw(ci, "YOU CARRY NOTHING I WANT.", PANEL.position.x + 30 + cw, PANEL.position.y + 76, Color("6a5f48"))
	for i in _sell.size():
		var row = _sell[i]
		var item: ItemData = row.item
		_row(ci, _sell_rect(i), item, item.sell_price, _hover == -(i + 1), true, "YOU CARRY %d" % row.count, 1)

	var foot := "Soul powder I will not touch. Keep it. You will need it."
	PixelText.draw(ci, foot.to_upper(), PANEL.position.x + PANEL.size.x / 2.0 - PixelText.width(foot.to_upper()) / 2.0,
		PANEL.position.y + PANEL.size.y - 16, Color("6a5f48"))


# One shop row, matching drawShopRow: the item's icon, its name, a stat line
# (green - "+N armour" for gear) or the "you carry N" for a sell row, a blurb, and
# the price with a coin. Names dim when you cannot afford them.
func _row(ci: CanvasItem, r: Rect2, item: ItemData, price: int, hov: bool, ok: bool, sub: String, mode: int) -> void:
	ci.draw_rect(r, Color("2a2214") if hov else Color("14110b"), true)
	_frame(ci, r, Color("4a3f26") if hov else Color("2a2416"))
	ItemIcons.draw_icon(ci, String(item.id), r.position.x + 18, r.position.y + r.size.y / 2.0, 0.7)
	PixelText.draw(ci, item.display_name.to_upper(), r.position.x + 34, r.position.y + 5,
		Color("e0c88a") if ok else Color("8a7a5a"))
	if mode == 0:
		var armor: int = item.get(&"armor") if &"armor" in item else 0
		if armor > 0:
			PixelText.draw(ci, "+%d ARMOUR" % armor, r.position.x + 34, r.position.y + 18, Color("7f9a6a"))
		var blurb: String = item.description if &"description" in item and item.description != "" else item.hover_hint
		PixelText.draw(ci, blurb.to_upper(), r.position.x + 34, r.position.y + 29, Color("6a5f48"))
	else:
		PixelText.draw(ci, sub, r.position.x + 34, r.position.y + 20, Color("6a5f48"))
	var pc := Color("f0d48a") if ok else Color("7a5a44")
	var ps := "%dG" % price
	PixelText.draw(ci, ps, r.position.x + r.size.x - 8 - PixelText.width(ps), r.position.y + 8, pc)


func _frame(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, 2), c, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), c, true)
	ci.draw_rect(Rect2(r.position.x + r.size.x - 2, r.position.y, 2, r.size.y), c, true)
