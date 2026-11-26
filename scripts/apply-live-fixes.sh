#!/bin/sh
# Apply Blackcomb's live-session polkit, VM-display, wallpaper and theme fixes.
# Run from a terminal:  sudo bash /path/to/blackcomb/apply-live-fixes.sh
# Nothing is changed until you run this, so it cannot affect booting.
set -eu
if [ "$(id -u)" -ne 0 ]; then
  echo 'Run with sudo.' >&2
  exit 1
fi
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
for file in live-keyboard.rules live-keyboard.pkla live-vm-display.sh live-vm-display.desktop \
            scripts/patch-lock-screen-wallpaper.sh \
            scripts/neofetch scripts/neofetch.conf scripts/neofetch-ascii.conf \
            scripts/neofetch-launcher.sh scripts/neofetch-LICENSE.md \
            assets/branding/crescent-moon-neofetch.txt; do
  [ -f "$HERE/$file" ] || { echo "Missing kit file: $file" >&2; exit 1; }
done
mkdir -p /usr/local/bin /etc/xdg/autostart /etc/polkit-1/rules.d \
  /var/lib/polkit-1/localauthority/50-local.d
cp "$HERE/live-vm-display.sh" /usr/local/bin/blackcomb-vm-display
chmod 755 /usr/local/bin/blackcomb-vm-display
cp "$HERE/live-vm-display.desktop" /etc/xdg/autostart/blackcomb-vm-display.desktop
cp "$HERE/live-keyboard.rules" /etc/polkit-1/rules.d/00-blackcomb-live-keyboard.rules
cp "$HERE/live-keyboard.pkla" /var/lib/polkit-1/localauthority/50-local.d/00-blackcomb-live-keyboard.pkla
cp "$HERE/scripts/patch-lock-screen-wallpaper.sh" /usr/local/bin/blackcomb-lock-screen-wallpaper
chmod 755 /usr/local/bin/blackcomb-lock-screen-wallpaper
/bin/sh /usr/local/bin/blackcomb-lock-screen-wallpaper / || :
if [ -d "$HERE/themes/opencode" ]; then
  mkdir -p /usr/share/color-schemes
  cp "$HERE"/themes/opencode/*.colors /usr/share/color-schemes/
fi
if [ -d "$HERE/applets" ]; then
  mkdir -p /usr/share/plasma/plasmoids
  for applet in "$HERE"/applets/*; do
    [ -d "$applet" ] || continue
    [ -f "$applet/metadata.json" ] || continue
    id=$(basename "$applet")
    mkdir -p "/usr/share/plasma/plasmoids/$id/contents/ui"
    cp "$applet/metadata.json" "/usr/share/plasma/plasmoids/$id/"
    cp "$applet"/contents/ui/*.qml "/usr/share/plasma/plasmoids/$id/contents/ui/"
  done
fi
mkdir -p /usr/local/lib/blackcomb/neofetch /etc/skel/.config/neofetch
cp "$HERE/scripts/neofetch" /usr/local/lib/blackcomb/neofetch/neofetch
chmod 755 /usr/local/lib/blackcomb/neofetch/neofetch
cp "$HERE/scripts/neofetch.conf" /usr/local/lib/blackcomb/neofetch/chafa.conf
cp "$HERE/scripts/neofetch-ascii.conf" /usr/local/lib/blackcomb/neofetch/ascii.conf
cp "$HERE/assets/branding/crescent-moon-neofetch.txt" /usr/local/lib/blackcomb/neofetch/crescent-moon-neofetch.txt
cp "$HERE/scripts/neofetch-LICENSE.md" /usr/local/lib/blackcomb/neofetch/LICENSE.md
cp "$HERE/scripts/neofetch-launcher.sh" /usr/local/bin/neofetch
chmod 755 /usr/local/bin/neofetch
cp "$HERE/scripts/neofetch.conf" /etc/skel/.config/neofetch/config.conf
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
  user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  if [ -n "$user_home" ] && [ -d "$user_home" ]; then
    mkdir -p "$user_home/.config/neofetch"
    cp "$HERE/scripts/neofetch.conf" "$user_home/.config/neofetch/config.conf"
    chown -R "$SUDO_USER:$(id -gn "$SUDO_USER")" "$user_home/.config/neofetch" 2>/dev/null || :
    /bin/sh /usr/local/bin/blackcomb-lock-screen-wallpaper \
      --file "$user_home/.config/kscreenlockerrc" || :
    chown "$SUDO_USER:$(id -gn "$SUDO_USER")" \
      "$user_home/.config/kscreenlockerrc" 2>/dev/null || :
  fi
fi
echo 'Live-session fixes applied. Log out and back in (or reboot) to use them.'
