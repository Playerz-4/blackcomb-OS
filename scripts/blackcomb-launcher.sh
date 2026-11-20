#!/bin/sh
# Configure the Plasma panel for the Blackcomb live/installed session:
#   - use the supplied crescent PNG for the Kickoff launcher button;
#   - dock the panel on the left edge as a vertical taskbar.
# Plasma::Types::Location is 5 for LeftEdge and FormFactor is 3 for Vertical.
# Both live in plasma-org.kde.plasma.desktop-appletsrc and accept absolute PNG
# paths, so no icon theme or SVG editing is needed. This runs as the user after
# Plasma has created its panel configuration.
set -eu

icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

i=0
while [ ! -f "$cfg" ] && [ "$i" -lt 60 ]; do
  sleep 1
  i=$((i + 1))
done
[ -f "$cfg" ] || exit 0

# If Plasma is already running, ask it to move existing panels immediately as
# well; the config append below makes the change persist on the next login.
# qdbus is optional, so a missing shell or Qt tooling can never break this
# helper.
qdbus_bin=
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus_bin=qdbus6
elif command -v qdbus >/dev/null 2>&1; then
  qdbus_bin=qdbus
fi
if [ -n "$qdbus_bin" ]; then
  "$qdbus_bin" org.kde.plasmashell /PlasmaShell \
    org.kde.PlasmaShell.evaluateScript \
    'var allPanels = panels(); for (var i = 0; i < allPanels.length; i++) { allPanels[i].location = "left"; }' \
    >/dev/null 2>&1 || :
fi

icon_groups=$(mktemp)
panel_groups=$(mktemp)

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
    plugin[group]=""; location[group]=""; formfactor[group]=""
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

if [ ! -s "$icon_groups" ] && [ ! -s "$panel_groups" ]; then
  rm -f "$icon_groups" "$panel_groups"
  exit 0
fi

while IFS= read -r group; do
  [ -n "$group" ] || continue
  printf '\n[%s][Configuration]\nicon=%s\n' "$group" "$icon" >> "$cfg"
done < "$icon_groups"

while IFS= read -r group; do
  [ -n "$group" ] || continue
  printf '\n[%s]\nlocation=5\nformfactor=3\n' "$group" >> "$cfg"
done < "$panel_groups"

rm -f "$icon_groups" "$panel_groups"
exit 0
