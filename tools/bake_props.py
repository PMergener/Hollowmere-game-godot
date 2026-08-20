# Slice the prop/terrain art packs into individual, background-keyed sprites the
# Godot editor can drop into a map.
#
# Each pack is a labelled contact sheet: a ~44px label column on the left, then a
# row of props on a dark grid. This crops each cell, floods the grid background
# out to transparency from the borders (so a dark prop is kept while the grid
# around it goes clear), trims to the prop, and writes a pixel-art .import beside
# each PNG so Godot imports them unfiltered.
#
# Characters are NOT baked here - they stay procedural until the character art
# pass. Chests and boxes are kept in SEPARATE folders on purpose: a chest is a
# lootable container, a box is a crate, and they must never be swapped.
import hashlib
import os
from collections import deque

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PACKS = os.path.join(ROOT, "assets", "art assets")
OUT = os.path.join(ROOT, "assets", "props")

# pack file, label-column width, cell count, cell height, [cells], out folder,
# name, TARGET HEIGHT. The packs are drawn at ~70-130px; the game's people are
# 29px tall, so each prop is shrunk to a target height authored for that scale -
# a crate below Nestor's shoulder, a boulder about his height, a tree over him.
# Shrinking here (not scaling the node) keeps the pixels crisp at 1:1.
JOBS = [
    ("Nature and terrain/Tree pack 01.png", 44, 8, 134, range(8), "trees", "tree", 50),
    ("Nature and terrain/rocks pack 01.png", 44, 8, 93, range(8), "rocks", "rock", 24),
    ("Objects/Box and chest pack 01.png", 44, 8, 85, [0, 1, 2, 3, 4], "boxes", "box", 20),
    ("Objects/Box and chest pack 01.png", 44, 8, 85, [5, 6, 7], "chests", "chest", 19),
]


def key_background(im):
    """Flood transparency in from the borders, matching the corner colour, so the
    grid background is removed but a dark prop in the middle is kept."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = px[0, 0]

    def close(c, tol=34):
        return abs(c[0] - bg[0]) <= tol and abs(c[1] - bg[1]) <= tol and abs(c[2] - bg[2]) <= tol

    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        if not close(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return im


def import_text(res_path):
    uid = "uid://c" + hashlib.sha1(res_path.encode()).hexdigest()[:12]
    base = os.path.basename(res_path)
    h = hashlib.md5(res_path.encode()).hexdigest()
    return (
        "[remap]\n\n"
        'importer="texture"\n'
        'type="CompressedTexture2D"\n'
        'uid="%s"\n'
        'path="res://.godot/imported/%s-%s.ctex"\n'
        "metadata={\n\"vram_texture\": false\n}\n\n"
        "[deps]\n\n"
        'source_file="%s"\n'
        'dest_files=["res://.godot/imported/%s-%s.ctex"]\n\n'
        "[params]\n\n"
        "compress/mode=0\ncompress/high_quality=false\ncompress/lossy_quality=0.7\n"
        "compress/hdr_compression=1\ncompress/normal_map=0\ncompress/channel_pack=0\n"
        "mipmaps/generate=false\nmipmaps/limit=-1\nroughness/mode=0\nroughness/src_normal=\"\"\n"
        "process/fix_alpha_border=true\nprocess/premult_alpha=false\n"
        "process/normal_map_invert_y=false\nprocess/hdr_as_srgb=false\n"
        "process/hdr_clamp_exposure=false\nprocess/size_limit=0\ndetect_3d/compress_to=0\n"
        % (uid, base, h, res_path, base, h))


def main():
    for pack, x0, n, h, cells, folder, name, target_h in JOBS:
        src = os.path.join(PACKS, pack)
        if not os.path.exists(src):
            print("skip (missing):", pack)
            continue
        im = Image.open(src).convert("RGBA")
        cell_w = (im.size[0] - x0) / n
        out_dir = os.path.join(OUT, folder)
        os.makedirs(out_dir, exist_ok=True)
        for idx, i in enumerate(cells):
            cell = im.crop((int(x0 + i * cell_w), 0, int(x0 + (i + 1) * cell_w), h))
            keyed = key_background(cell)
            bb = keyed.getbbox()
            if bb:
                keyed = keyed.crop(bb)
            # shrink to the target height for the game's scale, keeping aspect
            if keyed.size[1] > target_h:
                scale = target_h / keyed.size[1]
                keyed = keyed.resize(
                    (max(1, round(keyed.size[0] * scale)), target_h), Image.LANCZOS)
            png = os.path.join(out_dir, "%s_%d.png" % (name, idx + 1))
            keyed.save(png)
            res = "res://assets/props/%s/%s_%d.png" % (folder, name, idx + 1)
            with open(png + ".import", "w", encoding="utf-8", newline="\n") as f:
                f.write(import_text(res))
            print("baked", os.path.relpath(png, ROOT), "%dx%d" % keyed.size)
    print("done")


if __name__ == "__main__":
    main()
