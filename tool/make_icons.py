"""Makes the IB Score app icon for web, Android, and iOS.

Draws a white spade above the letters "IB" on felt green, and writes each
icon size that the platforms need. The PNG files are committed, so builds do
not need this script.

Usage:
  pip install pillow
  python3 tool/make_icons.py Roboto.ttf

Roboto.ttf is the variable Roboto font from
https://github.com/google/fonts/raw/main/ofl/roboto/Roboto%5Bwdth,wght%5D.ttf
(SIL Open Font License 1.1). The spade comes from
assets/fonts/NotoSansSymbols2-Regular.ttf in this repository.
"""

import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FELT_GREEN = (0x1E, 0x6B, 0x45)
WHITE = (255, 255, 255)
MASTER = 1024
SPADE_FONT = os.path.join(ROOT, 'assets/fonts/NotoSansSymbols2-Regular.ttf')


def draw_master(text_font: str, *, rounded: bool, content_scale: float,
                transparent_corners: bool) -> Image.Image:
    """Draws the icon at 1024 px.

    rounded: draw rounded corners (web and Android). iOS and maskable icons
      are full squares, because the platform makes the shape.
    content_scale: the share of the icon that the spade and letters use.
    """
    mode = 'RGBA' if transparent_corners else 'RGB'
    background = (0, 0, 0, 0) if transparent_corners else FELT_GREEN
    image = Image.new(mode, (MASTER, MASTER), background)
    draw = ImageDraw.Draw(image)
    if rounded:
        draw.rounded_rectangle(
            [0, 0, MASTER - 1, MASTER - 1], radius=int(MASTER * 0.22),
            fill=FELT_GREEN)
    else:
        draw.rectangle([0, 0, MASTER - 1, MASTER - 1], fill=FELT_GREEN)

    box = MASTER * content_scale  # The square that holds the content.
    top = (MASTER - box) / 2

    spade = ImageFont.truetype(SPADE_FONT, int(box * 0.62))
    _center_text(draw, '♠', spade, top + box * 0.36)

    letters = ImageFont.truetype(text_font, int(box * 0.30))
    try:
        # Bold weight and normal width, by axis name, in the font's order.
        wanted = {b'Weight': 700, b'Width': 100}
        axes = letters.get_variation_axes()
        letters.set_variation_by_axes(
            [wanted.get(axis['name'], axis['default']) for axis in axes])
    except (OSError, ValueError):
        pass  # A static bold font has no variation axes.
    _center_text(draw, 'IB', letters, top + box * 0.82)
    return image


def _center_text(draw: ImageDraw.ImageDraw, text: str,
                 font: ImageFont.FreeTypeFont, center_y: float) -> None:
    left, upper, right, lower = draw.textbbox((0, 0), text, font=font)
    x = (MASTER - (right - left)) / 2 - left
    y = center_y - (lower - upper) / 2 - upper
    draw.text((x, y), text, font=font, fill=WHITE)


def save(image: Image.Image, size: int, path: str) -> None:
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    image.resize((size, size), Image.LANCZOS).save(full, optimize=True)
    print(f'{size:5d}  {path}')


def main(text_font: str) -> None:
    rounded = draw_master(text_font, rounded=True, content_scale=0.86,
                          transparent_corners=True)
    # Maskable icons: the platform can cut up to a circle of 80 % of the
    # width, so the content stays inside the inner 66 %.
    maskable = draw_master(text_font, rounded=False, content_scale=0.66,
                           transparent_corners=False)
    # iOS icons: a full square with no transparency; iOS makes the shape.
    ios = draw_master(text_font, rounded=False, content_scale=0.80,
                      transparent_corners=False)

    save(rounded, 32, 'web/favicon.png')
    save(rounded, 192, 'web/icons/Icon-192.png')
    save(rounded, 512, 'web/icons/Icon-512.png')
    save(maskable, 192, 'web/icons/Icon-maskable-192.png')
    save(maskable, 512, 'web/icons/Icon-maskable-512.png')

    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        save(rounded, size,
             f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')

    icon_set = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    with open(os.path.join(ROOT, icon_set, 'Contents.json')) as f:
        contents = json.load(f)
    done = set()
    for entry in contents['images']:
        name = entry.get('filename')
        if not name or name in done:
            continue
        points = float(entry['size'].split('x')[0])
        scale = int(entry['scale'].rstrip('x'))
        save(ios, round(points * scale), f'{icon_set}/{name}')
        done.add(name)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
