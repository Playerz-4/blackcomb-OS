#!/usr/bin/env python3
import importlib.util
import tempfile
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
# Keep the splash (rhgb), but stop Plymouth claiming the early EFI framebuffer
# DRM card so SDDM/KWin can start, and pin a VM-friendly framebuffer size.
assert ('quiet rhgb root=live:CDLABEL=Fedora-KDE-Live-45 rd.live.image '
        'plymouth.use-simpledrm=0 video=1024x768 '
        'systemd.setenv=KWIN_DRM_NO_AMS=1 '
        'systemd.setenv=KWIN_FORCE_SW_CURSOR=1\n') in normal
assert normal.count('rhgb') == 1
assert normal.count('plymouth.use-simpledrm=0') == 1
assert normal.count('video=1024x768') == 1
assert normal.count('systemd.setenv=KWIN_DRM_NO_AMS=1') == 1
assert normal.count('systemd.setenv=KWIN_FORCE_SW_CURSOR=1') == 1
default_entry = normal.split('menuentry "Boot Blackcomb"')[1]
assert 'nomodeset' not in default_entry and '${basicgfx}' not in default_entry
without_splash = original.replace('quiet rhgb ', '')
patched_without_splash = mod.patch_grub(without_splash)
normal_without_splash = patched_without_splash.split('submenu "Troubleshooting -->"')[0]
assert (' root=live:CDLABEL=Fedora-KDE-Live-45 rd.live.image '
        'rhgb plymouth.use-simpledrm=0 video=1024x768 '
        'systemd.setenv=KWIN_DRM_NO_AMS=1 '
        'systemd.setenv=KWIN_FORCE_SW_CURSOR=1\n') in normal_without_splash
assert normal_without_splash.count('rhgb') == 1
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
with tempfile.TemporaryDirectory() as directory:
    boot = Path(directory) / 'boot'
    mod.write_live_session_fixes(boot)
    live = boot / 'usr/share/blackcomb/live'
    assert (live / 'wallpapers/kim-stargazer/metadata.json').is_file()
    assert (live / 'wallpapers/blackcomb-aurora/metadata.json').is_file()
    assert (live / 'patch-breeze-wallpaper.sh').is_file()
    assert 'Image=kim-stargazer' in (live / 'patch-breeze-wallpaper.sh').read_text()
    assert not (live / 'lookandfeel').exists()
    assert not (live / 'blackpkdgs.sh').exists()
    hook = (boot / 'var/lib/dracut/hooks/pre-pivot/99-blackcomb-live.sh').read_text()
    assert '/usr/share/wallpapers' in hook
    assert 'com.blackcomb.mountain.desktop' not in hook
    assert 'LookAndFeelPackage=org.kde.breeze.desktop' in hook
    assert 'patch-breeze-wallpaper.sh' in hook
    assert 'blackpkdgs' not in hook
print('Live GRUB menu tests passed.')
