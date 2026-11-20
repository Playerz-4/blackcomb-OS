#!/bin/sh
# Apply Blackcomb's keyboard and VM-display fixes to the running live session.
# Run from a terminal:  sudo bash /path/to/blackcomb/apply-live-fixes.sh
# Nothing is changed until you run this, so it cannot affect booting.
set -eu
if [ "$(id -u)" -ne 0 ]; then
  echo 'Run with sudo.' >&2
  exit 1
fi
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
for file in live-keyboard.rules live-vm-display.sh live-vm-display.desktop; do
  [ -f "$HERE/$file" ] || { echo "Missing kit file: $file" >&2; exit 1; }
done
mkdir -p /usr/local/bin /etc/xdg/autostart /etc/polkit-1/rules.d
cp "$HERE/live-vm-display.sh" /usr/local/bin/blackcomb-vm-display
chmod 755 /usr/local/bin/blackcomb-vm-display
cp "$HERE/live-vm-display.desktop" /etc/xdg/autostart/blackcomb-vm-display.desktop
cp "$HERE/live-keyboard.rules" /etc/polkit-1/rules.d/00-blackcomb-live-keyboard.rules
if [ -d "$HERE/themes/opencode" ]; then
  mkdir -p /usr/share/color-schemes
  cp "$HERE"/themes/opencode/*.colors /usr/share/color-schemes/
fi
echo 'Live-session fixes applied. Log out and back in (or reboot) to use them.'
