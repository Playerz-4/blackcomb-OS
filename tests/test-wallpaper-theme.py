#!/usr/bin/env python3
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent

wallpaper_metadata = sorted((root / 'wallpapers').glob('*/metadata.json'))
assert len(wallpaper_metadata) == 10
backgrounds = {path.stem for path in (root / 'backgrounds').glob('*.png')}
for metadata in wallpaper_metadata:
    data = json.loads(metadata.read_text())
    package = metadata.parent.name
    assert data['KPlugin']['Id'] == package
    assert data['KPlugin']['Name']
    assert package in backgrounds

assert (root / 'scripts/patch-breeze-wallpaper.sh').is_file()
assert 'Image=kim-stargazer' in (root / 'scripts/patch-breeze-wallpaper.sh').read_text()
assert 'default_image=/usr/share/wallpapers/kim-stargazer' in (root / 'scripts/blackcomb-wallpaper.sh').read_text()
assert not (root / 'themes/mountain').exists()
assert not (root / 'scripts/mountain-lookandfeel.conf').exists()

print('Wallpaper package tests passed.')
