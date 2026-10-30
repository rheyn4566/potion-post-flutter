"""Present host-rendered tablet screens; no painted mockup UI."""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
args = parser.parse_args()
canvas = Image.new('RGB', (1400, 750), '#103C39')
draw = ImageDraw.Draw(canvas)
font = lambda size: ImageFont.truetype(str(root/'assets/fonts/Poppins-SemiBold.ttf'),size)
regular = lambda size: ImageFont.truetype(str(root/'assets/fonts/Poppins-Regular.ttf'),size)
icon = Image.open(root/'store/potion-post-play-icon-512.png').convert('RGB').resize((80,80),Image.Resampling.LANCZOS)
canvas.paste(icon,(30,22))
draw.text((128,20),'Potion Post',font=font(32),fill='#FFF5DB')
draw.text((130,67),'v0.11.0 · Bigger levels, new settings and delivery celebration',font=regular(17),fill='#B8DDCA')
for index,(title,name) in enumerate([
    ('Home · Level / Play','HOME'),
    ('Larger level map','LEVELS'),
    ('Functional settings','SETTINGS'),
    ('Delivery celebration','DELIVERY'),
]):
    x = 30 + index*340
    draw.text((x,123),title,font=font(16),fill='#FFF1CC')
    screenshot = Image.open(root/f'docs/RELEASE_TABLET_{name}.png').convert('RGB')
    screenshot = screenshot.resize((320,512),Image.Resampling.LANCZOS)
    canvas.paste(screenshot,(x,157))
draw.text((30,698),'Tablet layouts rendered from the implemented app. Ads use SDK content at runtime.',font=regular(15),fill='#B8DDCA')
args.output.parent.mkdir(parents=True,exist_ok=True)
canvas.save(args.output,optimize=True)
print(args.output)
