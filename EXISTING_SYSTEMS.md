# Existing systems — the contract the editor integrates with

Engine: **Godot 4.7.1** (config feature "4.7"). TileMapLayer, terrain autotiling,
GraphEdit, EditorUndoRedoManager, `EditorInterface.play_custom_scene()` all
available. The event interpreter and every editor action must call the APIs below
— never re-implement them.

## Autoloads (global singletons)

| Autoload | File | Owns |
|---|---|---|
| `EventBus` | src/core/event_bus.gd | The signal hub. **`game_event(name, payload)`** is the event backbone. |
| `PlayerProgress` | src/core/player_progress.gd | Level, XP, gold, embers, skill ranks. |
| `ItemDb` | src/core/item_db.gd | `get_item(id) -> ItemData`, `has(id)`. Loads data/items + data/weapons. |
| `Inventory` | src/core/inventory.gd | The pack, belt, equipment. |
| `QuestLog` | src/core/quest_log.gd | Quest state machine, counts `game_event`s. |
| `SceneDirector` | src/core/scene_director.gd | `go_to(scene_path, spawn)` area travel. |
| `AudioDirector` | src/core/audio_director.gd | Ambience/drone/positional banks. |
| `Sfx` | src/systems/sfx.gd | Synthesized SFX + rain ambience. |
| `CollisionMap` | src/world/collision_map.gd | Rect collision (`blocked`, `add_solid`, …). |

## Public API the event interpreter calls

**EventBus** — `emit_event(name: StringName, payload := {})`, `toast(text)`, and the
generic `signal game_event(name, payload)`. Every trigger source and every
"set flag / notify" action rides this. Typed signals also exist (player_died,
level_gained, enemy_died(id,pos), quest_completed(quest), dialogue_finished, …).

**PlayerProgress** — `add_xp(int)`, `add_gold(int)`, `spend_gold(int) -> bool`,
`add_embers(int)`, `buy_skill(SkillData) -> bool`, `rank_of(SkillData) -> int`,
`damage_bonus() -> int`, `max_health() -> int`. State: level, xp, gold, embers.

**Inventory** — `add(ItemData, amount:=1) -> int(unfit)`, `remove(id, amount:=1) -> int`,
`count_of(id) -> int`, `has_item(id) -> bool`, `equip_from_pack(index) -> bool`,
`use_slot(index) -> bool`, `slot(index) -> ItemStack`. Items resolved by id via
`ItemDb.get_item(id)`.

**QuestLog** — `by_id(id) -> QuestData`, `state_of(q) -> State`, `count_of(q) -> int`,
`accept(q)`, `hand_in(q) -> bool`, `add_progress(q, n:=1)`, `reveal(q)`, `begin(q)`.
Progress is event-driven: a QuestData names `counts_event`, and any matching
`EventBus.game_event` advances it. **This is already the trigger→objective wiring
the quest builder needs.**

**SceneDirector** — `go_to(scene_path: String, spawn := &"default")` for the
change-map / teleport action. `register_world(...)` is called once by Main.

**Audio** — `Sfx.play(name, db, pitch)`, `Sfx.play_ambience(name, db)`,
`AudioDirector.set_ambience(stream, vol, fade)` / `set_drone(...)`.

**Combat (real-time, action)** — `MeleeAttack` (src/combat/melee_attack.gd) runs
the swing; on the strike it queries the **`hurtable`** group and calls
`take_melee_hit(damage: int, from_position: Vector2)` on each. `Enemy`
(src/actors/enemy.gd) answers that, exposes `is_hittable()`, `melee_hit_offset()`,
`signal died()`, and on death emits `enemy_died` + a `<id>_killed` game_event.
`Player.take_damage(dmg, armour)`. Camera shake lives on the player.

**Dialogue** — runtime is `DialogueBox` (src/ui/dialogue_box.gd), fed by
`EventBus.dialogue_requested(speaker, lines: PackedStringArray)`. **Linear lines
only today** — no portraits, choices or branching at runtime.

## Constraints & gaps the editor forces (smallest additions to propose)

1. **No flags/variables store.** Triggers/events need persistent named flags and
   variables. → add a lean `GameState` autoload (flags: Dictionary, variables:
   Dictionary; get/set/toggle/increment; emits `game_event` on change). Core to M3.
2. **No save/load.** Flags, quest state and progress do not persist. → a small
   `SaveSystem` (serialize GameState + PlayerProgress + QuestLog + Inventory to
   user://). Needed once flags exist; schedule with M3/M4.
3. **Combat is real-time, not encounter-based.** "Start battle with an encounter"
   has no battle scene. → interpret as **spawn an encounter group** (enemies
   placed/spawned in the live map). No turn-based system will be built unless asked.
4. **Dialogue runtime is linear.** Branching/portraits/choices need `DialogueBox`
   extended to consume a `DialogueData` resource (which already exists, unused). →
   smallest addition: teach DialogueBox to render DialogueData + emit the chosen
   branch as a `game_event`. Schedule with M3.
5. **Enemies are not yet scene/data-driven.** `Ghost` is instantiated in code;
   `EnemyData` exists but is unused. → enemies become PackedScenes (one per type)
   carrying an `EnemyData`, so the palette can list and place them. Schedule M2.
6. **Maps are code-built** (WorldData + procedural draw). → new maps use
   TileMapLayer scenes; CollisionMap already supports per-scene `add_solid`.
   Schedule M1. Existing village is migrated opportunistically, not blindly.
7. **No time-of-day or weather-change runtime hooks.** CanvasModulate + weather.gd
   exist; a `time_of_day` on the map resource driving CanvasModulate is the add. M6.

**Rule:** if an event action needs something a system doesn't expose, add the
smallest method to that system's public API and record it here — never duplicate
its logic in the interpreter.
