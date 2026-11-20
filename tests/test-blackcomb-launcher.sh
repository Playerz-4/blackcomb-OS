#!/usr/bin/env bash
# Verify that the launcher helper docks the Plasma panel left and sets the
# crescent PNG as the Kickoff icon, without disturbing other containments.
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/.config"
cfg="$tmp/home/.config/plasma-org.kde.plasma.desktop-appletsrc"
cat > "$cfg" <<'EOF'
[Containments][1]
activityId=
formfactor=2
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][1][Applets][2]
plugin=org.kde.plasma.kickoff

[Containments][3]
activityId=
formfactor=0
lastScreen=0
location=1
plugin=org.kde.plasma.desktop
wallpaperplugin=org.kde.image
EOF

HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"

grep -Fxq 'location=5' "$cfg"
grep -Fxq 'formfactor=3' "$cfg"
grep -Fq 'org.kde.PlasmaShell.evaluateScript' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'allPanels[i].location = "left"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'w.writeConfig("icon"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'currentConfigGroup = ["General"]' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'BLACKCOMB_OK:' "$root/scripts/blackcomb-launcher.sh"
grep -Fq -- '--print-reply' "$root/scripts/blackcomb-launcher.sh"
grep -Fxq '[Containments][1][Applets][2][General]' "$cfg"
grep -Fxq 'icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png' "$cfg"
test "$(grep -Ec '^location=5$' "$cfg")" -eq 1
test "$(grep -Ec '^plugin=org.kde.plasma.desktop$' "$cfg")" -eq 1
grep -Fxq 'location=1' "$cfg"

cp "$cfg" "$tmp/before"
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"
cmp "$cfg" "$tmp/before"
echo 'Plasma left taskbar and crescent launcher tests passed.'
