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
test -f "$tmp/extracted/usr/share/blackcomb/live/live-vm-display.sh"
grep -Fq 'org.freedesktop.locale1.set-keyboard' "$tmp/extracted/usr/share/blackcomb/live/live-keyboard.rules"
grep -Fxq 'ExecStart=/usr/sbin/blackcomb-live-setup' "$tmp/extracted/etc/systemd/system/blackcomb-live-setup.service"
test -f "$tmp/extracted/etc/systemd/system/initrd-switch-root.target.wants/blackcomb-live-setup.service"
test -f "$tmp/extracted/usr/sbin/blackcomb-live-setup"
echo 'Uncompressed live boot archive test passed.'
