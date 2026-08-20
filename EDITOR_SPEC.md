# Hollowmere RPG Editor — spec & locked decisions

A complete in-engine editor so the designer builds content — maps, enemies,
dialogue, quests, skills — entirely in Godot, never opening a script. Ships as a
Godot 4.7 EditorPlugin. Client = game designer; I = developer/art director.

## Locked architecture

- **Plugin folder:** everything editor-only lives in `addons/rpg_editor/`.
  Runtime systems that read the data stay in `src/` (they are the shared schema).
- **Content = custom Resources** (`@tool` + `class_name`, saved as `.tres`). The
  Inspector, drag-and-drop and versioning come free. No JSON, no hand-rolled
  property panels where an Inspector will do.
- **One schema, two consumers.** The `class_name` Resources in `src/resources/`
  are imported by both the running game and the editor. Game holds zero hardcoded
  content; editor holds zero game logic.
- **Every editor mutation goes through `EditorUndoRedoManager`** so Ctrl+Z works.
- **Do not rebuild what Godot ships:** TileMapLayer + TileSet terrain for maps;
  PackedScene instancing for entities; PointLight2D/CanvasModulate/GPUParticles2D
  for light/FX; native import for PNG/WAV/OGG; `play_custom_scene()` for playtest.
- **Interpreter is a thin dispatcher.** It reads an event Resource and calls the
  existing system APIs in EXISTING_SYSTEMS.md. It never resolves damage, rolls
  drops or owns combat state.

## Locked art-direction constants (Option A — raise to the assets' resolution)

- The uploaded packs are **RPG-Maker-scale art** (~200px characters, 16px base
  tile) — ~7× the old 576×360 procedural look. Option A is chosen: the game is
  re-based to the assets' density so they live at an **integer** scale.
- **Base tile: 16px.** All road/ground pieces are 16px multiples.
- **Integer scaling only.** No fractional scale, ever. An asset that will not sit
  on the grid at an integer factor is flagged for redraw, not scaled to fit.
- **Nearest-neighbour filtering** project-wide; no sub-pixel sprite positions.
- **Anchors:** every sprite anchored to how it sits (feet on ground / base at
  tile line), never default-centre.
- **Exact target internal resolution + character display size are finalized at
  M1**, tested against the real TileSet, then recorded here. (Deferred so the
  number is measured, not guessed. M0 is engine plumbing and does not depend on it.)

## Plugin folder layout

```
addons/rpg_editor/
  plugin.cfg
  rpg_editor.gd            # EditorPlugin: registers docks/gizmos, cleans up in _exit_tree
  docks/                   # bottom/side panels (entity palette, event editor, validation…)
  gizmos/                  # forward_canvas_* handle drawing for region/path/spawn nodes
  nodes/                   # @tool Node2D types placed in maps (TriggerRegion, PatrolPath…)
  ui/                      # shared UI primitives (property row, list panel, resource picker)
  import/                  # EditorImportPlugin(s) (GIF → SpriteFrames), sprite slicer
  icons/                   # dock/node icons
```

Content Resources live in `src/resources/` (existing schema). Authored `.tres`
content lives under `data/` and `scenes/` as today.

## Module boundaries

- **Docks** present and mutate Resources; they never contain game logic.
- **Gizmos** draw handles and translate viewport input into Resource edits
  (through EditorUndoRedoManager). One gizmo module per node type.
- **Runtime interpreter** (`src/systems/event_interpreter.gd`, added M3) is the
  only editor-authored data consumer at runtime, and only calls documented APIs.
- **Shared UI primitives** (ui/) are built once and reused by every dock. Build a
  primitive the first time a second dock needs it — not before.

## Conventions

- Files under ~300 lines, one feature per file. GDScript only unless justified.
- Resource `class_name`s are PascalCase and end in their kind (`QuestData`,
  `TriggerData`, `EventStep`). Editor-only scripts are snake_case files.
- Designer-facing `@export` names are plain language via `@export_group` +
  `@export_range`; tooltips on anything non-obvious.
- No dead code, no commented-out blocks, no unrequested abstractions.

## Build order (must load & be useful after each)

M0 skeleton + schema + entity palette dock · M1 map resource + TileSet + transition/
region gizmos · M2 enemy/NPC instance props + patrol/aggro + drop tables · M3
trigger/event editor + dialogue + runtime interpreter · M4 quest builder · M5
skill builder + tree · M6 lighting/FX presets + time-of-day · M7 sprite slicer +
GIF importer + validation dock + playtest polish.

## Decision log (append as locked)

- **D1 (M0):** Existing `src/resources/*` are the schema; not moved into the
  addon. The addon depends on them; the game does too. Satisfies "one schema".
- **D2 (M0):** Entity palette drags a scene into the viewport by presenting Godot
  a `{"type":"files"}` drag payload, reusing the engine's native scene-drop and
  its built-in undo — no custom instancing code.
- **D3 (R1, locked by designer):** Internal resolution **1280×720**, integer
  scaling, art shown near native. 16px base tile. The procedural characters/HUD
  are rebased to this scale (M1+). Exact character display size cut from the
  sheets at M1.
- **D4 (ground, locked by designer):** Village interior + roads are **dirt**;
  **grass** on the outer margins. Use the `Road*_ground` blends inside and
  `Road*_grass` at the edges.
- **D5 (locked by designer):** A lean `GameState` (flags/variables) + `SaveSystem`
  arrive at M3/M4. "Start battle" = **spawn an encounter group** (real-time), no
  turn-based battle scene.
