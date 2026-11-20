#!/usr/bin/env python3
import importlib.util
from pathlib import Path

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('live_boot', root / 'scripts/prepare-live-boot.py')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
original = (root / 'tests/fixtures/fedora-live-grub.cfg').read_text()
patched = mod.patch_grub(original)
assert 'set default="0"\nif ' in patched
assert 'Test this media' not in patched and 'rd.live.check' not in patched
assert 'menuentry "Boot Blackcomb" --class fedora --class gnu-linux --class gnu --class os' in patched
assert 'menuentry "Start Fedora-KDE-Live"' not in patched
assert 'submenu "Troubleshooting -->"' in patched
assert 'menuentry "Start Blackcomb (basic graphics, no splash)"' not in patched
assert patched.count('($root)/blackcomb-boot/plymouth.cpio') == 1
assert patched.count('menuentry ') == 2
troubleshooting = patched.split('submenu "Troubleshooting -->"')[1]
original_troubleshooting = original.split('submenu "Troubleshooting -->"')[1]
assert troubleshooting == original_troubleshooting
normal_entry = patched.split('submenu "Troubleshooting -->"')[0]
assert 'initrd ($root)/boot/x86_64/loader/initrd ($root)/blackcomb-boot/plymouth.cpio' in normal_entry
assert 'quiet rhgb root=live:CDLABEL=Fedora-KDE-Live-45 rd.live.image\n' in patched
without_splash = original.replace('quiet rhgb ', '')
patched_without_splash = mod.patch_grub(without_splash)
normal = patched_without_splash.split('submenu "Troubleshooting -->"')[0]
assert 'rd.live.image rhgb\n' in normal
assert 'rd.live.image ${basicgfx}\n' in patched_without_splash
# Firmware configs may use initrdefi instead of initrd; recovery must still
# keep the stock initrd while only normal boot receives the branded overlay.
efi_original = original.replace('    initrd ', '    initrdefi ')
efi_patched = mod.patch_grub(efi_original)
assert efi_patched.count('($root)/blackcomb-boot/plymouth.cpio') == 1
assert efi_patched.split('submenu "Troubleshooting -->"')[1] == efi_original.split('submenu "Troubleshooting -->"')[1]
for bad in [original.replace('Test this media', 'Unexpected test'),
            original.replace('rd.live.check', 'broken'),
            original.replace('Start Fedora-KDE-Live"', 'Start Unknown"'),
            original.replace('/boot/x86_64/loader/initrd', '/other/initrd'),
            original.replace('set default="1"', 'set default=saved')]:
    try:
        mod.patch_grub(bad)
    except SystemExit:
        pass
    else:
        raise AssertionError('Unexpected menu layout was accepted')
print('Live GRUB menu tests passed.')
