#!/usr/bin/env python3
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent

wallpaper_metadata = sorted((root / 'wallpapers').glob('*/metadata.json'))
assert len(wallpaper_metadata) == 7
backgrounds = {path.stem for path in (root / 'backgrounds').glob('*.png')}
for metadata in wallpaper_metadata:
    data = json.loads(metadata.read_text())
    package = metadata.parent.name
    assert data['KPlugin']['Id'] == package
    assert data['KPlugin']['Name']
    assert package in backgrounds

theme_metadata = json.loads((root / 'themes/mountain/metadata.json').read_text())
assert theme_metadata['KPackageStructure'] == 'Plasma/LookAndFeel'
assert theme_metadata['KPlugin']['Id'] == 'com.blackcomb.mountain.desktop'
assert theme_metadata['KPlugin']['Name'] == 'Mountain'

defaults = (root / 'themes/mountain/contents/defaults').read_text()
assert '[kdeglobals][KDE]\nwidgetStyle=Breeze' in defaults
assert '[kdeglobals][General]\nfontSmoothing=2' in defaults
assert '[plasmarc][Theme]\nname=default' in defaults
assert '[Wallpaper]\nImage=kim-stargazer' in defaults
assert 'ColorScheme' not in defaults
assert '[kwinrc][org.kde.kdecoration2]\nlibrary=org.kde.breeze' in defaults

print('Wallpaper packages and Mountain theme tests passed.')
