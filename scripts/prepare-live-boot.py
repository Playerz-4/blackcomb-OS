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
    # Require all initrd entries to have the expected Fedora live layout.
    # Keep troubleshooting entries on the original initrd, so they remain an
    # independent recovery path if the branded splash overlay causes a problem.
    initrd_line = r'^([ \t]*initrd(?:efi)?[ \t]+\([^\n]*\)/boot/x86_64/loader/initrd)[ \t]*$'
    initrds = len(re.findall(initrd_line, text, re.M))
    if initrds < 1 or len(re.findall(r'^[ \t]*initrd(?:efi)?[ \t]', text, re.M)) != initrds:
        fail('unexpected Fedora live initrd entries')
    overlay = ' ($root)/blackcomb-boot/plymouth.cpio'
    # Fedora's live image may not request a graphical Plymouth splash. Enable
    # it for the normal entry, leaving troubleshooting entries as supplied.
    normal_pattern = (r'(^menuentry\s+["\']Start Fedora[^"\']*["\'][^\n]*\{\n)'
                      r'((?:[^\n]*\n)*?)(^}[ \t]*$)')
    def enable_splash(match):
        body, count = re.subn(
            r'^([ \t]*linux(?:efi)?[ \t]+[^\n]*)$',
            lambda line: line.group(1) if re.search(r'\b(?:rhgb|splash)\b', line.group(1))
            else line.group(1) + ' rhgb', match.group(2), flags=re.M)
        if count != 1:
            fail('unexpected normal kernel entry')
        # Append the theme only to the normal boot. GRUB loads the uncompressed
        # archive after Fedora's original initrd; troubleshooting stays untouched.
        body, count = re.subn(initrd_line, lambda m: m.group(1) + overlay, body, flags=re.M)
        if count != 1:
            fail('unexpected normal initrd entry')
        header = re.sub(r'^(menuentry\s+)["\']Start Fedora[^"\']*["\']',
                        r'\1"Boot Blackcomb"', match.group(1), count=1)
        return header + body + match.group(3)
    text, normal = re.subn(normal_pattern, enable_splash, text, flags=re.M)
    if normal != 1:
        fail('expected one normal Fedora start entry')
    text, defaults = re.subn(r'^([ \t]*set[ \t]+default[ \t]*=[ \t]*)["\']?\d+["\']?[ \t]*$', r'\g<1>"0"', text, flags=re.M)
    if defaults != 1:
        fail('expected one numeric default entry')
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
