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
var _ambience: AudioStreamPlayer


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = &"Master"
	add_child(_ambience)
	_build_all()
	# A couple of sounds are universal enough to wire straight to the event bus
	# rather than making every caller remember them. Connected once, here - it used
	# to live in stop_ambience(), which re-subscribed on every trip underground and
	# stacked the level-up chime one louder each time.
	EventBus.level_gained.connect(func(_lvl: int) -> void: play(&"levelup"))


## Starts a looping bed - rain over the village - under everything. Passing "" or
## an unknown name stops it.
func play_ambience(sound_name: StringName, volume_db: float = -8.0) -> void:
	if not _bank.has(sound_name):
		_ambience.stop()
		return
	_ambience.stream = _bank[sound_name]
	_ambience.volume_db = volume_db
	_ambience.play()


func stop_ambience() -> void:
	_ambience.stop()


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

	_bank[&"rain"] = _build_rain()
	_bank[&"hum"] = _build_hum()
	# A dry bone knock: a short high click of noise over a low woody tick.
	_bank[&"bone"] = _render(0.16, func(buf: PackedFloat32Array) -> void:
		_noise(buf, 0.0, 0.10, 0.15, [[0.0, 2600.0], [1.0, 1400.0]], 1.5, 0.004, 0.26, 0.09)
		_osc(buf, "triangle", 0.0, 0.10, 190.0, 120.0, true, 0.004, 0.20, 0.09))
	# A whisper: three breathy band-passed syllables, no pitch, just air shaped into
	# something that was almost a word. Bandpasses climbing 700->2000 Hz.
	_bank[&"whisper"] = _render(1.3, func(buf: PackedFloat32Array) -> void:
		_noise(buf, 0.00, 0.34, 0.4, [[0.0, 700.0], [1.0, 1900.0]], 4.0, 0.05, 0.22, 0.30)
		_noise(buf, 0.40, 0.30, 0.4, [[0.0, 900.0], [1.0, 1600.0]], 4.5, 0.05, 0.20, 0.28)
		_noise(buf, 0.74, 0.40, 0.4, [[0.0, 800.0], [1.0, 2000.0]], 4.0, 0.05, 0.24, 0.40))
	# An owl's two-note call: a soft low "hoo... hoo", the second lower and longer.
	_bank[&"owl"] = _render(0.95, func(buf: PackedFloat32Array) -> void:
		_osc(buf, "sine", 0.0, 0.30, 402.0, 360.0, false, 0.04, 0.34, 0.24)
		_osc(buf, "sine", 0.02, 0.30, 201.0, 180.0, false, 0.04, 0.12, 0.24)   # a fifth under
		_osc(buf, "sine", 0.40, 0.44, 322.0, 286.0, false, 0.05, 0.38, 0.36)
		_osc(buf, "sine", 0.42, 0.44, 161.0, 143.0, false, 0.05, 0.13, 0.36))


## The underground bed: the HTML's deep hum. Two sub-oscillators at 34 and 34.6 Hz
## beating against each other about once every 1.7s, a 51 Hz triangle body, a
## whisper of noise for air, everything rolled off under a 120 Hz low-pass and
## breathing on a very slow swell. Meant to be felt, not heard. A 10s loop: 34,
## 34.6 and 51 Hz all complete whole cycles in 10s, so the tones loop with no seam
## and a short crossfade hides the swell's.
func _build_hum() -> AudioStreamWAV:
	var n := RATE * 10
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	const A_LP := 0.0233                      # one-pole low-pass at ~120 Hz
	for i in n:
		var tt := float(i) / RATE
		var ph := 51.0 * tt
		var tri := 4.0 * absf(ph - floorf(ph + 0.5)) - 1.0
		var s := 0.5 * sin(TAU * 34.0 * tt) + 0.5 * sin(TAU * 34.6 * tt) + 0.22 * tri
		s += (randf() * 2.0 - 1.0) * 0.05     # air
		lp += (s - lp) * A_LP
		var swell := 1.0 + 0.30 * sin(TAU * 0.1 * tt)
		buf[i] = lp * 0.5 * swell
	var fade := 1200
	for i in fade:
		var a := float(i) / fade
		buf[i] = lerpf(buf[n - fade + i], buf[i], a)
	var wav := _to_wav(buf)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav


## The rain bed, to the HTML build's EXACT recipe - the earlier port missed the two
## things that made it read as rain rather than harsh hiss:
##   * the white noise is PRE-SMOOTHED (s2 = s2*0.32 + w*0.68) before it ever reaches
##     the filters. Raw white noise band-passed is a fizzing static; the one-pole on
##     the source is what turns it into a soft wash.
##   * a slow LFO drifts the LOW-PASS CUTOFF (1750 +-430 Hz), so the brightness of
##     the rain breathes - a fixed filter reads as a flat sheet of noise.
## A second slower LFO gusts the level. HP 480 throughout. A 12s loop (one full
## brightness breath) with the tail cross-faded into the head. Played quiet, near
## the HTML's baseVol 0.05, so it sits UNDER the game instead of over it.
func _build_rain() -> AudioStreamWAV:
	var n := RATE * 12
	var buf := PackedFloat32Array()
	buf.resize(n)
	const A_HP := 0.9139                 # one-pole high-pass at 480 Hz
	var s2 := 0.0                        # pre-smoothing state on the source noise
	var lp := 0.0
	var hp := 0.0
	var prev := 0.0
	for i in n:
		var tt := float(i) / RATE
		var w := randf() * 2.0 - 1.0
		s2 = s2 * 0.32 + w * 0.68        # soften the noise BEFORE the filters
		# low-pass cutoff drifts 1750 +-430 Hz on a slow breath -> brightness moves
		var fc := 1750.0 + 430.0 * sin(TAU * tt / 12.0)
		var a_lp: float = clampf(1.0 - exp(-TAU * fc / RATE), 0.0, 1.0)
		lp += (s2 - lp) * a_lp
		hp = A_HP * (hp + lp - prev)
		prev = lp
		# a slower gust on the level, +-22%, two cycles across the loop
		var gust := 1.0 + 0.22 * sin(TAU * tt / 6.0)
		buf[i] = hp * 0.85 * gust
	var fade := 1500
	for i in fade:
		var a := float(i) / fade
		buf[i] = lerpf(buf[n - fade + i], buf[i], a)
	var wav := _to_wav(buf)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav


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
