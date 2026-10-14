"""Draws the Thalam app icon: a turmeric dot inside a ring of 8 small dots on kumkum red.

Usage:  python3 tools/make_icon.py
Needs Pillow (pip install pillow). Writes the 1024x1024 PNG into both asset catalogs.
"""
import math
import os

from PIL import Image, ImageDraw

KUMKUM = (0xA3, 0x17, 0x1E)
TURMERIC = (0xE3, 0xA2, 0x1A)
TEMPLE_GOLD = (0xC0, 0x8A, 0x2B)
IVORY = (0xFB, 0xF3, 0xE4)

SIZE = 1024
SCALE = 4  # draw 4x bigger, then shrink, for smooth edges


def draw_icon() -> Image.Image:
    s = SIZE * SCALE
    img = Image.new("RGB", (s, s), KUMKUM)
    d = ImageDraw.Draw(img)
    c = s / 2

    def circle(cx, cy, r, fill=None, outline=None, width=0):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=outline, width=width)

    ring_r = 0.30 * s  # radius of the ring of beats

    # Thin temple-gold guide circle through the 8 beat dots.
    circle(c, c, ring_r, outline=TEMPLE_GOLD, width=int(0.006 * s))

    # 8 beats of Adi Talam, beat 1 (sam) at the top in turmeric.
    for i in range(8):
        a = i / 8 * 2 * math.pi - math.pi / 2
        x, y = c + ring_r * math.cos(a), c + ring_r * math.sin(a)
        r = 0.045 * s if i == 0 else 0.036 * s
        circle(x, y, r, fill=TURMERIC if i == 0 else IVORY)

    # The big turmeric dot in the middle, with a gold halo.
    circle(c, c, 0.165 * s, fill=TEMPLE_GOLD)
    circle(c, c, 0.150 * s, fill=TURMERIC)

    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    icon = draw_icon()
    for folder in ("iOS", "Watch"):
        out = os.path.join(root, folder, "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        icon.save(out, "PNG")  # RGB, no alpha: required for the App Store
        print("wrote", out)


if __name__ == "__main__":
    main()
