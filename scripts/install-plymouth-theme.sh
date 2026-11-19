#!/usr/bin/env bash
# Install a separate copy of Fedora's spinner with Blackcomb branding.
set -Eeuo pipefail
usage() {
  cat <<'HELP'
Usage: sudo blackcomb-plymouth [--restore-fedora]

Install or refresh the Blackcomb Plymouth loading screen and rebuild initramfs.
--restore-fedora resets to the distribution default and rebuilds initramfs.
This affects the installed system, not the live USB or the GRUB menu.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# > 1)) || [[ ${1:-} != '' && ${1:-} != --restore-fedora ]]; then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root using sudo.' >&2; exit 1; }
command -v plymouth-set-default-theme >/dev/null || { echo 'Missing plymouth-set-default-theme.' >&2; exit 1; }
if [[ ${1:-} == --restore-fedora ]]; then
  plymouth-set-default-theme --reset --rebuild-initrd
  echo 'Fedora default Plymouth theme restored.'
  exit 0
fi
spinner=/usr/share/plymouth/themes/spinner
[[ -f $spinner/spinner.plymouth ]] || { echo 'Fedora spinner theme not found; install plymouth-theme-spinner.' >&2; exit 1; }
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
creator=$here/create-plymouth-theme.sh
logo=$here/../assets/branding/blackcomb-boot-watermark.png
if [[ ! -f $creator ]]; then creator=/usr/local/lib/blackcomb/create-plymouth-theme.sh; fi
if [[ ! -f $logo ]]; then logo=/usr/share/blackcomb/branding/blackcomb-boot-watermark.png; fi
[[ -f $creator && -f $logo ]] || { echo 'Blackcomb theme files missing; run setup first.' >&2; exit 1; }
bash "$creator" "$spinner/spinner.plymouth" "$spinner" "$logo" /usr/share/plymouth/themes/blackcomb
plymouth-set-default-theme blackcomb --rebuild-initrd
echo 'Blackcomb Plymouth theme selected. Reboot to see it.'
