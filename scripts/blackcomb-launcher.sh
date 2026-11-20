#!/bin/sh
# Configure the Plasma panel for the Blackcomb live/installed session:
#   - use the supplied crescent PNG for the Kickoff launcher button;
#   - dock the panel on the left edge as a vertical taskbar.
#
# Plasma::Types::Location is 5 for LeftEdge and FormFactor is 3 for Vertical.
# Kickoff reads its icon from the applet's [General] group. The settings are
# appended to plasma-org.kde.plasma.desktop-appletsrc so they survive logout,
# and a guarded Plasma scripting call applies them to the running shell too.
# No icon theme or SVG editing is needed.
set -eu

icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

i=0
while [ ! -f "$cfg" ] && [ "$i" -lt 60 ]; do
  sleep 1
  i=$((i + 1))
done
[ -f "$cfg" ] || exit 0

icon_groups=$(mktemp)
panel_groups=$(mktemp)
trap 'rm -f "$icon_groups" "$panel_groups"' EXIT HUP INT TERM

# Already applied on this session? Do not append the same settings again.
if grep -Fqx "icon=$icon" "$cfg"; then
  : > "$icon_groups"
else
  awk -F= '
    /^\[Containments\]\[[^]]+\]\[Applets\]\[[^]]+\]$/ {
      group=$0
      gsub(/^\[|\]$/, "", group)
      next
    }
    /^\[/ { group=""; next }
    $1 == "plugin" && $2 == "org.kde.plasma.kickoff" && group != "" { print group }
  ' "$cfg" | sort -u > "$icon_groups"
fi

# Find panel containments that still need the left-edge vertical layout.
# Later duplicate group sections are merged by KConfig, so the values appended
# below win without rewriting Plasma's own configuration.
awk -F= '
  /^\[Containments\]\[[^]]+\]$/ {
    group=$0
    gsub(/^\[|\]$/, "", group)
    plugin[group]="" ; location[group]="" ; formfactor[group]=""
    next
  }
  /^\[/ { group=""; next }
  group != "" {
    if ($1 == "plugin") plugin[group]=$2
    else if ($1 == "location") location[group]=$2
    else if ($1 == "formfactor") formfactor[group]=$2
  }
  END {
    for (g in plugin) {
      if (plugin[g] == "org.kde.panel" &&
          (location[g] != "5" || formfactor[g] != "3")) {
        print g
      }
    }
  }
' "$cfg" | sort -u > "$panel_groups"

while IFS= read -r group; do
  [ -n "$group" ] || continue
  printf '\n[%s][General]\nicon=%s\n' "$group" "$icon" >> "$cfg"
done < "$icon_groups"

while IFS= read -r group; do
  [ -n "$group" ] || continue
  printf '\n[%s]\nlocation=5\nformfactor=3\n' "$group" >> "$cfg"
done < "$panel_groups"

# Ask a running Plasma shell to apply both changes immediately. The config
# append only takes full effect on the next Plasma start, so this keeps the
# live session correct without restarting the shell. The script prints counts
# so this helper can keep retrying until the shell has actually loaded both
# the panel and the Kickoff applet. qdbus and dbus-send are optional; a missing
# tool or shell can never break the helper.
launcher_js='var allPanels = panels(); var moved = 0; var icons = 0; for (var i = 0; i < allPanels.length; i++) { allPanels[i].location = "left"; moved++; var widgets = allPanels[i].widgets(); for (var j = 0; j < widgets.length; j++) { var w = widgets[j]; if (w.type === "org.kde.plasma.kickoff") { w.currentConfigGroup = ["General"]; w.writeConfig("icon", "'"$icon"'"); w.reloadConfig(); icons++; } } } print("BLACKCOMB_OK:" + moved + ":" + icons);'

apply_live_layout() {
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.plasmashell /PlasmaShell \
      org.kde.PlasmaShell.evaluateScript "$launcher_js"
  elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.plasmashell /PlasmaShell \
      org.kde.PlasmaShell.evaluateScript "$launcher_js"
  elif command -v dbus-send >/dev/null 2>&1; then
    dbus-send --session --print-reply --dest=org.kde.plasmashell \
      /PlasmaShell org.kde.PlasmaShell.evaluateScript string:"$launcher_js"
  else
    return 1
  fi
}

if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  i=0
  while [ "$i" -lt 30 ]; do
    result=$(apply_live_layout 2>/dev/null || :)
    counts=$(printf '%s\n' "$result" |
      sed -n 's/.*BLACKCOMB_OK:\([0-9][0-9]*\):\([0-9][0-9]*\).*/\1:\2/p' |
      head -n 1)
    if [ -n "$counts" ]; then
      panel_count=${counts%%:*}
      kickoff_count=${counts##*:}
      if [ "$panel_count" -gt 0 ] && [ "$kickoff_count" -gt 0 ]; then
        break
      fi
    fi
    i=$((i + 1))
    sleep 1
  done
fi

exit 0
