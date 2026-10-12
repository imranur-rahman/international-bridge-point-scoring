"""Makes the suit symbol font of IB Score.

Keeps only the four suit glyphs (U+2660 ♠, U+2663 ♣, U+2665 ♥, U+2666 ♦) of
Noto Sans Symbols 2, so that the web app downloads a few KB instead of about
0.5 MB.

Usage:
  pip install fonttools
  python3 tool/subset_font.py NotoSansSymbols2-Regular.ttf \
      assets/fonts/NotoSansSymbols2-Regular.ttf

Get the full font from
https://github.com/google/fonts/raw/main/ofl/notosanssymbols2/NotoSansSymbols2-Regular.ttf
(SIL Open Font License 1.1, see assets/fonts/OFL.txt).
"""

import sys

from fontTools import subset

SUITS = [0x2660, 0x2663, 0x2665, 0x2666]


def main(source: str, target: str) -> None:
    options = subset.Options()
    options.layout_features = []
    options.name_IDs = ['*']  # Keep the copyright and license names.
    options.notdef_outline = True
    font = subset.load_font(source, options)
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=SUITS)
    subsetter.subset(font)
    missing = [hex(c) for c in SUITS if c not in font.getBestCmap()]
    if missing:
        sys.exit(f'The font has no glyph for {missing}')
    subset.save_font(font, target, options)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
