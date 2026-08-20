@tool
extends EditorPlugin

## The Hollowmere RPG editor. Every dock, gizmo and importer the designer uses is
## registered here and torn down cleanly in _exit_tree - the plugin leaves no
## leaked controls or types behind when disabled.
##
## Kept deliberately thin: it wires modules together and owns nothing itself.
## Each capability lives in its own module under addons/rpg_editor/.

const EntityPalette := preload("res://addons/rpg_editor/docks/entity_palette.gd")

var _entity_palette: Control


func _enter_tree() -> void:
	_entity_palette = EntityPalette.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _entity_palette)


func _exit_tree() -> void:
	if _entity_palette != null:
		remove_control_from_docks(_entity_palette)
		_entity_palette.queue_free()
		_entity_palette = null
