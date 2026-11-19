#!/usr/bin/env python3
"""Prepare the Fedora live GRUB menu and Plymouth files, without rebuilding initrd."""
import re
import sys
from pathlib import Path


def fail(message):
    raise SystemExit(f"Unsupported Fedora live GRUB config: {message}")


def patch_grub(text):
    # Only touch the known, simple Kiwi live-media entries. Fail instead of
    # guessing if a future Fedora release changes its menu layout.
    lines = text.splitlines(keepends=True)
    result = []
    removed = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.match(r'^\s*menuentry\s+["\']Test this media\b', line, re.I):
            entry = [line]
            i += 1
            while i < len(lines) and not re.fullmatch(r'\s*}\s*', lines[i]):
                entry.append(lines[i])
                i += 1
            if i == len(lines):
                fail('unclosed media-test entry')
            entry.append(lines[i])
            if 'rd.live.check' not in ''.join(entry) or not any(re.match(r'^\s*initrd(?:efi)?\s', x) for x in entry):
                fail('unexpected media-test entry')
            removed += 1
        else:
            result.append(line)
        i += 1
    if removed != 1:
        fail(f'expected exactly one media-test entry, found {removed}')
    text = ''.join(result)
    if 'rd.live.check' in text:
        fail('media check occurs outside the expected entry')
    # Do NOT add "rhgb" here. Fedora KDE 43+ has a known Plymouth-to-SDDM
    # handoff race when that argument is present: Plymouth starts inside the
    # initramfs, keeps the DRM device busy, and SDDM's greeter fails to open
    # /dev/dri/card* ("Device or resource busy"). The result is exactly a
    # working boot splash followed by a black desktop with nothing on it
    # (Red Hat bug 2404966, upstream sddm#1917). Removing "rhgb" is the
    # documented fix and still allows Plymouth to show later, from the real
    # root, once the graphics device is ready. Troubleshooting entries are
    # left as Fedora supplies them.
    normal_pattern = (r'(^menuentry\s+["\']Start Fedora[^"\']*["\'][^\n]*\{\n)'
                      r'((?:[^\n]*\n)*?)(^}[ \t]*$)')
    def safe_boot(match):
        def strip_rhgb(line):
            text = line.group(1)
            indent = re.match(r'^[ \t]*', text).group(0)
            args = re.sub(r'\brhgb\b', '', text[len(indent):])
            return indent + re.sub(r'[ \t]{2,}', ' ', args).strip()
        body, count = re.subn(
            r'^([ \t]*linux(?:efi)?[ \t]+[^\n]*)$',
            strip_rhgb, match.group(2), flags=re.M)
        if count != 1:
            fail('unexpected normal kernel entry')
        header = re.sub(r'^(menuentry\s+)["\']Start Fedora[^"\']*["\']',
                        r'\1"Boot Blackcomb"', match.group(1), count=1)
        return header + body + match.group(3)
    text, normal = re.subn(normal_pattern, safe_boot, text, flags=re.M)
    if normal != 1:
        fail('expected one normal Fedora start entry')
    text, defaults = re.subn(r'^([ \t]*set[ \t]+default[ \t]*=[ \t]*)["\']?\d+["\']?[ \t]*$', r'\g<1>"0"', text, flags=re.M)
    if defaults != 1:
        fail('expected one numeric default entry')
    overlay = ' ($root)/blackcomb-boot/plymouth.cpio'
    # GRUB loads the uncompressed newc archive after the original initrd,
    # so its theme and logo override the files in that initrd.
    pattern = r'^([ \t]*initrd(?:efi)?[ \t]+\([^\n]*\)/boot/x86_64/loader/initrd)[ \t]*$'
    text, initrds = re.subn(pattern, lambda m: m.group(1) + overlay, text, flags=re.M)
    if initrds < 1:
        fail('expected Fedora live initrd entries')
    if len(re.findall(r'^[ \t]*initrd(?:efi)?[ \t]', text, re.M)) != initrds:
        fail('unexpected initrd entry')

    # Retain Fedora's existing troubleshooting submenu, without adding a
    # second top-level basic-graphics entry.
    return text


def main():
    if len(sys.argv) != 4:
        raise SystemExit('Usage: prepare-live-boot.py ORIGINAL_GRUB OUTPUT_GRUB BOOT_DIR')
    original, output, boot_dir = map(Path, sys.argv[1:])
    patched = patch_grub(original.read_text())
    conf_dir = boot_dir / 'etc/plymouth'
    theme_dir = boot_dir / 'usr/share/plymouth/themes/blackcomb-live'
    spinner_dir = boot_dir / 'usr/share/plymouth/themes/spinner'
    for directory in (conf_dir, theme_dir, spinner_dir):
        directory.mkdir(parents=True, exist_ok=True)
    (conf_dir / 'plymouthd.conf').write_text('[Daemon]\nTheme=blackcomb-live\nShowDelay=0\n')
    (theme_dir / 'blackcomb-live.plymouth').write_text('''[Plymouth Theme]
Name=Blackcomb Live
Description=Blackcomb logo and Fedora spinner
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/spinner
HorizontalAlignment=.5
VerticalAlignment=.7
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.9
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
MessageBelowAnimation=true
''')
    output.write_text(patched)


if __name__ == '__main__':
    main()
