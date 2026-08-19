extends Node

## Moves the player between areas.
##
## Areas are ordinary scenes. This swaps which one is loaded, puts the player on
## the named spawn point, and applies that area's light, weather and sound. It
## does not know what any particular area contains - a new dungeon needs no code
## here, only a scene with a spawn point in it.
##
## The world registers itself on startup rather than being looked up by path, so
## renaming a node in Main cannot silently break travel.

signal transition_finished()

const FADE_SECONDS := 0.35

var current_area: GameArea = null
var current_area_id: StringName = &""

var _host: Node2D = null
var _player: Node2D = null
var _modulate: CanvasModulate = null
var _fade: ColorRect = null
var _busy := false


## Called once by Main. Everything else here depends on it.
func register_world(host: Node2D, player: Node2D, modulate: CanvasModulate, fade: ColorRect) -> void:
	_host = host
	_player = player
	_modulate = modulate
	_fade = fade


func is_ready_to_travel() -> bool:
	return _host != null and _player != null and not _busy


## Loads an area and puts the player on [param spawn_point]. When the spawn
## point does not exist the player lands at the area origin and a warning is
## printed - visible and wrong beats invisible and wrong.
func go_to(scene_path: String, spawn_point: StringName = &"default") -> void:
	if not is_ready_to_travel():
		push_warning("SceneDirector: world not registered, or a change is already running.")
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneDirector: no scene at %s" % scene_path)
		return
	_busy = true
	_change(scene_path, spawn_point)


func _change(scene_path: String, spawn_point: StringName) -> void:
	await _fade_to(1.0)

	if current_area != null:
		EventBus.area_exited.emit(current_area_id)
		current_area.queue_free()
		# Wait for it to actually leave the tree before the next one arrives,
		# or both areas exist for a frame and their triggers both fire.
		await current_area.tree_exited

	var packed: PackedScene = load(scene_path)
	var area := packed.instantiate()
	if not (area is GameArea):
		push_error("SceneDirector: %s is not a GameArea." % scene_path)
		_busy = false
		await _fade_to(0.0)
		return

	current_area = area as GameArea
	_host.add_child(current_area)
	# Let the area run its own _ready before anything is asked of it.
	await get_tree().process_frame

	_place_player(spawn_point)
	_apply_area_mood(current_area.area_data)

	current_area_id = current_area.area_id()
	EventBus.area_entered.emit(current_area_id)

	await _fade_to(0.0)
	_busy = false
	transition_finished.emit()


func _place_player(spawn_point: StringName) -> void:
	var marker := current_area.spawn_point(spawn_point)
	if marker == null:
		push_warning("SceneDirector: area '%s' has no spawn point '%s'." % [current_area_id, spawn_point])
		_player.global_position = current_area.global_position
		return
	_player.global_position = marker.global_position
	if _player.has_method(&"face_direction"):
		_player.call(&"face_direction", marker.facing)


func _apply_area_mood(data: AreaData) -> void:
	if data == null:
		return
	if _modulate != null:
		_modulate.color = data.ambient_light
	AudioDirector.set_ambience(data.ambience, data.ambience_volume)
	AudioDirector.set_drone(data.drone, data.drone_volume)


func _fade_to(alpha: float) -> void:
	if _fade == null:
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished
