#!/usr/bin/env bash
# Verify that the launcher helper docks the Plasma panel left, sets the
# crescent PNG as the Kickoff icon, and adds the standard panel widgets without
# disturbing other containments or duplicating changes on a second run.
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
grep -Fq 'allPanels[i].location = "left"' "$root/scripts/blackcomb-launcher.sh" || grep -Fq 'panel.location = "left"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'w.writeConfig("icon"' "$root/scripts/blackcomb-launcher.sh" || grep -Fq 'current.writeConfig("icon"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'currentConfigGroup = ["General"]' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'BLACKCOMB_OK:' "$root/scripts/blackcomb-launcher.sh"
grep -Fq -- '--print-reply' "$root/scripts/blackcomb-launcher.sh"
grep -Fxq '[Containments][1][Applets][2][General]' "$cfg"
grep -Fxq 'icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png' "$cfg"
test "$(grep -Ec '^location=5$' "$cfg")" -eq 1
test "$(grep -Ec '^plugin=org.kde.plasma.desktop$' "$cfg")" -eq 1
grep -Fxq 'location=1' "$cfg"

for plugin in org.kde.plasma.systemmonitor.memory org.kde.plasma.battery \
              org.kde.plasma.systemmonitor org.kde.plasma.digitalclock; do
  grep -Fxq "plugin=$plugin" "$cfg"
  test "$(grep -Ec "^plugin=$plugin\$" "$cfg")" -eq 1
done
# Dynamic Music is added once to the panel and once to the desktop so the
# artist/title remain readable in either layout.
test "$(grep -Ec '^plugin=org.kde.plasma.mediacontroller$' "$cfg")" -eq 2
test "$(grep -Ec '^plugin=org.kde.plasma.notifications$' "$cfg")" -eq 1
grep -Fxq 'global=Meta+N' "$cfg"
grep -Fxq '[Containments][1][Applets][8][Shortcuts]' "$cfg"
grep -Fxq 'title=RAM' "$cfg"
grep -Fxq 'chartFace=org.kde.ksysguard.horizontalbars' "$cfg"
grep -Fxq 'sensorIds=["memory/physical/usedPercent"]' "$cfg"
grep -Fxq 'title=GPU' "$cfg"
grep -Fxq 'blackcombWidget=gpu' "$cfg"
grep -Fxq 'sensorIds=["gpu/all/usage"]' "$cfg"
grep -Fq 'containment.addWidget(spec.id)' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'addWidgetTo(panel, blackcombWidgets[k], seen)' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'memory/physical/usedPercent' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'gpu/all/usage' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'org.kde.plasma.digitalclock' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'org.kde.plasma.mediacontroller' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'org.kde.plasma.notifications' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'Meta+N' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'var allDesktops = desktops();' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'addWidgetTo(desktop, blackcombWidgets[4], desktopSeen)' "$root/scripts/blackcomb-launcher.sh"

cp "$cfg" "$tmp/before"
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"
cmp "$cfg" "$tmp/before"
echo 'Plasma taskbar, launcher and panel widget tests passed.'
