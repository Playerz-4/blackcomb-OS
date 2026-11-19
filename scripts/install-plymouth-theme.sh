#!/usr/bin/env bash
# Install a copy of Ubuntu's BGRT spinner with the Blackcomb logo.
set -Eeuo pipefail
usage() {
  cat <<'HELP'
Usage: sudo blackcomb-plymouth [--restore-ubuntu]

Install or refresh the Blackcomb Plymouth loading screen and initramfs.
--restore-ubuntu selects the original Ubuntu BGRT theme instead.
This affects the installed system, not the installer USB or the GRUB menu.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# > 1)) || [[ ${1:-} != '' && ${1:-} != --restore-ubuntu ]]; then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root using sudo.' >&2; exit 1; }
for cmd in update-alternatives update-initramfs; do
  command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 1; }
done
ubuntu_theme=/usr/share/plymouth/themes/bgrt/bgrt.plymouth
[[ -f $ubuntu_theme ]] || { echo 'Ubuntu BGRT Plymouth theme not found.' >&2; exit 1; }
if [[ ${1:-} == --restore-ubuntu ]]; then
  update-alternatives --set default.plymouth "$ubuntu_theme"
  update-initramfs -u -k all
  echo 'Ubuntu BGRT loading screen restored.'
  exit 0
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
creator=$here/create-plymouth-theme.sh
logo=$here/../assets/branding/blackcomb-boot-watermark.png
if [[ ! -f $creator ]]; then creator=/usr/local/lib/blackcomb/create-plymouth-theme.sh; fi
if [[ ! -f $logo ]]; then logo=/usr/share/blackcomb/branding/blackcomb-boot-watermark.png; fi
[[ -f $creator && -f $logo ]] || { echo 'Blackcomb theme files missing; run setup first.' >&2; exit 1; }
theme_dir=/usr/share/plymouth/themes/blackcomb
bash "$creator" "$ubuntu_theme" /usr/share/plymouth/themes/spinner "$logo" "$theme_dir"
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$theme_dir/blackcomb.plymouth" 80
update-alternatives --set default.plymouth "$theme_dir/blackcomb.plymouth"
update-initramfs -u -k all
echo 'Blackcomb Plymouth loading screen installed. Reboot to see it.'
