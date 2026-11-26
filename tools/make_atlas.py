"""Regenerate assets/ascii_atlas.png — the ASCII character atlas.

The ramp was chosen by MEASUREMENT, not by tradition: the old ramp
" .:-=+*#%@" is NOT monotonic in DejaVu Sans Mono Bold — '-' had fewer
ink pixels than ':' and '%' fewer than '#', so brighter cells could map
to a sparser glyph and the ASCII look collapsed. This script renders
each candidate glyph, counts its bright pixels, and uses a 10-glyph ramp
whose ink coverage strictly increases. It asserts monotonicity and
prints the counts, so a bad font/size change fails loudly instead of
silently producing a broken atlas.

Atlas: 10 glyphs x 24 px cells = 240x24 px, DejaVu Sans Mono Bold 20pt
with a 1px stroke so the strokes stay thick when the shader samples the
atlas down to a 12px screen cell. Run: python tools/make_atlas.py
(needs Pillow: pip install pillow).
"""
import pathlib

from PIL import Image, ImageDraw, ImageFont

# Measured ink coverage (bright px / 576) at 24px cell, 20pt bold, stroke 1:
# ' ' 0, '.' 36, ':' 72, '+' 84, '*' 104, 'o' 126, '%' 163, '#' 184,
# 'M' 205, '@' 226 — strictly increasing, min gap 12 px.
CHARS = [" ", ".", ":", "+", "*", "o", "%", "#", "M", "@"]
CELL = 24
FONT_SIZE = 20
FONT_PATHS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
    "C:/Windows/Fonts/consola.ttf",  # Consolas Bold fallback on Windows
    "C:/Windows/Fonts/lucon.ttf",  # Lucida Console fallback on Windows
]


def _load_font() -> ImageFont.FreeTypeFont:
    for path in FONT_PATHS:
        try:
            return ImageFont.truetype(path, FONT_SIZE)
        except OSError:
            continue
    print("WARNING: no bold monospace font found, using PIL default")
    return ImageFont.load_default()


def main() -> None:
    img = Image.new("RGB", (CELL * len(CHARS), CELL), (0, 0, 0))
    d = ImageDraw.Draw(img)
    font = _load_font()
    for i, ch in enumerate(CHARS):
        if ch == " ":
            continue
        bbox = d.textbbox((0, 0), ch, font=font, stroke_width=1)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        x = i * CELL + (CELL - w) // 2 - bbox[0]
        y = (CELL - h) // 2 - bbox[1]
        d.text((x, y), ch, font=font, fill=(255, 255, 255),
               stroke_width=1, stroke_fill=(255, 255, 255))
    out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "ascii_atlas.png"
    img.save(str(out))
    print("saved", out, img.size, CHARS)
    counts = []
    for i, ch in enumerate(CHARS):
        crop = img.crop((i * CELL, 0, (i + 1) * CELL, CELL))
        bright = sum(1 for p in crop.getdata() if p[0] > 50)
        counts.append(bright)
        print(i, repr(ch), "bright_px", bright)
    assert all(b > a for a, b in zip(counts, counts[1:])), (
        "atlas ramp is not monotonic: %s" % (counts,))
    print("OK: ramp is strictly increasing")


if __name__ == "__main__":
    main()
