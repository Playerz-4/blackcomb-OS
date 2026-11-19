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
assert patched.count('($root)/blackcomb-boot/plymouth.cpio') == 2
assert patched.count('menuentry ') == 2
troubleshooting = patched.split('submenu "Troubleshooting -->"')[1]
original_troubleshooting = original.split('submenu "Troubleshooting -->"')[1]
assert troubleshooting == original_troubleshooting.replace(
    '/boot/x86_64/loader/initrd\n',
    '/boot/x86_64/loader/initrd ($root)/blackcomb-boot/plymouth.cpio\n')
normal = patched.split('submenu "Troubleshooting -->"')[0]
assert 'quiet root=live:CDLABEL=Fedora-KDE-Live-45 rd.live.image\n' in normal
# Black-screen fix: "rhgb" must never be added to (or left in) the default
# entry. With it, Plymouth holds the DRM device while SDDM starts and the
# Plasma desktop never appears (Red Hat bug 2404966).
assert 'rhgb' not in normal
without_splash = original.replace('quiet rhgb ', '')
patched_without_splash = mod.patch_grub(without_splash)
normal_without_splash = patched_without_splash.split('submenu "Troubleshooting -->"')[0]
assert ' root=live:CDLABEL=Fedora-KDE-Live-45 rd.live.image\n' in normal_without_splash
assert 'rhgb' not in normal_without_splash
assert 'rd.live.image ${basicgfx}\n' in patched_without_splash
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
