#!/bin/sh
# Set the Plasma application-launcher button icon for the live session.
# Kickoff stores its icon in plasma-org.kde.plasma.desktop-appletsrc and accepts
# an absolute PNG path, so no icon theme or SVG editing is needed. This runs as
# the live user after Plasma has created its panel configuration.
set -eu

icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

i=0
while [ ! -f "$cfg" ] && [ "$i" -lt 60 ]; do
  sleep 1
  i=$((i + 1))
done
[ -f "$cfg" ] || exit 0

# Already applied on this live session.
if grep -Fqx "icon=$icon" "$cfg"; then
  exit 0
fi

tmp=$(mktemp)
awk -F= '
  /^\[Containments\]\[[^]]+\]\[Applets\]\[[^]]+\]$/ {
    group=$0
    gsub(/^\[|\]$/, "", group)
    next
  }
  $1 == "plugin" && $2 == "org.kde.plasma.kickoff" && group != "" { print group }
' "$cfg" | sort -u > "$tmp"

if [ ! -s "$tmp" ]; then
  rm -f "$tmp"
  exit 0
fi

# KConfig merges repeated group sections, so appending the Configuration
# groups is sufficient and keeps this helper independent of kwriteconfig6.
while IFS= read -r group; do
  printf '\n[%s][Configuration]\nicon=%s\n' "$group" "$icon" >> "$cfg"
done < "$tmp"

rm -f "$tmp"
exit 0
