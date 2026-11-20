#!/usr/bin/env python3
"""Verify the generated OpenCode-derived Plasma color schemes."""
import importlib.util
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location(
    'generate_opencode_themes', root / 'scripts/generate-opencode-themes.py')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

outputs = mod.build()
assert len(outputs) >= 60, f'only {len(outputs)} themes generated'
assert 'OpenCode-Catppuccin.colors' in outputs
assert 'OpenCode-Catppuccin-Light.colors' in outputs
assert 'OpenCode-Dracula.colors' in outputs
assert 'OpenCode-Nord.colors' in outputs
assert 'OpenCode-Tokyonight.colors' in outputs

required_sections = (
    '[General]', '[KDE]', '[WM]', '[Colors]', '[ColorEffects:Disabled]',
    '[ColorEffects:Inactive]', '[Colors:Button]', '[Colors:Complementary]',
    '[Colors:Selection]', '[Colors:Tooltip]', '[Colors:View]', '[Colors:Window]',
)
color_line = re.compile(r'^([A-Za-z:]+)=(\d{1,3}),(\d{1,3}),(\d{1,3})$')
scheme_ids = set()
for filename, expected in sorted(outputs.items()):
    path = root / 'themes/opencode' / filename
    assert path.is_file(), f'missing generated theme: {filename}'
    assert path.read_text(encoding='utf-8') == expected, f'stale theme: {filename}'
    for section in required_sections:
        assert f'{section}\n' in expected, f'{filename} is missing {section}'
    assert f'ColorScheme={path.stem}\n' in expected
    assert path.stem not in scheme_ids, f'duplicate scheme id: {path.stem}'
    scheme_ids.add(path.stem)
    for line in expected.splitlines():
        if color_line.match(line):
            assert all(0 <= int(part) <= 255 for part in color_line.match(line).groups()[1:])

catppuccin = outputs['OpenCode-Catppuccin.colors']
assert 'Name=OpenCode Catppuccin\n' in catppuccin
assert 'ColorScheme=OpenCode-Catppuccin\n' in catppuccin
assert 'ForegroundNormal=205,214,244\n' in catppuccin
print(f'OpenCode Plasma theme tests passed ({len(outputs)} schemes).')
