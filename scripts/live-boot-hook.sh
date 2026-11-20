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

mkdir -p "$dst/etc/systemd/system/plasmalogin.service.d" \
         "$dst/etc/systemd/system/sddm.service.d" \
         "$dst/etc/sddm.conf.d" \
         "$dst/etc/plasmalogin.conf.d" \
         "$dst/etc/xdg/autostart" \
         "$dst/etc/profile.d" \
         "$dst/etc/polkit-1/rules.d" \
         "$dst/home/liveuser/.config/plasma-workspace/env" \
         "$dst/usr/local/bin" \
         "$dst/usr/share/backgrounds/blackcomb" \
         "$dst/usr/share/blackcomb/branding" 2>/dev/null || exit 0

# Fedora 44+ KDE uses Plasma Login Manager; older media use SDDM. Both can
# start before Plymouth releases the DRM device (RHBZ 2404966). Wait only for
# plymouth-quit.service; plymouth-quit-wait.service is ordered after the
# display manager and would create a cycle. Drop-ins for absent units are
# ignored, so shipping both is harmless.
cp -f "$src/plasmalogin-wait.conf" \
  "$dst/etc/systemd/system/plasmalogin.service.d/10-blackcomb-wait.conf" 2>/dev/null || :
cp -f "$src/sddm-wait.conf" \
  "$dst/etc/systemd/system/sddm.service.d/10-blackcomb-wait.conf" 2>/dev/null || :

# Reinforce Fedora's runtime autologin. PLM reads named [Autologin][seatN]
# groups separately from the main config, so this cannot be overridden by the
# global User/Session values that livesys writes into /etc/plasmalogin.conf.
cp -f "$src/plasmalogin-autologin.conf" \
  "$dst/etc/plasmalogin.conf.d/99-blackcomb-live.conf" 2>/dev/null || :
cp -f "$src/plasmalogin-wallpaper.conf" \
  "$dst/etc/plasmalogin.conf.d/50-blackcomb-wallpaper.conf" 2>/dev/null || :

# KWin in a VM: legacy DRM mode plus software cursor, per KDE's VirtualBox
# documentation. Also set from the kernel command line so the greeter inherits
# it; these copies cover the live user's Plasma session even if it is restarted.
cp -f "$src/kwin-vm-env.sh" "$dst/etc/profile.d/99-blackcomb-kwin-vm.sh" 2>/dev/null || :
cp -f "$src/kwin-vm-env.sh" \
  "$dst/home/liveuser/.config/plasma-workspace/env/99-blackcomb-kwin-vm.sh" 2>/dev/null || :

# VM display autostart. This keeps working when Plasma loads; the helper uses
# KScreen on Wayland and xrandr if an X11 session is ever present.
cp -f "$src/live-vm-display.sh" "$dst/usr/local/bin/blackcomb-vm-display" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-vm-display" 2>/dev/null || :
cp -f "$src/live-vm-display.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-vm-display.desktop" 2>/dev/null || :

# Keyboard layout change without a root password (live media has none).
# Polkit uses the first matching rule, so 00- takes precedence over Fedora's
# packaged rules that would otherwise ask for authentication.
cp -f "$src/live-keyboard.rules" \
  "$dst/etc/polkit-1/rules.d/00-blackcomb-live-keyboard.rules" 2>/dev/null || :

# Initial wallpaper for new live users and the PLM greeter. Copy every staged
# background so the live wallpaper picker has all Kim/Blackcomb images, not only
# the default stargazer image.
for bg in "$src"/*.png; do
  [ -e "$bg" ] || continue
  case "$(basename "$bg")" in
    crescent-moon-start-icon.png) continue ;;
  esac
  cp -f "$bg" "$dst/usr/share/backgrounds/blackcomb/" 2>/dev/null || :
done
cp -f "$src/blackcomb-wallpaper.sh" "$dst/usr/local/bin/blackcomb-wallpaper" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-wallpaper" 2>/dev/null || :
cp -f "$src/blackcomb-wallpaper.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-wallpaper.desktop" 2>/dev/null || :

# Plasma application-launcher icon supplied with Blackcomb.
cp -f "$src/crescent-moon-start-icon.png" \
  "$dst/usr/share/blackcomb/branding/crescent-moon-start-icon.png" 2>/dev/null || :
cp -f "$src/blackcomb-launcher.sh" \
  "$dst/usr/local/bin/blackcomb-launcher" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-launcher" 2>/dev/null || :
cp -f "$src/blackcomb-launcher.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-launcher.desktop" 2>/dev/null || :

exit 0
