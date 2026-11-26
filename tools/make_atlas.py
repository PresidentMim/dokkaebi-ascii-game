import pathlib
from PIL import Image, ImageDraw, ImageFont
chars = [" ", ".", ":", "-", "=", "+", "*", "#", "%", "@"]
cell_w, cell_h = 16, 16
img = Image.new("RGB", (cell_w*len(chars), cell_h), (0,0,0))
d = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf", 14)
except Exception as e:
    font = ImageFont.load_default()
    print("fallback font", e)
for i, ch in enumerate(chars):
    if ch == " ":
        continue
    # center char in cell
    bbox = d.textbbox((0,0), ch, font=font)
    w = bbox[2]-bbox[0]; h = bbox[3]-bbox[1]
    x = i*cell_w + (cell_w-w)//2 - bbox[0]
    y = (cell_h-h)//2 - bbox[1]
    d.text((x, y), ch, font=font, fill=(255,255,255))
img.save(str(pathlib.Path(__file__).resolve().parent.parent / "assets" / "ascii_atlas.png"))
print("saved", img.size, chars)
# verify pixels: check non-black pixels per cell
import collections
for i,ch in enumerate(chars):
    crop = img.crop((i*cell_w,0,(i+1)*cell_w,cell_h))
    px = list(crop.getdata())
    bright = sum(1 for p in px if p[0]>50)
    print(i, repr(ch), "bright_px", bright)
