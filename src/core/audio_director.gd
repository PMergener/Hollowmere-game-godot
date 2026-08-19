extends Node

## The only thing in the game that plays a sound.
##
## Nothing else touches an AudioStreamPlayer. A skeleton asks its SoundBank for
## "hit" and hands it here; whether that is one file or one of four, how loud it
## is and where it sits in the mix is decided in one place.
##
## Positional sounds come out of a pool, because creating a player per swing and
## freeing it afterwards is how a game acquires a stutter.

const POOL_SIZE := 16
const AMBIENCE_FADE := 1.5

var _pool: Array[AudioStreamPlayer2D] = []
var _next_in_pool := 0
var _ui_player: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _drone: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var _tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()

	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer2D.new()
		player.bus = &"SFX"
		player.max_distance = 420.0
		add_child(player)
		_pool.append(player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = &"UI"
	add_child(_ui_player)

	_ambience = _make_loop_player(&"Ambience")
	_drone = _make_loop_player(&"Ambience")


func _make_loop_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.volume_db = -80.0
	add_child(player)
	return player


# --- One-off sounds ---------------------------------------------------------

## Plays a named sound from a bank at a place in the world. Silently does
## nothing when the bank has no such sound, which is correct: a creature with no
## death cry simply dies quietly.
func play_at(bank: SoundBank, key: StringName, world_position: Vector2) -> void:
	if bank == null:
		return
	var stream := bank.pick(key, _rng)
	if stream == null:
		return
	var player := _take_from_pool()
	player.stream = stream
	player.global_position = world_position
	player.volume_db = linear_to_db(maxf(0.001, bank.volume_scale))
	player.pitch_scale = 1.0 + _rng.randf_range(-bank.pitch_variance, bank.pitch_variance)
	player.play()


## Same, but flat in the middle of the mix. For menus and the journal.
func play_ui(bank: SoundBank, key: StringName) -> void:
	if bank == null:
		return
	var stream := bank.pick(key, _rng)
	if stream == null:
		return
	_ui_player.stream = stream
	_ui_player.volume_db = linear_to_db(maxf(0.001, bank.volume_scale))
	_ui_player.pitch_scale = 1.0 + _rng.randf_range(-bank.pitch_variance, bank.pitch_variance)
	_ui_player.play()


func _take_from_pool() -> AudioStreamPlayer2D:
	# Prefer a player that has finished; steal the oldest if they are all busy.
	for i in range(_pool.size()):
		var index := (_next_in_pool + i) % _pool.size()
		if not _pool[index].playing:
			_next_in_pool = (index + 1) % _pool.size()
			return _pool[index]
	var stolen := _pool[_next_in_pool]
	_next_in_pool = (_next_in_pool + 1) % _pool.size()
	return stolen


# --- Beds -------------------------------------------------------------------

## The looping sound of a place: rain outside, water underground.
func set_ambience(stream: AudioStream, volume: float, fade: float = AMBIENCE_FADE) -> void:
	_crossfade(_ambience, stream, volume, fade)


## A second, lower bed under the first. The sewers use it.
func set_drone(stream: AudioStream, volume: float, fade: float = AMBIENCE_FADE) -> void:
	_crossfade(_drone, stream, volume, fade)


func _crossfade(player: AudioStreamPlayer, stream: AudioStream, volume: float, fade: float) -> void:
	var previous: Tween = _tweens.get(player, null)
	if previous != null and previous.is_valid():
		previous.kill()

	var target_db := -80.0 if (stream == null or volume <= 0.0) else linear_to_db(volume)

	if player.stream == stream:
		# Same bed, new level: just ride the volume.
		var ride := create_tween()
		ride.tween_property(player, "volume_db", target_db, fade)
		_tweens[player] = ride
		return

	var tween := create_tween()
	tween.tween_property(player, "volume_db", -80.0, fade * 0.5)
	tween.tween_callback(_swap_stream.bind(player, stream))
	if stream != null and volume > 0.0:
		tween.tween_property(player, "volume_db", target_db, fade * 0.5)
	_tweens[player] = tween


func _swap_stream(player: AudioStreamPlayer, stream: AudioStream) -> void:
	player.stop()
	player.stream = stream
	if stream != null:
		player.play()


# --- Mix --------------------------------------------------------------------

func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), muted)


func is_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Master"))


func toggle_mute() -> bool:
	var next := not is_muted()
	set_muted(next)
	return next
