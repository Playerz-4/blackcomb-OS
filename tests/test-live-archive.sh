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
grep -Fq 'plymouth-quit-wait' "$hook"
grep -Fq 'exit 0' "$hook"
if grep -q 'initrd-switch-root.target.wants' "$hook"; then
  echo 'Hook must not add a switch-root unit' >&2
  exit 1
fi
wait="$tmp/extracted/usr/share/blackcomb/live/sddm-wait.conf"
grep -Fxq 'After=plymouth-quit.service' "$wait"
if grep -q 'plymouth-quit-wait.service' "$wait"; then
  echo 'plymouth-quit-wait would create an ordering cycle' >&2
  exit 1
fi
grep -Fxq 'ExecStartPre=/bin/sleep 5' "$wait"
grep -Fxq 'ExecStartPre=/bin/sleep 5' \
  "$tmp/extracted/usr/share/blackcomb/live/plasmalogin-wait.conf"
grep -Fq 'xrandr --output' \
  "$tmp/extracted/usr/share/blackcomb/live/live-vm-display.sh"
test -x "$tmp/extracted/usr/share/blackcomb/live/live-vm-display.sh"
cmp "$tmp/extracted/usr/share/blackcomb/live/kim-stargazer.png" \
  "$root/backgrounds/kim-stargazer.png"
echo 'Uncompressed live boot archive test passed.'
