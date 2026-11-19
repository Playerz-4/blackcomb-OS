#!/bin/sh
# Apply the wallpaper once per user; subsequent wallpaper choices are theirs.
set -eu
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/blackcomb"
marker="$state_dir/wallpaper-initialized"
[ ! -e "$marker" ] || exit 0
command -v plasma-apply-wallpaperimage >/dev/null 2>&1 || exit 0
# Plasma's desktop service may not be available immediately at autostart.
i=0
while [ "$i" -lt 12 ]; do
  if plasma-apply-wallpaperimage /usr/share/backgrounds/blackcomb/kim-stargazer.png; then
    mkdir -p "$state_dir"
    touch "$marker"
    exit 0
  fi
  i=$((i + 1))
  sleep 5
done
exit 1
