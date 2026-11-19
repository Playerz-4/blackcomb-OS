#!/bin/sh
# Best effort: pick a modest KMS mode so Plasma fits a typical VirtualBox
# window without Guest Additions. Installed into the live root at boot.
set -eu
state="${XDG_STATE_HOME:-$HOME/.local/state}/blackcomb"
[ ! -e "$state/vm-display-initialized" ] || exit 0
systemd-detect-virt --vm >/dev/null 2>&1 || exit 0
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

# Prefer 1024x768, then 1280x720, then the smallest advertised mode. Use the
# mode numbers exactly as kscreen-doctor prints them.
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
  mkdir -p "$state"
  : > "$state/vm-display-initialized"
fi
exit 0
