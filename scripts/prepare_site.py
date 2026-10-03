import pathlib
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[1]
for source,target in [('menu.png','menu.jpg'),('game0.png','gameplay.jpg')]+[(f'game{i}.png',f'game{i}.jpg') for i in [7,8,15,25]]:
    with Image.open(ROOT/'qa'/source) as image:
        image.convert('RGB').save(ROOT/'docs'/'assets'/target,quality=90,optimize=True)
print('SITE_IMAGES_READY')
