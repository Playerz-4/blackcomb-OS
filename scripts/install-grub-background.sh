#!/usr/bin/env bash
# Opt-in GRUB menu background; separate from Ubuntu's Plymouth boot splash.
set -Eeuo pipefail
usage() {
  cat <<'HELP'
Usage: sudo blackcomb-grub-background

Install the Blackcomb GRUB menu background on an installed Ubuntu system and
regenerate grub.cfg. Existing GRUB settings are not replaced. GRUB may hide its
menu by default; use Shift or Esc during boot to show it. The Plymouth loading
screen is not changed.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($#)); then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root using sudo.' >&2; exit 1; }
[[ -f /etc/default/grub ]] || { echo 'GRUB configuration not found; no changes made.' >&2; exit 1; }
command -v update-grub >/dev/null || { echo 'update-grub is unavailable; no changes made.' >&2; exit 1; }
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
image=$here/../assets/branding/grub-background.png
if [[ ! -f $image ]]; then image=/usr/share/blackcomb/branding/grub-background.png; fi
[[ -f $image ]] || { echo 'Blackcomb GRUB background not found; run setup first.' >&2; exit 1; }
install -d /boot/grub /etc/default/grub.d
install -m 644 "$image" /boot/grub/blackcomb-background.png
printf 'GRUB_BACKGROUND="/boot/grub/blackcomb-background.png"\n' > /etc/default/grub.d/60-blackcomb-background.cfg
update-grub
printf 'Blackcomb GRUB background enabled. The Plymouth loading splash is unchanged.\n'
