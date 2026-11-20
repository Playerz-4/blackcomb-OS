#!/usr/bin/env bash
# Real cpio round-trip: verify the boot logo and theme are in the overlay.
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 "$root/scripts/prepare-live-boot.py" "$root/tests/fixtures/fedora-live-grub.cfg" "$tmp/grub.cfg" "$tmp/stage"
"$root/scripts/create-live-boot-archive.sh" "$tmp/stage" "$root/assets/branding/blackcomb-boot-watermark.png" "$tmp/plymouth.cpio"
mkdir "$tmp/extracted"
(cd "$tmp/extracted" && cpio -id --quiet < "$tmp/plymouth.cpio")
cmp "$tmp/extracted/usr/share/plymouth/themes/spinner/watermark.png" "$root/assets/branding/blackcomb-boot-watermark.png"
grep -Fxq 'Theme=blackcomb-live' "$tmp/extracted/etc/plymouth/plymouthd.conf"
grep -Fxq 'ModuleName=two-step' "$tmp/extracted/usr/share/plymouth/themes/blackcomb-live/blackcomb-live.plymouth"
hook="$tmp/extracted/var/lib/dracut/hooks/pre-pivot/99-blackcomb-live.sh"
test -x "$hook"
grep -Fq 'sddm.service.d/10-blackcomb-wait.conf' "$hook"
grep -Fq 'plasmalogin.service.d/10-blackcomb-wait.conf' "$hook"
grep -Fq 'plasmalogin.conf.d/99-blackcomb-live.conf' "$hook"
grep -Fq 'plasmalogin.conf.d/50-blackcomb-wallpaper.conf' "$hook"
grep -Fq '00-blackcomb-live-keyboard.rules' "$hook"
grep -Fq 'crescent-moon-start-icon.png' "$hook"
grep -Fq 'blackcomb-launcher.desktop' "$hook"
grep -Fq 'usr/share/color-schemes' "$hook"
grep -Fq 'ColorScheme=OpenCode-Catppuccin' "$hook"
grep -Fq '.config/neofetch' "$hook"
grep -Fq '/usr/local/bin/neofetch' "$hook"
grep -Fq '/usr/local/lib/blackcomb/neofetch/neofetch' "$hook"
grep -Fq 'crescent-moon-neofetch.txt' "$hook"
grep -Fq 'plymouth-quit-wait' "$hook"
grep -Fq 'exit 0' "$hook"
if grep -q 'initrd-switch-root.target.wants' "$hook"; then
  echo 'Hook must not add a switch-root unit' >&2
  exit 1
fi
wait="$tmp/extracted/usr/share/blackcomb/live/sddm-wait.conf"
grep -Fxq 'After=plymouth-quit.service' "$wait"
if grep -Eq '^[[:space:]]*After=.*plymouth-quit-wait\.service' "$wait"; then
  echo 'plymouth-quit-wait would create an ordering cycle' >&2
  exit 1
fi
grep -Fxq 'ExecStartPre=/bin/sleep 5' "$wait"
grep -Fxq 'ExecStartPre=/bin/sleep 5' \
  "$tmp/extracted/usr/share/blackcomb/live/plasmalogin-wait.conf"
autologin="$tmp/extracted/usr/share/blackcomb/live/plasmalogin-autologin.conf"
grep -Fxq '[Autologin][seat0]' "$autologin"
grep -Fxq 'User=liveuser' "$autologin"
grep -Fxq 'Session=plasma.desktop' "$autologin"
wallpaper="$tmp/extracted/usr/share/blackcomb/live/plasmalogin-wallpaper.conf"
grep -Fxq 'WallpaperPluginId=org.kde.image' "$wallpaper"
grep -Fxq 'Image=file:///usr/share/backgrounds/blackcomb/kim-stargazer.png' "$wallpaper"
grep -Fxq 'PreviewImage=file:///usr/share/backgrounds/blackcomb/kim-stargazer.png' "$wallpaper"
keyboard="$tmp/extracted/usr/share/blackcomb/live/live-keyboard.rules"
grep -Fq 'subject.user == "liveuser"' "$keyboard"
if grep -q 'subject.active' "$keyboard"; then
  echo 'Keyboard policy must not require subject.active' >&2
  exit 1
fi
kwin_env="$tmp/extracted/usr/share/blackcomb/live/kwin-vm-env.sh"
grep -Fxq 'export KWIN_DRM_NO_AMS=1' "$kwin_env"
grep -Fxq 'export KWIN_FORCE_SW_CURSOR=1' "$kwin_env"
grep -Fq 'plasma-workspace/env/99-blackcomb-kwin-vm.sh' "$hook"
grep -Fq 'xrandr --output' \
  "$tmp/extracted/usr/share/blackcomb/live/live-vm-display.sh"
test -x "$tmp/extracted/usr/share/blackcomb/live/live-vm-display.sh"
for bg in "$root"/backgrounds/*.png; do
  cmp "$tmp/extracted/usr/share/blackcomb/live/$(basename "$bg")" "$bg"
done
cmp "$tmp/extracted/usr/share/blackcomb/live/crescent-moon-start-icon.png" \
  "$root/assets/branding/crescent-moon-start-icon.png"
launcher="$tmp/extracted/usr/share/blackcomb/live/blackcomb-launcher.sh"
grep -Fxq 'icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png' "$launcher"
grep -Fq '[General]' "$launcher"
grep -Fq 'org.kde.plasma.kickoff' "$launcher"
grep -Fq 'location=5' "$launcher"
grep -Fq 'formfactor=3' "$launcher"
test -x "$launcher"
cmp "$tmp/extracted/usr/share/blackcomb/live/neofetch.conf" "$root/scripts/neofetch.conf"
cmp "$tmp/extracted/usr/share/blackcomb/live/neofetch-ascii.conf" \
  "$root/scripts/neofetch-ascii.conf"
cmp "$tmp/extracted/usr/share/blackcomb/live/neofetch-launcher.sh" \
  "$root/scripts/neofetch-launcher.sh"
cmp "$tmp/extracted/usr/share/blackcomb/live/neofetch" \
  "$root/third-party/neofetch/neofetch"
cmp "$tmp/extracted/usr/share/blackcomb/live/crescent-moon-neofetch.txt" \
  "$root/assets/branding/crescent-moon-neofetch.txt"
test -x "$tmp/extracted/usr/share/blackcomb/live/neofetch"
test -x "$tmp/extracted/usr/share/blackcomb/live/neofetch-launcher.sh"
theme="$tmp/extracted/usr/share/blackcomb/live/themes/OpenCode-Catppuccin.colors"
cmp "$theme" "$root/themes/opencode/OpenCode-Catppuccin.colors"
grep -Fxq 'Name=OpenCode Catppuccin' "$theme"
grep -Fxq 'ColorScheme=OpenCode-Catppuccin' "$theme"
test -f "$tmp/extracted/usr/share/blackcomb/live/themes/OpenCode-Nord-Light.colors"
echo 'Uncompressed live boot archive test passed.'
