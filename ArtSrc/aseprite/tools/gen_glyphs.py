"""Regenerate the CJK glyph block inside the main-battle-ui-draft-v*.lua scripts.

Aseprite's Lua API cannot draw text, so every non-ASCII character that appears
in a string literal of the draft script is rasterised here (WenQuanYi Micro Hei,
no antialiasing) and written back between the BEGIN/END GLYPHS markers.

Usage (any Python with Pillow):
    python ArtSrc/aseprite/tools/gen_glyphs.py            # every draft script
    python ArtSrc/aseprite/tools/gen_glyphs.py path.lua   # just this one
"""

import glob
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = sorted(glob.glob(os.path.join(HERE, "..", "main-battle-ui-draft-v*.lua")))
FONT = "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc"
SIZES = (12, 16)
BEGIN, END = "-- BEGIN GLYPHS", "-- END GLYPHS"

# Dense glyphs that collapse into blobs when thresholded at small sizes.
OVERRIDES = {
    (12, "量"): [
        "..########..",
        "..#......#..",
        "..########..",
        "..#......#..",
        "..########..",
        "############",
        "..########..",
        "..#..##..#..",
        "..########..",
        ".....##.....",
        ".##########.",
    ],
}


def used_chars(src: str) -> list[str]:
    body = src.split(BEGIN)[0] + src.split(END)[-1]
    chars = set()
    for lit in re.findall(r'"([^"\n]*)"', body):
        chars.update(ch for ch in lit if ord(ch) > 0x7F)
    return sorted(chars)


def rasterise(chars: list[str], size: int) -> tuple[int, dict]:
    font = ImageFont.truetype(FONT, size)
    pad = size
    bitmaps = {}
    top, bottom = 10**9, -1
    for ch in chars:
        im = Image.new("L", (size * 2 + pad, size * 2 + pad), 0)
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((0, pad // 2), ch, font=font, fill=255)
        bbox = im.getbbox()
        if bbox:
            top, bottom = min(top, bbox[1]), max(bottom, bbox[3])
        bitmaps[ch] = (im, round(font.getlength(ch)))
    h = bottom - top
    out = {}
    for ch, (im, adv) in bitmaps.items():
        rows = []
        for y in range(top, bottom):
            rows.append("".join("#" if im.getpixel((x, y)) > 127 else "." for x in range(adv)))
        fixed = OVERRIDES.get((size, ch))
        if fixed:
            rows = (fixed + ["." * adv] * h)[:h]
        out[ch] = (adv, rows)
    return h, out


def lua_block(chars: list[str]) -> str:
    lines = [BEGIN, "local GLYPHS = {"]
    for size in SIZES:
        h, glyphs = rasterise(chars, size)
        lines.append(f"  [{size}] = {{ h = {h},")
        for ch in chars:
            adv, rows = glyphs[ch]
            body = ",".join(f'"{r}"' for r in rows)
            lines.append(f"    [0x{ord(ch):04X}] = {{ w = {adv}, {body} }}, -- {ch}")
        lines.append("  },")
    lines.append("}")
    lines.append(END)
    return "\n".join(lines)


def regen(script: str) -> bool:
    with open(script, encoding="utf-8") as fh:
        src = fh.read()
    if BEGIN not in src or END not in src:
        print(f"glyph markers missing in {script}", file=sys.stderr)
        return False
    chars = used_chars(src)
    head = src.split(BEGIN)[0]
    tail = src.split(END)[-1]
    with open(script, "w", encoding="utf-8") as fh:
        fh.write(head + lua_block(chars) + tail)
    print(f"{len(chars)} glyphs x {len(SIZES)} sizes -> {os.path.relpath(script)}")
    return True


def main() -> int:
    scripts = sys.argv[1:] or SCRIPTS
    return 0 if all([regen(s) for s in scripts]) else 1


if __name__ == "__main__":
    sys.exit(main())
