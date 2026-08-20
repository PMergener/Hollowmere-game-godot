# Hollowmere RPG Editor — progress

Read this + EDITOR_SPEC.md + EXISTING_SYSTEMS.md at the start of every session.

## Milestones

- [x] **M0 — Plugin skeleton, schema, entity palette dock** — DONE
  - [x] System audit → EXISTING_SYSTEMS.md
  - [x] EDITOR_SPEC.md + EDITOR_PROGRESS.md
  - [x] `addons/rpg_editor/` + plugin.cfg + EditorPlugin (clean _exit_tree)
  - [x] Entity palette dock: scans scenes/enemies + scenes/npcs, thumbnails via
		the engine previewer, drag→viewport via native "files" payload
  - [x] Example entity scenes: wraith, herbert, villager
  - Note: procedural entities have no in-editor art preview yet (scripts aren't
    @tool); this resolves for free at M2 when entities become sheet-based
    Sprite2D/AnimatedSprite2D scenes that preview natively.
- [~] **M1 — Map resource + TileSet authoring + MapTransition/TriggerRegion gizmos** ← in progress
  - [x] Tiles derived from the Tiled file: **16px**, 15-col road atlases, 17-col
        ground atlas. Fill tiles found by opaque-scan: dirt ground_grass(10,2),
        grass (3,8), cobble road_ground(2,2).
  - [x] TileSet authored → `assets/tilesets/hollowmere.tres` (all cells paintable)
  - [x] `scenes/areas/demo_map.tscn` — TileMapLayer, dirt + grass margins + road
        cross, a SpawnPoint. **Visible and paintable in the editor.**
  - [ ] Terrain autotiling (road edges blend) — deferred; needs GUI iteration
  - [ ] Resolution rebase to 1280x720 + HUD reflow + camera (R1) — next unit
  - [ ] MapData resource (name, music, ambient light, time-of-day, encounter table)
  - [ ] MapTransition + TriggerRegion viewport gizmos
  - Note: dirt fill reads bright in raw render; verify/possibly pick a darker tile
	once the map is wired under the game's lighting (with the resolution unit).
- [ ] **M2 — Enemy/NPC instances: properties, patrol paths, aggro gizmos, drop tables**
- [ ] **M3 — Trigger/event editor + dialogue authoring + runtime interpreter**
- [ ] **M4 — Quest builder wired to triggers**
- [ ] **M5 — Skill builder + skill-tree GraphEdit**
- [ ] **M6 — Lighting/FX preset palette + time-of-day**
- [ ] **M7 — Sprite slicer + GIF importer + validation dock + playtest button + polish**

## Open questions for the designer

All resolved (see EDITOR_SPEC decision log D3–D5):
1. ~~Resolution~~ → **R1: 1280×720, integer scale** (D3).
2. ~~Save/load + flags~~ → approved, lean at M3/M4 (D5).
3. ~~"Start battle"~~ → spawn encounter group (D5).
4. ~~Ground~~ → **dirt village + dirt road, grass margins** (D4).

## Status

**M0 complete.** Plugin loads clean; game runs unchanged (plugin is editor-only).
The "Entities" dock lists the wraith/herbert/villager scenes and drags them into
the viewport.

**Next: M1** — but it is gated on the resolution decision (open question 1). M1
starts by locking the internal resolution + character display size against the
real TileSet, then authoring the TileSet from the road/ground packs. Awaiting the
designer's answers on resolution numbers and grass-vs-dirt before rebuilding the
world at the new scale.
