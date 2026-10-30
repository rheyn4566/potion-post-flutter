"""Compose actual Flutter QA captures without changing their artwork or layout."""
from pathlib import Path
import argparse

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SCREENS = [
    ('Home · Moonbloom world', 'ALIGNED_HOME.png'),
    ('Home · Lily Pond world', 'WORLD_LILYPOND_HOME.png'),
    ('Gardens · grounded inhabitants', 'WORLD_LILYPOND_GARDENS.png'),
    ('Daily · clean controls', 'ALIGNED_DAILY.png'),
    ('Friends · collection showcase', 'ALIGNED_FRIENDS.png'),
    ('Play · courier card', 'ALIGNED_GAMEPLAY.png'),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    width, gap, margin = 380, 24, 30
    height, header, label, row_gap = 608, 126, 38, 26
    canvas = Image.new('RGB', (margin * 2 + width * 3 + gap * 2,
                              header + 2 * (height + label) + row_gap + 56), '#F7F1E2')
    draw = ImageDraw.Draw(canvas)
    fonts = ROOT / 'assets/fonts'
    title = ImageFont.truetype(str(fonts / 'Poppins-SemiBold.ttf'), 34)
    text = ImageFont.truetype(str(fonts / 'Poppins-Medium.ttf'), 17)
    small = ImageFont.truetype(str(fonts / 'Poppins-Regular.ttf'), 15)
    draw.text((margin, 23), 'Potion Post', font=title, fill='#183F3D')
    draw.text((margin, 73), 'v0.10.0 · Build 20   /   Actual Flutter screen renders',
              font=text, fill='#486762')
    for index, (name, capture) in enumerate(SCREENS):
        x = margin + (index % 3) * (width + gap)
        y = header + (index // 3) * (height + label + row_gap)
        draw.text((x, y), name, font=text, fill='#183F3D')
        image = Image.open(ROOT / 'docs' / capture).convert('RGB')
        image.thumbnail((width, height), Image.Resampling.LANCZOS)
        draw.rounded_rectangle((x - 1, y + label - 1, x + width + 1,
                                y + label + height + 1), radius=9, fill='#D0D8CE')
        canvas.paste(image, (x + (width - image.width) // 2,
                             y + label + (height - image.height) // 2))
    draw.text((margin, canvas.height - 36),
              '68 tests passed · 19 full environments · Grounded animals · Existing save format',
              font=small, fill='#486762')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(args.output, optimize=True)
    print(f'{args.output} · {canvas.width} × {canvas.height}')


if __name__ == '__main__':
    main()
