extends CanvasLayer

## The landmark banner: a gold or red gradient strip across the upper third with a
## title and an optional subtitle, rising a few pixels as it fades in and fading
## out at the end. The HTML build's banner(), for the beats a toast is too small
## for - a level gained, a vow closed, a gate given. It also listens straight to
## the level and quest signals so those never need to remember to ask.

const GW := 300.0

var _main := ""
var _sub := ""
var _gold := true
var _age := 0.0
var _dur := 0.0

@onready var painter: Node2D = $Painter


func _ready() -> void:
	layer = 21   # above the world and weather, below panels
	EventBus.banner_requested.connect(_show)
	EventBus.level_gained.connect(func(lvl: int) -> void:
		var prog := PlayerProgress.progression
		var sub := "+%d VIGOUR" % prog.health_per_level
		if prog.damage_every_n_levels > 0 and lvl % prog.damage_every_n_levels == 0:
			sub += "   +1 EDGE"
		_show("LEVEL %d" % lvl, sub, true))
	EventBus.quest_completed.connect(func(q: QuestData) -> void:
		var sub := "%d XP EARNED" % q.xp_reward if q.xp_reward > 0 else ""
		_show("QUEST COMPLETE", sub, true))


func _show(main: String, sub: String, gold: bool) -> void:
	_main = main
	_sub = sub
	_gold = gold
	_age = 0.0
	_dur = 4.2 if sub != "" else 3.2


func _process(delta: float) -> void:
	if _age < _dur:
		_age += delta
		painter.queue_redraw()
	elif _main != "":
		_main = ""
		painter.queue_redraw()


func paint(ci: CanvasItem) -> void:
	if _main == "" or _age >= _dur:
		return
	var fade := 1.0
	if _age < 0.4:
		fade = _age / 0.4
	elif _age > _dur - 0.9:
		fade = maxf(0.0, (_dur - _age) / 0.9)
	var rise := (1.0 - minf(1.0, _age / 0.5)) * 6.0
	var y := 360.0 * 0.34 + rise
	var gx := (576.0 - GW) / 2.0
	var strip_h := 46.0 if (_gold and _sub != "") else 30.0

	# the fading gradient strip, drawn as vertical slices so the edges vanish
	var mid := Color(0.157, 0.110, 0.031, 0.72) if _gold else Color(0.149, 0.031, 0.031, 0.72)
	var slices := 40
	for i in slices:
		var f := float(i) / (slices - 1)
		var edge := 1.0 - absf(f - 0.5) * 2.0        # 0 at ends, 1 at centre
		var a := mid.a * edge * fade
		ci.draw_rect(Rect2(gx + GW * f, y - 8.0, GW / slices + 1.0, strip_h),
			Color(mid.r, mid.g, mid.b, a), true)

	# the two hairlines
	var line := Color(0.690, 0.549, 0.227, 0.55 * fade) if _gold else Color(0.588, 0.157, 0.133, 0.55 * fade)
	ci.draw_rect(Rect2(gx + 40.0, y - 9.0, GW - 80.0, 1), line, true)
	ci.draw_rect(Rect2(gx + 40.0, y + (36.0 if (_gold and _sub != "") else 20.0), GW - 80.0, 1), line, true)

	# title, drop-shadow then fill, centred (wider letter spacing gives it weight)
	var mc := Color(0.788, 0.635, 0.306, fade) if _gold else Color(0.659, 0.200, 0.165, fade)
	_centered(ci, _main, y + 1.0, Color(0.16, 0.10, 0.02, fade), 6.0)
	_centered(ci, _main, y, mc, 6.0)
	if _sub != "":
		var sc := Color(0.604, 0.514, 0.259, fade) if _gold else Color(0.541, 0.353, 0.227, fade)
		_centered(ci, _sub, y + 25.0, Color(0.16, 0.10, 0.02, fade * 0.9), 4.0)
		_centered(ci, _sub, y + 24.0, sc, 4.0)


# PixelText, centred horizontally at the screen mid-line, with the given spacing.
func _centered(ci: CanvasItem, text: String, y: float, col: Color, spacing: float) -> void:
	var w := PixelText.width(text, spacing)
	PixelText.draw(ci, text, 288.0 - w / 2.0, y, col, spacing)
