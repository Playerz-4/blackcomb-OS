#!/usr/bin/env bash
# Optional GRUB menu background for standard Fedora GRUB installations.
set -Eeuo pipefail
usage() {
  cat <<'HELP'
Usage: sudo blackcomb-grub-background [--remove]

Add or remove the Blackcomb GRUB background on an installed Fedora system.
Regenerates /boot/grub2/grub.cfg, not the EFI stub. Existing GRUB settings are
preserved; an existing GRUB_THEME or console mode can prevent the image showing.
The Plymouth loading screen is not changed. Back up your system before editing.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# > 1)) || [[ ${1:-} != '' && ${1:-} != --remove ]]; then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root using sudo.' >&2; exit 1; }
[[ -f /etc/default/grub && -f /boot/grub2/grub.cfg ]] || { echo 'Standard Fedora GRUB configuration not found; no changes made.' >&2; exit 1; }
command -v grub2-mkconfig >/dev/null || { echo 'grub2-mkconfig is unavailable; no changes made.' >&2; exit 1; }
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
image=$here/../assets/branding/grub-background.png
if [[ ! -f $image ]]; then image=/usr/share/blackcomb/branding/grub-background.png; fi
if [[ ${1:-} != --remove && ! -f $image ]]; then echo 'Blackcomb GRUB background not found; run setup first.' >&2; exit 1; fi
backup=$(mktemp /etc/default/blackcomb-grub.XXXXXXXX)
cp -p /etc/default/grub "$backup"
trap 'rm -f -- "$backup"' EXIT
# Keep all user-owned settings; the final assignment is the only managed line.
sed -i '/^GRUB_BACKGROUND="\/boot\/grub2\/blackcomb-background.png" # blackcomb-managed$/d' /etc/default/grub
if [[ ${1:-} != --remove ]]; then
  install -m 644 "$image" /boot/grub2/blackcomb-background.png
  printf '\nGRUB_BACKGROUND="/boot/grub2/blackcomb-background.png" # blackcomb-managed\n' >> /etc/default/grub
fi
if ! grub2-mkconfig -o /boot/grub2/grub.cfg; then
  cp -p "$backup" /etc/default/grub
  echo 'GRUB regeneration failed; restored /etc/default/grub. Inspect the GRUB configuration before rebooting.' >&2
  exit 1
fi
if [[ ${1:-} == --remove ]]; then rm -f /boot/grub2/blackcomb-background.png; fi
echo 'GRUB configuration updated; the Plymouth loading screen is unchanged.'
