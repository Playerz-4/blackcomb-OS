#!/usr/bin/env python3
"""Generate KDE Plasma color schemes from the bundled OpenCode themes.

The source JSON files are the official OpenCode built-in TUI themes. OpenCode
palettes are semantic colors rather than Plasma color schemes, so this script
maps the useful roles (background, panel, text, accent, status colors) onto a
complete Plasma ``.colors`` file. Generated files are committed so the ISO
build never needs network access.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / 'themes/opencode/source'
OUTPUT_DIR = ROOT / 'themes/opencode'
UPSTREAM_SHA = '85951cb08614dfe6443905552cae49d59d2d6615'

SPECIAL_NAMES = {
    'catppuccin': 'Catppuccin',
    'one-dark': 'One Dark',
    'opencode': 'Default',
    'rosepine': 'Rose Pine',
    'synthwave84': 'Synthwave84',
    'tokyonight': 'TokyoNight',
}

PALETTE_KEYS = (
    'primary', 'secondary', 'accent', 'error', 'warning', 'success', 'info',
    'text', 'textMuted', 'background', 'backgroundPanel', 'backgroundElement',
    'border', 'markdownLink', 'markdownLinkText',
)

TRANSPARENT_FALLBACKS = {
    'background': ('darkPanelBg', 'lightPanelBg', 'darkBg', 'lightBg', 'darkStep1', 'lightStep1'),
    'backgroundPanel': ('darkPanelBg', 'lightPanelBg', 'darkBgPanel', 'lightBgPanel', 'darkStep2', 'lightStep2'),
    'backgroundElement': ('darkStep6', 'lightStep6', 'darkPanelBg', 'lightPanelBg', 'darkStep3', 'lightStep3'),
}


def display_name(stem):
    if stem in SPECIAL_NAMES:
        return SPECIAL_NAMES[stem]
    return ' '.join(part.capitalize() for part in stem.split('-'))


def slug(stem):
    return 'OpenCode-' + '-'.join(part.capitalize() for part in stem.split('-'))


def resolve(value, data, mode, seen=()):
    """Resolve an OpenCode def/theme reference to a raw color string."""
    theme = data.get('theme', {})
    defs = data.get('defs', {})
    if isinstance(value, dict):
        if mode in value:
            value = value[mode]
        elif 'dark' in value:
            value = value['dark']
        else:
            return None
    if not isinstance(value, str):
        return None
    if value.startswith('#') or value == 'transparent':
        return value
    if value in seen:
        return None
    if value in defs:
        return resolve(defs[value], data, mode, seen + (value,))
    if value in theme:
        return resolve(theme[value], data, mode, seen + (value,))
    return None


def fallback_transparent(key, data, mode):
    for name in TRANSPARENT_FALLBACKS.get(key, ()):
        if name in data.get('defs', {}):
            value = resolve(data['defs'][name], data, mode, (name,))
            if value and value != 'transparent':
                return value
    return '#000000' if mode == 'dark' else '#ffffff'


def rgb(raw, mode):
    """Return an opaque RGB tuple, compositing alpha over a neutral backdrop."""
    value = raw
    if not isinstance(value, str) or not value.startswith('#'):
        value = '#000000' if mode == 'dark' else '#ffffff'
    digits = value[1:]
    if len(digits) in (3, 4):
        digits = ''.join(ch * 2 for ch in digits)
    if len(digits) not in (6, 8):
        digits = '000000' if mode == 'dark' else 'ffffff'
    red, green, blue = (int(digits[i:i + 2], 16) for i in (0, 2, 4))
    if len(digits) == 8:
        alpha = int(digits[6:8], 16) / 255
        base = (0, 0, 0) if mode == 'dark' else (255, 255, 255)
        red, green, blue = (
            round(red * alpha + base[0] * (1 - alpha)),
            round(green * alpha + base[1] * (1 - alpha)),
            round(blue * alpha + base[2] * (1 - alpha)),
        )
    return red, green, blue


def triplet(color):
    return ','.join(str(part) for part in color)


def contrasting_text(background):
    """Pick readable selection text for a solid accent background."""
    red, green, blue = (channel / 255 for channel in background)
    linear = []
    for channel in (red, green, blue):
        linear.append(channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4)
    luminance = 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    return (0, 0, 0) if luminance > 0.42 else (255, 255, 255)


def palette(data, mode):
    result = {}
    for key in PALETTE_KEYS:
        if key not in data.get('theme', {}):
            raise SystemExit(f'OpenCode theme is missing required key: {key}')
        raw = resolve(data['theme'][key], data, mode)
        if raw is None or raw == 'transparent':
            raw = fallback_transparent(key, data, mode)
        result[key] = rgb(raw, mode)
    return result


def scheme_text(p, name, scheme_id, source_file):
    selection_fg = contrasting_text(p['primary'])
    wm_inactive = p['backgroundElement']

    def line(key, color):
        return f'{key}={triplet(color)}'

    def role_group(title, background, alternate, foreground):
        return '\n'.join([
            f'[{title}]',
            line('BackgroundAlternate', alternate),
            line('BackgroundNormal', background),
            line('DecorationFocus', p['primary']),
            line('DecorationHover', p['accent']),
            line('ForegroundActive', p['accent']),
            line('ForegroundInactive', p['textMuted']),
            line('ForegroundLink', p['markdownLink']),
            line('ForegroundNegative', p['error']),
            line('ForegroundNeutral', p['warning']),
            line('ForegroundNormal', foreground),
            line('ForegroundPositive', p['success']),
            line('ForegroundVisited', p['markdownLinkText']),
            '',
        ])

    groups = [
        '[ColorEffects:Disabled]',
        'Color=127,127,127',
        'ColorAmount=0.6',
        'ColorEffect=0',
        'ContrastAmount=0.65',
        'ContrastEffect=0',
        'IntensityAmount=0.25',
        'IntensityEffect=0',
        '',
        '[ColorEffects:Inactive]',
        'ChangeSelectionColor=true',
        'Color=127,127,127',
        'ColorAmount=0.1',
        'ColorEffect=2',
        'ContrastAmount=0.1',
        'ContrastEffect=2',
        'Enable=false',
        'IntensityAmount=0',
        'IntensityEffect=0',
        '',
        role_group('Colors', p['background'], p['backgroundPanel'], p['text']),
        role_group('Colors:Button', p['backgroundPanel'], p['backgroundElement'], p['text']),
        role_group('Colors:Complementary', p['backgroundElement'], p['backgroundPanel'], p['text']),
        '\n'.join([
            '[Colors:Selection]',
            line('BackgroundAlternate', p['secondary']),
            line('BackgroundNormal', p['primary']),
            line('DecorationFocus', p['primary']),
            line('DecorationHover', p['accent']),
            line('ForegroundActive', selection_fg),
            line('ForegroundInactive', p['text']),
            line('ForegroundLink', p['markdownLinkText']),
            line('ForegroundNegative', p['error']),
            line('ForegroundNeutral', p['warning']),
            line('ForegroundNormal', selection_fg),
            line('ForegroundPositive', p['success']),
            line('ForegroundVisited', p['markdownLink']),
            '',
        ]),
        role_group('Colors:Tooltip', p['backgroundElement'], p['backgroundPanel'], p['text']),
        role_group('Colors:View', p['background'], p['backgroundPanel'], p['text']),
        role_group('Colors:Window', p['backgroundPanel'], p['backgroundElement'], p['text']),
        '\n'.join([
            '[General]',
            f'ColorScheme={scheme_id}',
            f'Name={name}',
            'shadeSortColumn=true',
            '',
        ]),
        '[KDE]',
        'contrast=4',
        '',
        '\n'.join([
            '[WM]',
            line('activeBackground', p['backgroundPanel']),
            'activeBlend=255,255,255',
            line('activeForeground', p['text']),
            line('inactiveBackground', wm_inactive),
            'inactiveBlend=123,126,127',
            line('inactiveForeground', p['textMuted']),
            '',
        ]),
    ]
    header = (
        f'# Generated from the OpenCode {source_file} theme.\n'
        f'# Source: https://github.com/anomalyco/opencode/blob/{UPSTREAM_SHA}/'
        f'packages/tui/src/theme/assets/{source_file}.json\n'
        '# Regenerate with scripts/generate-opencode-themes.py.\n'
    )
    return header + '\n'.join(groups)


def build():
    if not SOURCE_DIR.is_dir():
        raise SystemExit(f'Missing source directory: {SOURCE_DIR}')
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs = {}
    for path in sorted(SOURCE_DIR.glob('*.json')):
        data = json.loads(path.read_text(encoding='utf-8'))
        stem = path.stem
        dark = palette(data, 'dark')
        light = palette(data, 'light')
        label = display_name(stem)
        base = slug(stem)
        outputs[f'{base}.colors'] = scheme_text(
            dark, f'OpenCode {label}', base, stem)
        if any(dark[key] != light[key] for key in ('background', 'backgroundPanel', 'text', 'primary', 'accent')):
            light_id = f'{base}-Light'
            outputs[f'{light_id}.colors'] = scheme_text(
                light, f'OpenCode {label} Light', light_id, stem)
    return outputs


def main():
    check = '--check' in sys.argv[1:]
    outputs = build()
    if check:
        for filename, content in sorted(outputs.items()):
            path = OUTPUT_DIR / filename
            if not path.is_file() or path.read_text(encoding='utf-8') != content:
                raise SystemExit(f'Generated theme is stale: {filename}')
        print(f'Checked {len(outputs)} OpenCode Plasma themes.')
        return
    for filename, content in sorted(outputs.items()):
        (OUTPUT_DIR / filename).write_text(content, encoding='utf-8')
    print(f'Generated {len(outputs)} OpenCode Plasma themes.')


if __name__ == '__main__':
    main()
