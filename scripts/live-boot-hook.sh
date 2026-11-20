#!/bin/sh
# dracut pre-pivot hook (run as 99-blackcomb-live.sh), after the live overlay
# is mounted. /sysroot is the mounted live root. Copy Blackcomb's session
# fixes into its writable overlay so the next systemd startup sees them.
#
# This is deliberately NOT a systemd unit and is not a switch-root dependency:
# it runs inside the existing dracut-pre-pivot.service and always exits 0, so
# a failed copy cannot block switch-root or drop the session into emergency
# mode. Every operation is best effort.
src=/usr/share/blackcomb/live
dst=/sysroot

[ -d "$src" ] || exit 0
[ -d "$dst/etc" ] || exit 0

mkdir -p "$dst/etc/systemd/system/sddm.service.d" \
         "$dst/etc/xdg/autostart" \
         "$dst/etc/polkit-1/rules.d" \
         "$dst/usr/local/bin" \
         "$dst/usr/share/backgrounds/blackcomb" 2>/dev/null || exit 0

# SDDM must wait for Plymouth to release the DRM device (RHBZ 2404966).
cp -f "$src/sddm-wait.conf" \
  "$dst/etc/systemd/system/sddm.service.d/10-blackcomb-wait.conf" 2>/dev/null || :

# VM display autostart.
cp -f "$src/live-vm-display.sh" "$dst/usr/local/bin/blackcomb-vm-display" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-vm-display" 2>/dev/null || :
cp -f "$src/live-vm-display.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-vm-display.desktop" 2>/dev/null || :

# Keyboard layout change without a root password (live media has none).
cp -f "$src/live-keyboard.rules" \
  "$dst/etc/polkit-1/rules.d/49-blackcomb-live-keyboard.rules" 2>/dev/null || :

# Initial wallpaper for new live users.
cp -f "$src/kim-stargazer.png" \
  "$dst/usr/share/backgrounds/blackcomb/kim-stargazer.png" 2>/dev/null || :
cp -f "$src/blackcomb-wallpaper.sh" "$dst/usr/local/bin/blackcomb-wallpaper" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-wallpaper" 2>/dev/null || :
cp -f "$src/blackcomb-wallpaper.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-wallpaper.desktop" 2>/dev/null || :

exit 0
