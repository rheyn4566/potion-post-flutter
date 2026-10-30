"""Export the generated master into platform sizes without altering the artwork."""
from pathlib import Path
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
master = Image.open(root / 'assets/potion-post-icon.png').convert('RGBA')
master = master.resize((1024, 1024), Image.Resampling.LANCZOS)
master.save(root / 'assets/potion-post-icon.png', optimize=True)
master.resize((256, 256), Image.Resampling.LANCZOS).convert('RGB').save(root / 'assets/icons/app-brand.webp', quality=88, method=6)
store = root / 'store';store.mkdir(exist_ok=True)
master.resize((512, 512), Image.Resampling.LANCZOS).save(store / 'potion-post-play-icon-512.png', optimize=True)
res = root / 'android/app/src/main/res'
for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    dest = res / ('mipmap-' + density)
    dest.mkdir(exist_ok=True)
    master.resize((size,size),Image.Resampling.LANCZOS).save(dest/'ic_launcher.png',optimize=True)
dest = res / 'drawable-nodpi';dest.mkdir(exist_ok=True)
master.resize((432,432),Image.Resampling.LANCZOS).save(dest/'launcher_art.png',optimize=True)
ios = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((ios/'Contents.json').read_text())['images']:
    if 'filename' not in item:continue
    size = round(float(item['size'].split('x')[0])*float(item['scale'][:-1]))
    master.resize((size,size),Image.Resampling.LANCZOS).convert('RGB').save(ios/item['filename'],optimize=True)
assert (store/'potion-post-play-icon-512.png').stat().st_size < 1024 * 1024
print('Android, iOS and Play Store icon exports created')
