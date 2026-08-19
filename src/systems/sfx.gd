extends Node

## Every sound in the game, synthesized - no wav files, exactly as the HTML build
## made them in Web Audio. Each named sound is rendered once into a PCM buffer at
## startup from oscillators, noise and envelopes, then played from a small pool
## of players so several can overlap.
##
## Ported faithfully: the swing is band-passed noise sweeping down, a hit is that
## plus a low triangle thud, hurt is a falling sine, the wraith's shriek is a
## resonant noise sweep. Keeping the recipe here means a designer changes a sound
## by changing numbers, never by finding and re-recording a file.

const RATE := 32000
const POOL := 12

var muted := false
var _bank: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)
	_build_all()
	# A couple of sounds are universal enough to wire straight to the event bus
	# rather than making every caller remember them.
	EventBus.level_gained.connect(func(_lvl): play(&"levelup"))


## Plays a named sound. Unknown names are ignored rather than erroring, so a
## missing sound never takes the game down.
func play(sound_name: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if muted or not _bank.has(sound_name):
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _bank[sound_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()


func toggle_mute() -> void:
	muted = not muted


# --- synthesis --------------------------------------------------------------

func _build_all() -> void:
	_bank[&"swing"] = _render(0.32, func(buf):
		_noise(buf, 0.0, 0.30, 0.3, [[0.0, 3200.0], [0.22, 700.0]], 2.2, 0.03, 0.075, 0.26))

	_bank[&"hit"] = _render(0.26, func(buf):
		_noise(buf, 0.0, 0.24, 0.3, [[0.0, 1500.0]], 1.1, 0.001, 0.11, 0.19)
		_osc(buf, "triangle", 0.0, 0.20, 220.0, 70.0, true, 0.001, 0.07, 0.17))

	_bank[&"hurt"] = _render(0.44, func(buf):
		_osc(buf, "sine", 0.0, 0.42, 140.0, 48.0, true, 0.005, 0.14, 0.38))

	_bank[&"shriek"] = _render(1.0, func(buf):
		_noise(buf, 0.0, 0.98, 0.3, [[0.0, 600.0], [0.5, 2600.0], [0.9, 900.0]], 7.0, 0.12, 0.085, 0.95))

	_bank[&"growl"] = _render(0.6, func(buf):
		_noise(buf, 0.0, 0.58, 0.55, [[0.0, 260.0], [0.4, 150.0]], 3.0, 0.06, 0.07, 0.5))

	_bank[&"levelup"] = _render(0.95, func(buf):
		var notes := [523.0, 659.0, 784.0, 1047.0]
		for i in notes.size():
			_osc(buf, "triangle", i * 0.09, 0.5, notes[i], notes[i], false, 0.03, 0.055, 0.45))

	_bank[&"pickup"] = _render(0.45, func(buf):
		var notes := [660.0, 990.0]
		for i in notes.size():
			_osc(buf, "sine", i * 0.07, 0.24, notes[i], notes[i], false, 0.02, 0.05, 0.20))

	_bank[&"heal"] = _render(0.6, func(buf):
		var notes := [392.0, 523.0, 659.0]
		for i in notes.size():
			_osc(buf, "sine", i * 0.06, 0.38, notes[i], notes[i], false, 0.03, 0.045, 0.34))

	_bank[&"coin"] = _render(0.4, func(buf):
		var notes := [1180.0, 1560.0]
		for i in notes.size():
			_osc(buf, "triangle", i * 0.05, 0.28, notes[i], notes[i], false, 0.012, 0.030, 0.24))

	_bank[&"denied"] = _render(0.24, func(buf):
		_osc(buf, "sine", 0.0, 0.22, 196.0, 138.0, true, 0.02, 0.032, 0.20))

	_bank[&"quest"] = _render(0.9, func(buf):
		var notes := [349.0, 466.0, 587.0]
		for i in notes.size():
			_osc(buf, "triangle", i * 0.11, 0.65, notes[i], notes[i], false, 0.04, 0.05, 0.6))


## Runs a fill closure over a fresh buffer of [param dur] seconds, then packs it
## into a 16-bit PCM stream.
func _render(dur: float, fill: Callable) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	fill.call(buf)
	return _to_wav(buf)


## A tone. [param exp_sweep] chooses exponential vs linear frequency travel; the
## gain rises linearly to [param peak] over [param attack], then decays
## exponentially to silence over [param decay].
func _osc(buf: PackedFloat32Array, wave: String, t0: float, dur: float,
		f0: float, f1: float, exp_sweep: bool, attack: float, peak: float, decay: float) -> void:
	var start := int(t0 * RATE)
	var count := int(dur * RATE)
	var phase := 0.0
	for i in count:
		var idx := start + i
		if idx < 0 or idx >= buf.size():
			continue
		var u := float(i) / count
		var f := (f0 * pow(f1 / f0, u)) if exp_sweep else lerpf(f0, f1, u)
		phase += TAU * f / RATE
		var s := _wave(wave, phase)
		buf[idx] += s * _env(float(i) / RATE, attack, peak, decay)


## Smoothed noise, band-passed through a state-variable filter whose centre
## frequency follows [param freq_points] (geometric interpolation), with the same
## envelope shape as [method _osc].
func _noise(buf: PackedFloat32Array, t0: float, dur: float, smooth: float,
		freq_points: Array, q: float, attack: float, peak: float, decay: float) -> void:
	var start := int(t0 * RATE)
	var count := int(dur * RATE)
	var last := 0.0
	var low := 0.0
	var band := 0.0
	var q1 := 1.0 / q
	for i in count:
		var idx := start + i
		if idx < 0 or idx >= buf.size():
			continue
		var white := randf() * 2.0 - 1.0
		last = last * smooth + white * (1.0 - smooth)
		var x := last * (2.2 if smooth > 0.7 else 1.0)
		var f := _freq_at(freq_points, float(i) / count)
		var fp := 2.0 * sin(PI * minf(f, RATE * 0.45) / RATE)
		var high := x - low - q1 * band
		band += fp * high
		low += fp * band
		buf[idx] += band * _env(float(i) / RATE, attack, peak, decay)


func _freq_at(points: Array, u: float) -> float:
	if points.size() == 1:
		return points[0][1]
	var span: float = points[points.size() - 1][0]
	var tt := u * span
	for k in range(points.size() - 1):
		var a_t: float = points[k][0]
		var a_f: float = points[k][1]
		var b_t: float = points[k + 1][0]
		var b_f: float = points[k + 1][1]
		if tt <= b_t:
			var seg := (tt - a_t) / maxf(0.0001, b_t - a_t)
			return a_f * pow(b_f / a_f, seg)
	return points[points.size() - 1][1]


func _wave(wave: String, phase: float) -> float:
	match wave:
		"sine":
			return sin(phase)
		"triangle":
			return asin(sin(phase)) * (2.0 / PI)
		"saw":
			return fposmod(phase, TAU) / PI - 1.0
	return sin(phase)


func _env(tt: float, attack: float, peak: float, decay: float) -> float:
	if tt < attack:
		return peak * (tt / maxf(0.0001, attack))
	var d := (tt - attack) / maxf(0.0001, decay)
	return peak * pow(0.0007, clampf(d, 0.0, 1.0))


func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v := int(clampf(buf[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
