# Hollowmere — HTML → Godot parity checklist

**The work order.** Every system, feature, asset and piece of content in the HTML
build (`hollowmere.html`, notes v18.8) up to the **Yotan gate**, marked against the
current Godot build. Fixed in the order below, systems before polish. This is an
**expansion, not a replacement**: working Godot systems are kept; HTML defines
WHAT, Godot defines HOW.

**Status key:** ✅ Present (parity) · 🟡 Partial (exists, gaps listed) · ❌ Missing
· 🐞 Broken (diagnosed) · ➕ Godot-only (not in HTML)

**One standing deviation:** the HTML is 576×360 procedural. Per your locked R1
decision, Godot renders larger for the new sheet assets. Parity here means
**behaviour, numbers, content and feel** — not procedural pixels. Where a number
or a beat differs, that's a bug; where only the art medium differs, that's intended.

---

## Fix order (systems → polish) — SESSION PROGRESS

1. ✅ **Ghost damage** — plumbed weapon dmg into the swing; 3 hits, HP/5 untouched.
2. ✅ **NPC interaction facing** — interaction hold; stops, faces, resumes.
3. ✅ **Torches emit no light** — brazier PointLight2D read as warm pools.
4. ✅ **Equipment interface** — character sheet + pack; armour +5 wired into damage.
5. ✅ **Shop** — Ondrick, buy/sell, pricing, one-time key, data-driven.
6. ✅ **Minimap** — full port, hostile-only wraiths, hides underground.
7. ✅ **Atmosphere** — rain audio rebuilt (HP480/LP1750 + LFOs); visuals confirmed.
8. ✅ **Dialogue box** — typewriter, scroll, contrast, clean wrapping. *(portrait + branching choices deferred)*
9. ✅ **Enemies** — skeleton + zombie + Fallen Hunter boss + shared telegraphed melee AI + boss bar.
10. ✅ **Areas** — undercroft + Drowned Run + sewer2 + village↔area travel + well/grate/gate. *(Ondrick shop interior remaining)*
11. ✅ **Content** — full chest→sigil→key→Aldric→report→gate→ending spine. *(Ondrick/Nestor asides + 2 sewer notes remaining)*
12. ✅ **Herbert sprite** — elderly hooded elder with a staff (drawElder).

**Also done this session (beyond the original list):** death + respawn ("THE
DARK TAKES YOU"), skills (K) with embers + all three effects wired, undercroft
quest 2 playable (5 skeletons + 2 zombies), Fallen Hunter boss + boss bar,
undercroft reward chest (Long sword + Sigil), the Herbert sigil→key handover,
the Elphric report → Yotan gate (3 states) → ending card, the Drowned Run +
Aldric + 4-page letter + journal re-read block, the stamina HUD bar, vignette +
grain in every area + real additive fog, the hints scroll (T), the sewer hum +
2 sewer notes, banners for the landmark beats, the hanged man + rope gate on the
well, the inventory portrait, level-up HP/lamp/edge scaling actually applied,
owls (perched + positional hoot), whispers (4 shuffled lines).

**Verified end-to-end (final smoke test):** full spine walked village→undercroft→
Drowned Run→Hunter's hall and back, boss kill opens the report, all UI layers
intact, **zero script errors across the whole run.**

**Genuinely remaining (all secondary / beyond the gate):** the bow (post-gate
road reward, needs a projectile system), The Voice (post-gate road event),
Ondrick + Nestor extra asides, bone-hit / zombie-moan SFX, Ondrick's shop
interior room. None sit on the path to the Yotan gate.

## Remaining to reach the Yotan gate (biggest chunks first)

- ✅ **Drowned Run (sewer)** area + Sewer Key grate + Aldric + letter + 7 skeletons (30 HP)
- ✅ **Sewer2** area + **Fallen Hunter boss** + boss bar + green-flare tell
- ✅ **Content chain**: undercroft chest (Long sword + Sigil) → Herbert hands the
  Sewer Key → Aldric's body + 4-page letter → the Elphric recognition → report to
  Herbert → **Yotan gate** (barred/unbarred/open states) → the ending card.
  *The whole spine from chest to ending is now walkable end-to-end.*
- ✅ **hanged man** (rope gate on the well), **owls**, **whispers**, **sewer hum**,
  **hints scroll (T)**, **banners**, **inventory portrait**, the 2 sewer notes.
- 🟡 **Full Herbert/Ondrick/Nestor dialogue chains** — Herbert's full arc is in
  (sigil recoil, report, all quest states); Ondrick + Nestor asides still short-form.
- 🟡 **positional/HRTF audio** — owls + hoots pan by distance (AudioStreamPlayer2D);
  not true binaural HRTF.
- ❌ **Bow** (secondary, post-gate road reward), **The Voice** (post-gate road event).
- 🟡 **Drowned Run collision** — built as one wide room, not the HTML's zig-zag of
  64px corridors (no arbitrary corridor collision; flagged, content parity holds).

---

## A. Core / presentation

| Feature | HTML | Godot | Notes |
|---|---|---|---|
| Internal resolution | 576×360 pixelated | 🟡 576×360 now → 1280×720 (R1) | Deliberate deviation for sheet art |
| Darkness composite | lighting layer over scene | 🟡 | CanvasModulate + PointLight2D; ambient values need matching to HTML |
| Camera follow + shake | ✅ | ✅ | sine-tremor shake ported |
| **Minimap** (top-right, houses/trees/braziers/pyre/villagers/drops/viewport/player, hostile ghosts blink red, passive hidden) | ✅ | ✅ | full port; hides underground |
| Rain (village): scattered landing points, splashes, double-draw over-dark | ✅ | 🟡 | visuals partial; **audio bad → match HTML recipe** |
| Vignette (edges crushed 0.75) | ✅ | ✅ | ring-drawn; now every area, not village-only |
| Film grain (moving noise overlay) | ✅ | ✅ | 128px noise, jittered; every area |
| Fog (5 additive radial blobs r135 @0.10) | ✅ | ✅ | real ADD-blend node; village mist |

## B. Player (Nestor)

| Feature | HTML | Godot | Notes |
|---|---|---|---|
| 150 HP, red orb | ✅ | ✅ | |
| Lamp charge 100, green orb, drain 2/regen 1, auto-stow, relight>0 | ✅ | ✅ | |
| Torch r117 + lamp r93, one hand, sword other | ✅ | 🟡 | torch light radius/flicker vs HTML to verify |
| XP curve ×1.85; +12 HP / +4 lamp / +1 edge every 2 lvls | ✅ | ✅ | applied to the player on level-up; reward banner |
| Edge bonus (weaponDmg = base + edge) | ✅ | ✅ | plumbed into the swing; edge = floor(level/2) |
| Short sword geometry + cleave + reach | ✅ | ✅ | |
| Long sword (+5 reach, 12 dmg, own icon) | ✅ | ✅ | loot from the undercroft chest |
| Bow (secondary, TAB, 10 dmg, −20% move) | ✅ | ❌ | |
| Death: fade + "THE DARK TAKES YOU" + respawn, ghosts pacified | ✅ | ✅ | fade + hold + respawn at plaza |
| Run (Shift) + stamina nuggets + **HUD bar** | — | ➕ | Godot-only, kept per your call; now with a 10-cell bar above the belt in the HTML idiom (drains right-to-left, red pulse when locked) |

## C. Combat

| Feature | HTML | Godot | Notes |
|---|---|---|---|
| wind/strike/recover, arc hit, cleave, shake | ✅ | ✅ | |
| **Ghost dies in 3 hits (15 HP / 5 dmg)** | ✅ 3 hits | 🐞 **2 hits** | **ROOT CAUSE:** `Player._try_swing()` never sets `melee.damage` from the weapon, so the swing uses `MeleeAttack`'s `@export` default **8** (not the short sword's 5). 8+8=16 ≥ 15 → 2 hits. Fix: feed `held_weapon.damage (or unarmed) + PlayerProgress.damage_bonus()` into `melee.damage` at swing time. **Do NOT change the 15 HP or the 5 dmg.** |
| Armour flat reduction, floor 1 | ✅ | ✅ | take_damage subtracts armor_total(), floor 1 |
| Enemy telegraphs (windup poses) | ✅ | 🟡 | ghost only; other enemies missing |

## D. Enemies

| Enemy | HTML | Godot | Notes |
|---|---|---|---|
| Wraith/shade (15 HP, 24–40, lamp-reveal, 3.6s expose→hostile, chase through walls, drops soul+tear) | ✅ | 🟡 | present; **hostile red bleed-through + screen-edge red pulse missing**; positional growl missing |
| Skeleton — undercroft (20 HP, 28–40, shield, falchion, red eyes dark-on-hit, telegraph) | ✅ | ✅ | 5 in the undercroft, shared telegraph brain |
| Skeleton — sewer (30 HP) | ✅ | ✅ | 7 in the Drowned Run, HP set post-spawn |
| Zombie (20 HP, 45–60, 0.95s windup, both-arms grab) | ✅ | ✅ | 2 in the undercroft |
| Fallen Hunter / Elphric (165 HP, 44–67, green-flare tell, boss bar) | ✅ | ✅ | in sewer2; wears the player silhouette, green eyes |
| Ghost respawn 15–27s, validated spot | ✅ | ✅ | |

## E. NPCs

| Feature | HTML | Godot | Notes |
|---|---|---|---|
| Herbert — quest giver, marker !/? | ✅ | 🟡 | logic present; **sprite is not elderly-with-staff** (your note; applies to Herbert, not Nestor) |
| Villagers wander; 5 speak, 3 say "..." | ✅ | ✅ | |
| **NPC interaction facing** (stop autonomous move, turn to face player, resume) | ✅ | 🐞 | villager keeps wandering / walks away; state-machine fix, not speed |
| Ondrick (shopkeeper) | ✅ | ✅ | armour buy/sell; first-talk lines then shop |
| Owls (3 trees, hoot 16–42s) | ✅ | ✅ | perched + blink/turn + positional hoot (2D, not HRTF) |
| Hanged man (skeleton, quest-gated, cut rope → rope drop) | ✅ | ✅ | at the crooked tree after shades; rope gates the well |

## F. Inventory / equipment

| Feature | HTML | Godot | Notes |
|---|---|---|---|
| Pack 50 slots, belt = first 9, hotbar 1–9 | ✅ | ✅ | |
| Pickup → first free slot, refuse if full | ✅ | ✅ | |
| Soul powder heal +40, refuse at full (red flash) | ✅ | ✅ | |
| Crystalized tear (stack, vendor trash 5g) | ✅ | 🟡 | drops + stacks; selling missing (no shop) |
| **Equipment UI** (weapon/armour/pack; equip via 1–9; stats; portrait) | ✅ | ✅ | sheet + pack + slots wired to combat + breathing portrait |
| Long sword / mail / plate / rope / letter / shackle / sigil / bow items | ✅ | 🟡 | have lamp/torch/soul/tear/key/sigil/gold; rest missing |
| Pack panel | ✅ | ✅ | |

## G. UI

| Feature | HTML | Godot | Notes |
|---|---|---|---|
| HUD orbs (HP, lamp) + hotbar | ✅ | ✅ | |
| Journal (J) — VOWS + NOTES n/4 tabs + letter block | ✅ | ✅ | both tabs + re-readable Aldric letter |
| Skills panel (K) — 3 skills, embers, compounding cost | ✅ | ✅ | panel + all three effects wired |
| **Shop panel** (BUY/SELL, gold header) | ✅ | ✅ | Ondrick; buy/sell, one-time items |
| **Dialogue box** — frame, typewriter 44 c/s, scroll, advance indicator | ✅ | ✅ | typewriter + scroll + contrast; HTML dialogue has no portrait |
| Hints scroll (T) | ✅ | ✅ | controls (this build) + carried-item guide |
| Banners (level/quest/boss/vow) | ✅ | ✅ | gradient strip + title/sub; auto on level & quest, plus key beats |
| Toasts | ✅ | ✅ | |

## H. Quests (chain to Yotan)

| Quest | HTML | Godot | Notes |
|---|---|---|---|
| shades — banish 10 wraiths, 50 XP | ✅ | ✅ | playable end-to-end |
| undercroft — clear 7, 50 XP + 25g | ✅ | ✅ | map + 5 skeletons + 2 zombies playable |
| elphric — report to Herbert, 80 XP | ✅ | ✅ | boss death reveals it; Herbert report pays out |
| yotan — travel north, 100 XP | ✅ | ✅ | closes on the report; gate opens; ending card |
| Markers !/? (Herbert, well, minimap) | ✅ | 🟡 | Herbert only |
| Sewer Key handover (Herbert, on sigil) | ✅ | ✅ | |

## I. World / areas

| Area | HTML | Godot | Notes |
|---|---|---|---|
| Village (walls, north gate, 15 houses, pyre, well, cart, graves, fences, trees, braziers) | ✅ | 🟡 | procedural village present; **houses need the asset pass + variety**; gate states missing |
| Undercroft (dark room, blue torches, decor) | ✅ | ✅ | one wide room, not 5 (flagged) |
| Drowned Run (sewer, iron gate + key) | ✅ | 🟡 | built + key-gated; zig-zag corridors are one wide room (flagged) |
| Sewer2 (Fallen Hunter hall) | ✅ | ✅ | boss + boss bar |
| Ondrick's shop interior | ✅ | ❌ | |
| Herbert's house | ✅ (orphaned) | ❌ | orphaned in HTML too — skip |
| Area transitions (well/rope, gates, shaft) — validated standing spots | ✅ | ❌ | SceneDirector exists; transitions unbuilt |
| North gate: barred / unbarred / open states | ✅ | ✅ | 3 states, drawbar, open cue + ending |
| Collision `blocked()` | ✅ | ✅ | CollisionMap ported |

## J. Audio (all synthesized in HTML — reproduce the recipes, no files exist)

| Sound | HTML | Godot | Notes |
|---|---|---|---|
| Rain loop (noise, HP480/LP1750, 2 slow LFOs) | ✅ | 🐞 | **current rain is bad — reproduce the HTML recipe** (there is no rain *file*; it's synthesized) |
| Swing/hit/hurt/shriek/pickup/heal | ✅ | ✅ | |
| Ghost growl + death whimper (HRTF positional) | ✅ | 🟡 | growl present; positional + whimper missing |
| Sewer hum (34/34.6 Hz beat, felt not heard) | ✅ | ✅ | 10s loop; plays in all 3 underground areas |
| Whispers (4 lines, 20s walking) | ✅ | 🟡 | shuffled lines + breathy sound, walk-gated; not circling-HRTF |
| Owl hoots / bone SFX / zombie moan | ✅ | 🟡 | owl hoot synthesized + positional; bone/moan pending |
| level/quest/vow/gateopen/coin/denied | ✅ | 🟡 | have level/quest/coin/denied; vow/gateopen missing |
| Positional (HRTF) panning | ✅ | 🟡 | AudioStreamPlayer2D distance/pan on owls; not binaural HRTF |

## K. Lore / content

| Content | HTML | Godot | Notes |
|---|---|---|---|
| 4 scattered notes (village ×2, sewer, sewer2) + pickup + Notes tab | ✅ | ✅ | all 4 spawn + collectable + journal Notes tab |
| Aldric's letter (4 pages, re-readable, journal block) | ✅ | ✅ | on the body + re-read block in journal |
| Dialogue: Herbert full chain, Ondrick, Nestor hunter-down, villager lines | ✅ | 🟡 | Herbert quest lines present; rest missing |
| The Voice | ✅ | ❌ | |
| Whisper events (4 lines) | ✅ | ✅ | shuffled, one per 20s of walking |

---

## Godot-only additions to reconcile (not in HTML)

- ➕ **Stamina / run (Shift):** the HTML has no stamina or run. Keep as an
  expansion, or cut for strict parity? Your call — I will not remove it silently.
- ➕ **Art-pack props + TileSet** (trees/rocks/chests/boxes, dirt/grass/road): the
  new-assets direction. Not a parity conflict; it's the "with the new assets" part.

## Things I cannot reproduce identically (flagged, not approximated silently)

- **HRTF positional audio:** the HTML uses a Web Audio HRTF panner (true binaural).
  Godot's AudioStreamPlayer2D gives stereo distance/pan, not HRTF. I'll match
  *positioning and falloff*; the binaural head-model is not reproducible without a
  custom DSP — say if you want me to attempt one.
- **Exact procedural sprite pixels:** we're on sheet art now by your direction, so
  characters/props won't be pixel-identical to the HTML's `fillRect` art. Behaviour
  and silhouette-read parity, yes; pixel parity, no (intended).

---

*Nothing has been changed yet. Awaiting your go on this checklist before I start
at fix #1 (ghost damage).*
