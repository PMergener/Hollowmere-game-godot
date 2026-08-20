# Making maps in Hollowmere

You build maps by **placing things in a scene**, not by editing code. This guide
covers the prop toolkit that is in now: trees, rocks, chests and crates from your
art packs.

## The one-minute version

1. In Godot, open **`scenes/areas/village_props.tscn`** (double-click it in the
   FileSystem panel, bottom-left).
2. In the same FileSystem panel, open **`scenes/props/`**. You'll see folders:
   `trees`, `rocks`, `chests`, `boxes`.
3. **Drag any prop** (e.g. `trees/tree_5.tscn`) from there onto the map in the
   middle of the screen. It appears where you drop it.
4. **Move it** by dragging, or with the arrow keys. Its position IS where it will
   be in the game — no numbers to type.
5. Press **Ctrl+S** to save, then **F5** to play and walk around it.

That's a map edit. Everything below is just detail.

## What each prop does

- **Trees / rocks** — decoration that blocks the way. You walk *behind* the top
  of a tree but bump into its base.
- **Chests** (`scenes/props/chests/`) — open once when you press **E** near them,
  paying out coins and items, then dim to show they're spent.
- **Boxes** (`scenes/props/boxes/`) — crates that block the way until you smash
  them with a swing; sometimes a coin spills out.

> Chests and boxes are **not** interchangeable. A chest is opened; a crate is
> broken. They come from the same art pack but live in separate folders so they
> never get mixed up.

## Tuning a prop (optional)

Click a placed prop and look at the **Inspector** (right side). You can change:

- **Texture** — swap which tree/rock/chest this is, without replacing the node.
- **Blocks** — untick to make it pure decoration you can walk through.
- **Collision Size** — how big its solid base is, in pixels. Make it smaller if
  the block feels too wide, bigger if you can clip through a corner.
- **Foot Trim** — nudge the art up/down if it looks like it's floating or sunk.

For a **chest**, you also get **Coins** and **Contents** (drag item `.tres`
files from `data/items/` into Contents to put them inside).

## Adding your own art

Drop a new sprite sheet into `assets/art assets/…`, then a sprite gets sliced
out by the baker. For now the packs are pre-sliced into `assets/props/`. When you
add a new pack, tell me its layout (how many props across, any label column) and
I'll bake it into individual, background-removed sprites and generate the
draggable scenes for it — the same way trees and rocks were done.

## What's coming next

Still to build on top of this: paintable ground tiles, enemy spawners you drop in
and set a count on, doorways that carry you to another map, and trigger zones for
events. Those turn "a screen with props" into "a map with a dungeon under it."
