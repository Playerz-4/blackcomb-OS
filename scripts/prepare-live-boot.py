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
    # Keep "rhgb" so Plymouth displays the Blackcomb splash. The Plasma black
    # screen is a DRM handoff race (RHBZ 2404966): on Fedora 42+ Plymouth uses
    # the early EFI framebuffer (simpledrm) and can hold a /dev/dri/card device
    # while the real guest driver and SDDM try to claim it. Tell Plymouth to
    # wait for the real GPU driver instead - the documented way to keep the
    # splash without the early framebuffer owning a DRM card - and pin a
    # modest 1024x768 framebuffer so the desktop fits a VirtualBox window.
    # Hardware acceleration is NOT disabled: no nomodeset/basicgfx is added.
    # Troubleshooting entries are left as Fedora supplies them.
    normal_pattern = (r'(^menuentry\s+["\']Start Fedora[^"\']*["\'][^\n]*\{\n)'
                      r'((?:[^\n]*\n)*?)(^}[ \t]*$)')
    def splash_boot(match):
        def harden(line):
            text = line.group(1)
            indent = re.match(r'^[ \t]*', text).group(0)
            args = re.sub(r'[ \t]{2,}', ' ', text[len(indent):]).strip()
            for arg in ('rhgb', 'plymouth.use-simpledrm=0', 'video=1024x768'):
                if not re.search(r'(?<!\S)' + re.escape(arg) + r'(?!\S)', args):
                    args += ' ' + arg
            return indent + args
        body, count = re.subn(
            r'^([ \t]*linux(?:efi)?[ \t]+[^\n]*)$',
            harden, match.group(2), flags=re.M)
        if count != 1:
            fail('unexpected normal kernel entry')
        header = re.sub(r'^(menuentry\s+)["\']Start Fedora[^"\']*["\']',
                        r'\1"Boot Blackcomb"', match.group(1), count=1)
        return header + body + match.group(3)
    text, normal = re.subn(normal_pattern, splash_boot, text, flags=re.M)
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


def write_live_session_fixes(boot_dir):
    """Inject best-effort live-session fixes into the boot overlay.

    A unit in the initramfs runs just before switch-root and copies these
    files into the writable live-root overlay. That lets the live session
    answer the keyboard polkit prompt and fit a VirtualBox window without
    rebuilding Fedora's live filesystem.
    """
    scripts = Path(__file__).resolve().parent
    live = boot_dir / 'usr/share/blackcomb/live'
    live.mkdir(parents=True, exist_ok=True)
    for name in ('live-vm-display.sh', 'live-vm-display.desktop',
                 'live-keyboard.rules', 'live-setup.service'):
        (live / name).write_text((scripts / name).read_text())

    setup = boot_dir / 'usr/sbin/blackcomb-live-setup'
    setup.parent.mkdir(parents=True, exist_ok=True)
    setup.write_text('''#!/bin/sh
# Runs in the initramfs, before switch-root. /sysroot is the writable live
# root overlay; copy the Blackcomb session fixes into it.
set -eu
src=/usr/share/blackcomb/live
dst=/sysroot
[ -d "$dst/etc" ] || exit 0
mkdir -p "$dst/usr/local/bin" "$dst/etc/xdg/autostart" "$dst/etc/polkit-1/rules.d"
cp "$src/live-vm-display.sh" "$dst/usr/local/bin/blackcomb-vm-display"
chmod 755 "$dst/usr/local/bin/blackcomb-vm-display"
cp "$src/live-vm-display.desktop" "$dst/etc/xdg/autostart/blackcomb-vm-display.desktop"
cp "$src/live-keyboard.rules" "$dst/etc/polkit-1/rules.d/49-blackcomb-live-keyboard.rules"
exit 0
''')
    setup.chmod(0o755)

    unit = (live / 'live-setup.service').read_text()
    unit_dir = boot_dir / 'etc/systemd/system'
    wants = unit_dir / 'initrd-switch-root.target.wants'
    wants.mkdir(parents=True, exist_ok=True)
    (unit_dir / 'blackcomb-live-setup.service').write_text(unit)
    # systemd pulls in every unit named in a .wants directory; a regular file
    # with the unit content works as well as a symlink to the real unit.
    (wants / 'blackcomb-live-setup.service').write_text(unit)


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
    write_live_session_fixes(boot_dir)
    output.write_text(patched)


if __name__ == '__main__':
    main()
