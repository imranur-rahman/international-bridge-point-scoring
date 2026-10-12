"""Makes the small font files of IB Scoring.

Two modes:

1. Suit symbols: keeps only the four suit glyphs (U+2660 ♠, U+2663 ♣,
   U+2665 ♥, U+2666 ♦) of Noto Sans Symbols 2.

     python3 tool/subset_font.py suits NotoSansSymbols2-Regular.ttf \
         assets/fonts/NotoSansSymbols2-Regular.ttf

   Source: https://github.com/google/fonts/raw/main/ofl/notosanssymbols2/NotoSansSymbols2-Regular.ttf

2. Headings: makes static SemiBold (600) and Bold (700) files of the
   variable Montserrat font, with only Basic Latin, Latin-1, and the
   punctuation that the app uses.

     python3 tool/subset_font.py headings "Montserrat[wght].ttf" assets/fonts

   Source: https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat%5Bwght%5D.ttf

Both fonts use the SIL Open Font License 1.1 (see assets/fonts/).
Needs: pip install fonttools
"""

import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SUITS = [0x2660, 0x2663, 0x2665, 0x2666]

# Basic Latin, Latin-1, and: – — ’ “ ” • … − ×
LATIN = (
    list(range(0x20, 0x7F))
    + list(range(0xA0, 0x100))
    + [0x2013, 0x2014, 0x2019, 0x201C, 0x201D, 0x2022, 0x2026, 0x2212, 0xD7]
)


def _subset(font: TTFont, unicodes: list[int]) -> TTFont:
    options = subset.Options()
    options.layout_features = ['kern', 'liga']
    options.name_IDs = ['*']  # Keep the copyright and license names.
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)
    return font


def suits(source: str, target: str) -> None:
    font = _subset(TTFont(source), SUITS)
    missing = [hex(c) for c in SUITS if c not in font.getBestCmap()]
    if missing:
        sys.exit(f'The font has no glyph for {missing}')
    font.save(target)


def headings(source: str, target_dir: str) -> None:
    for weight, name in [(600, 'SemiBold'), (700, 'Bold')]:
        static = instancer.instantiateVariableFont(
            TTFont(source), {'wght': weight}
        )
        font = _subset(static, LATIN)
        path = os.path.join(target_dir, f'Montserrat-{name}.ttf')
        font.save(path)
        print(f'{os.path.getsize(path):7d}  {path}')


if __name__ == '__main__':
    if len(sys.argv) != 4 or sys.argv[1] not in ('suits', 'headings'):
        sys.exit(__doc__)
    {'suits': suits, 'headings': headings}[sys.argv[1]](sys.argv[2], sys.argv[3])
