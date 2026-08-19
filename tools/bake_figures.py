# Bake the procedural characters into Godot sprite sheets.
#
# In the HTML game the art IS code: drawFigure() paints a body from parameters,
# there is no protagonist.png anywhere. Godot needs real textures, so this drives
# the same drawFigure through a headless browser and captures the pixels.
#
# What makes this different from the HTML project's spriteatlas.py: there, each
# sprite is tight-cropped to its own bounding box. That is wrong for animation -
# if frame 2 of a walk is one pixel taller than frame 1, the feet slide. Here
# every frame is rendered into a FIXED cell, anchored at the same bottom-centre
# point, so the character stays planted while its legs move.
#
# Output per character:
#   assets/sprites/characters/<name>.png        one packed sheet
#   assets/sprites/characters/<name>.png.import Godot import settings (pixel art)
#   assets/sprites/characters/<name>.tres       a SpriteFrames, ready to drop on
#                                               an AnimatedSprite2D
import hashlib
import io
import json
import os
import subprocess

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT_ROOT = os.path.dirname(HERE)
HTML_GAME = os.path.join(
    os.path.expanduser("~"),
    "OneDrive", "\u00c1rea de Trabalho", "Hollowmere works", "hollowmere.html")

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if not os.path.exists(CHROME):
    CHROME = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

CANVAS_W, CANVAS_H = 576, 360
# One cell per frame. Generous enough for the tallest pose (arms up mid-swing)
# with a margin, so nothing is clipped by the cell edge.
CELL_W, CELL_H = 40, 44
# The figure's feet sit this far up from the cell bottom, leaving room for the
# drop shadow drawFigure paints under the body.
FOOT_MARGIN = 6

# game direction index -> Godot facing name. 0 front/down, 1 back/up, 2 L, 3 R.
DIRS = [(0, "down"), (1, "up"), (2, "left"), (3, "right")]
WALK_PHASES = [0.0, 1.5707963, 3.1415926, 4.712389]

# Each character: a name, the palette expression evaluated inside the game, and
# the drawFigure options object. The lamp/torch light is NOT baked - in Godot
# that glow is a real PointLight2D on the player, so the body holds an unlit lamp.
CHARACTERS = [
    ("nestor",      "PAL_P",       {"eyes": True}),
    ("villager_1",  "NPC_PALS[0]", {"eyes": True}),
    ("villager_2",  "NPC_PALS[1]", {"eyes": True}),
    ("villager_3",  "NPC_PALS[2]", {"eyes": True}),
    ("yotan_guard", "GUARD_PAL",   {"eyes": True}),
]


def frames_for(char):
    """The ordered frame list for one character: idle then walk, per direction."""
    name, pal, opts = char
    frames = []
    for d, dn in DIRS:
        frames.append(dict(pal=pal, opts=opts, dir=d, phase=0.0, moving=False))
    for d, dn in DIRS:
        for ph in WALK_PHASES:
            frames.append(dict(pal=pal, opts=opts, dir=d, phase=ph, moving=True))
    return frames


ANIMS_ORDER = ([("idle_%s" % dn, 1) for _, dn in DIRS]
               + [("walk_%s" % dn, 4) for _, dn in DIRS])


def build_js(frames, bg):
    cols = CANVAS_W // CELL_W
    tpl = """
(function(){
  var realRAF=window.requestAnimationFrame.bind(window);
  var pending=[];
  window.requestAnimationFrame=function(f){pending.push(f);return 1;};
  window.cancelAnimationFrame=function(){};
  ['HINTS','INV','JOURNAL','SKILLPANE','SHOP','SCROLL','DLG'].forEach(function(n){
    try{ var o=eval(n); if(o&&typeof o==='object'&&'open' in o) o.open=false; }catch(e){}
  });
  var F=__FRAMES__, CW=__CW__, CH=__CH__, COLS=__COLS__, FM=__FM__;
  var c=document.querySelector('canvas'), g=c.getContext('2d');
  realRAF(function(){ realRAF(render); });
  function render(){
    try{ cam.x=0; cam.y=0; }catch(e){}
    g.setTransform(1,0,0,1,0,0); g.globalAlpha=1;
    g.clearRect(0,0,__W__,__H__);
    g.fillStyle='__BG__'; g.fillRect(0,0,__W__,__H__);
    for(var i=0;i<F.length;i++){
      var s=F[i], cx=(i%COLS)*CW, cy=Math.floor(i/COLS)*CH;
      var mx=cx+CW/2, my=cy+CH-FM;
      try{ drawFigure(mx, my, s.dir, s.phase, s.moving, eval(s.pal), s.opts); }
      catch(err){ }
    }
    c.remove();
    Array.prototype.slice.call(document.body.children).forEach(function(el){
      if(el.tagName!=='SCRIPT') el.remove(); });
    document.body.appendChild(c);
    document.documentElement.style.cssText='margin:0;padding:0;background:transparent';
    document.body.style.cssText='margin:0;padding:0;background:transparent;overflow:hidden';
    c.style.cssText='display:block;margin:0;width:__W__px;height:__H__px;image-rendering:pixelated';
  }
})();
"""
    repl = {
        "__FRAMES__": json.dumps(frames),
        "__CW__": str(CELL_W), "__CH__": str(CELL_H),
        "__COLS__": str(cols), "__FM__": str(FOOT_MARGIN),
        "__W__": str(CANVAS_W), "__H__": str(CANVAS_H), "__BG__": bg,
    }
    for k, v in repl.items():
        tpl = tpl.replace(k, v)
    return tpl


def shoot(frames, bg, out_png):
    html = io.open(HTML_GAME, encoding="utf-8", newline="").read()
    html += "\n<script>\n" + build_js(frames, bg) + "\n</script>\n"
    tmp = os.path.join(HERE, ".bake.html")
    io.open(tmp, "w", encoding="utf-8", newline="").write(html)
    url = "file:///" + tmp.replace("\\", "/").replace(" ", "%20")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--no-first-run", "--force-device-scale-factor=1",
                    "--user-data-dir=" + os.path.join(HERE, ".chrome-profile"),
                    "--window-size=%d,%d" % (CANVAS_W, CANVAS_H),
                    "--virtual-time-budget=15000", "--screenshot=" + out_png, url],
                   capture_output=True)
    os.remove(tmp)


def recover_alpha(black_png, white_png):
    """Two screenshots - one over black, one over white - solve for alpha.
    A fully opaque pixel reads identical on both; a transparent one reads as the
    background. The gap between them is the transparency."""
    b = Image.open(black_png).convert("RGB")
    w = Image.open(white_png).convert("RGB")
    out = Image.new("RGBA", b.size)
    pb, pw, po = b.load(), w.load(), out.load()
    for y in range(b.size[1]):
        for x in range(b.size[0]):
            rb, gb, bb = pb[x, y]
            rw, gw, bw = pw[x, y]
            a = 255 - ((rw - rb) + (gw - gb) + (bw - bb)) / 3.0
            a = max(0.0, min(255.0, a))
            if a < 1:
                po[x, y] = (0, 0, 0, 0)
                continue
            k = 255.0 / a
            po[x, y] = (min(255, int(rb * k + 0.5)), min(255, int(gb * k + 0.5)),
                        min(255, int(bb * k + 0.5)), int(a + 0.5))
    return out


def _hash(s):
    return hashlib.md5(s.encode()).hexdigest()


def import_file(res_path):
    """A .png.import with filtering and mipmaps OFF - the pixel-art preset."""
    uid = "uid://b" + hashlib.sha1(res_path.encode()).hexdigest()[:10]
    base = os.path.basename(res_path)
    h = _hash(res_path)
    text = (
        "[remap]\n\n"
        'importer="texture"\n'
        'type="CompressedTexture2D"\n'
        'uid="%s"\n'
        'path="res://.godot/imported/%s-%s.ctex"\n'
        "metadata={\n"
        '"vram_texture": false\n'
        "}\n\n"
        "[deps]\n\n"
        'source_file="%s"\n'
        'dest_files=["res://.godot/imported/%s-%s.ctex"]\n\n'
        "[params]\n\n"
        "compress/mode=0\n"
        "compress/high_quality=false\n"
        "compress/lossy_quality=0.7\n"
        "compress/hdr_compression=1\n"
        "compress/normal_map=0\n"
        "compress/channel_pack=0\n"
        "mipmaps/generate=false\n"
        "mipmaps/limit=-1\n"
        "roughness/mode=0\n"
        'roughness/src_normal=""\n'
        "process/fix_alpha_border=true\n"
        "process/premult_alpha=false\n"
        "process/normal_map_invert_y=false\n"
        "process/hdr_as_srgb=false\n"
        "process/hdr_clamp_exposure=false\n"
        "process/size_limit=0\n"
        "detect_3d/compress_to=0\n"
        % (uid, base, h, res_path, base, h))
    return uid, text


def sprite_frames_tres(sheet_res, sheet_uid, cols, anims_order, fps=8.0):
    """A SpriteFrames that carves the packed sheet into AtlasTexture regions."""
    total = sum(c for _, c in anims_order)
    lines = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (total + 2), ""]
    lines.append('[ext_resource type="Texture2D" uid="%s" path="%s" id="1_sheet"]'
                 % (sheet_uid, sheet_res))
    lines.append("")

    atlas_ids = []
    idx = 0
    for _, count in anims_order:
        for _ in range(count):
            col = idx % cols
            row = idx // cols
            x, y = col * CELL_W, row * CELL_H
            aid = "atlas_%d" % idx
            atlas_ids.append(aid)
            lines.append('[sub_resource type="AtlasTexture" id="%s"]' % aid)
            lines.append('atlas = ExtResource("1_sheet")')
            lines.append('region = Rect2(%d, %d, %d, %d)' % (x, y, CELL_W, CELL_H))
            lines.append("")
            idx += 1

    lines.append("[resource]")
    lines.append("animations = [")
    idx = 0
    for anim_name, count in anims_order:
        speed = fps if count > 1 else 5.0
        entries = []
        for _ in range(count):
            entries.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}'
                           % atlas_ids[idx])
            idx += 1
        lines.append("{")
        lines.append('"frames": [%s],' % ", ".join(entries))
        lines.append('"loop": true,')
        lines.append('"name": &"%s",' % anim_name)
        lines.append('"speed": %s' % speed)
        lines.append("},")
    lines.append("]")
    return "\n".join(lines) + "\n"


def main():
    if not os.path.exists(HTML_GAME):
        raise SystemExit("cannot find hollowmere.html at %s" % HTML_GAME)
    if not os.path.exists(CHROME):
        raise SystemExit("cannot find Chrome/Edge to render with")
    out_dir = os.path.join(GODOT_ROOT, "assets", "sprites", "characters")
    os.makedirs(out_dir, exist_ok=True)
    cols = CANVAS_W // CELL_W

    for char in CHARACTERS:
        name = char[0]
        frames = frames_for(char)

        black = os.path.join(HERE, ".bake_k.png")
        white = os.path.join(HERE, ".bake_w.png")
        shoot(frames, "#000000", black)
        shoot(frames, "#ffffff", white)
        sheet = recover_alpha(black, white)

        used_rows = (len(frames) + cols - 1) // cols
        sheet = sheet.crop((0, 0, cols * CELL_W, used_rows * CELL_H))

        png_path = os.path.join(out_dir, name + ".png")
        sheet.save(png_path)
        for f in (black, white):
            try:
                os.remove(f)
            except OSError:
                pass

        res_png = "res://assets/sprites/characters/%s.png" % name
        uid, imp = import_file(res_png)
        io.open(png_path + ".import", "w", encoding="utf-8", newline="\n").write(imp)

        tres = sprite_frames_tres(res_png, uid, cols, ANIMS_ORDER)
        io.open(os.path.join(out_dir, name + ".tres"), "w",
                encoding="utf-8", newline="\n").write(tres)

        print("baked %-14s %d frames -> %s.png (%dx%d)"
              % (name, len(frames), name, sheet.width, sheet.height))

    print("done")


if __name__ == "__main__":
    main()
