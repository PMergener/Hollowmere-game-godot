class_name SoundBank
extends Resource

## A named set of sounds, so nothing in the game refers to an audio file by
## path. Ask for "hit" and the bank decides what that means for this creature.
##
## Give a key several streams and one is chosen at random, which stops a
## repeated sound from turning into a metronome.

@export var streams: Dictionary = {}

@export_group("Playback")
@export_range(0.0, 2.0, 0.01) var volume_scale: float = 1.0
## Random pitch spread. 0.1 means each play lands within 10 percent of normal.
@export_range(0.0, 0.5, 0.01) var pitch_variance: float = 0.08


## Returns null when the bank has nothing under this name, which is not an
## error: a creature without a death sound simply dies quietly.
func pick(key: StringName, rng: RandomNumberGenerator) -> AudioStream:
	if not streams.has(key):
		return null
	var value: Variant = streams[key]
	if value is AudioStream:
		return value
	if value is Array and not (value as Array).is_empty():
		var list: Array = value
		return list[rng.randi_range(0, list.size() - 1)]
	return null
