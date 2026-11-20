#!/bin/sh
# Best effort: pick a modest display mode so Plasma fits a typical VirtualBox
# window without Guest Additions. Works for both the X11 and Wayland sessions.
set -eu
state="${XDG_STATE_HOME:-$HOME/.local/state}/blackcomb"
[ ! -e "$state/vm-display-initialized" ] || exit 0
systemd-detect-virt --vm >/dev/null 2>&1 || exit 0

done_ok() {
  mkdir -p "$state"
  : > "$state/vm-display-initialized"
}

# X11: xrandr is the direct, reliable path. Prefer 1024x768, then 1280x720,
# then 800x600; only use modes the connected output actually advertises.
if [ -n "${DISPLAY:-}" ] && command -v xrandr >/dev/null 2>&1; then
  info=$(xrandr --query 2>/dev/null || true)
  output=$(printf '%s\n' "$info" | awk '$2 == "connected" { print $1; exit }')
  if [ -n "$output" ]; then
    modes=$(printf '%s\n' "$info" | awk -v o="$output" '
      $1 == o { found = 1; next }
      found && $2 == "connected" { exit }
      found && /^[ \t]*[0-9]+x[0-9]+/ { print }
    ')
    for mode in 1024x768 1280x720 800x600; do
      if printf '%s\n' "$modes" | grep -Eq "^[ \t]*${mode}([ \t]|$)"; then
        if xrandr --output "$output" --mode "$mode" >/dev/null 2>&1; then
          done_ok
          exit 0
        fi
      fi
    done
  fi
fi

# Wayland fallback: ask KWin/KScreen for a modest mode. The mode numbers are
# exactly those printed by kscreen-doctor --outputs.
command -v kscreen-doctor >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
info=''
i=0
while [ "$i" -lt 15 ]; do
  info=$(kscreen-doctor --outputs 2>/dev/null || true)
  case $info in *Modes:*) break ;; esac
  i=$((i + 1))
  sleep 2
done
case $info in *Modes:*) ;; *) exit 0 ;; esac
chosen=$(printf '%s\n' "$info" | python3 -c '
import re
import sys
line = next((row for row in sys.stdin if "Modes:" in row), "")
out = re.search(r"Output:\s*(\d+)", line)
modes = [(int(w), int(h), int(i)) for i, w, h in
         re.findall(r"(\d+):(\d+)x(\d+)@", line)]
if out and modes:
    wanted = {(1024, 768): 3, (1280, 720): 2, (800, 600): 1}
    best = min(modes, key=lambda m: (-wanted.get((m[0], m[1]), 0), m[0] * m[1]))
    print(out.group(1), best[2])
' 2>/dev/null) || exit 0
[ -n "$chosen" ] || exit 0
set -- $chosen
if kscreen-doctor "output.$1.mode.$2" >/dev/null 2>&1; then
  done_ok
fi
exit 0
