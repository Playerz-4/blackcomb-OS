#!/usr/bin/env bash
# Run on the installed system, not inside the live installer.
set -Eeuo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# The media places this script at the kit root; a checkout keeps it in scripts/.
if [[ ! -d $HERE/backgrounds && -d $HERE/../backgrounds ]]; then HERE=$(cd "$HERE/.." && pwd); fi
usage() {
  cat <<'HELP'
Usage: sudo ./setup-blackcomb.sh [--yes]

Install KDE Plasma and Blackcomb artwork on an installed Ubuntu 26.10 system.
This changes the default login manager to SDDM and refreshes the Ubuntu boot splash.
Internet access and a reboot are required. It does not remove the Ubuntu desktop.
The separate GRUB background and launcher icon must be enabled manually.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# > 1)) || [[ ${1:-} != '' && ${1:-} != --yes ]]; then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root using sudo.' >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo 'Cannot identify this system.' >&2; exit 1; }
. /etc/os-release
[[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 26.10 ]] || { echo 'This setup is intended only for installed Ubuntu 26.10.' >&2; exit 1; }
if grep -Eq '(^| )boot=casper( |$)' /proc/cmdline; then
  echo 'This appears to be the live session. Install Ubuntu and reboot first.' >&2
  exit 1
fi
for file in "$HERE/scripts/blackcomb-wallpaper.sh" "$HERE/scripts/blackcomb-wallpaper.desktop" "$HERE/scripts/install-grub-background.sh" "$HERE/backgrounds/blackcomb-midnight.png" "$HERE/backgrounds/kim-alpine.png" "$HERE/backgrounds/blackcomb-blue-hour.png" "$HERE/backgrounds/kim-stargazer.png" "$HERE/assets/branding/grub-background.png" "$HERE/assets/branding/blackcomb-launcher.svg" "$HERE/assets/branding/blackcomb-logo.png"; do
  [[ -f $file ]] || { echo "Missing setup kit file: $file" >&2; exit 1; }
done
if [[ ${1:-} != --yes ]]; then
  printf 'This installs KDE Plasma and switches the login manager to SDDM. Continue? [y/N] '
  read -r answer
  [[ $answer == y || $answer == Y || $answer == yes || $answer == YES ]] || exit 0
fi
export DEBIAN_FRONTEND=noninteractive
printf 'sddm shared/default-x-display-manager select sddm\n' | debconf-set-selections
apt-get update
apt-get install -y kubuntu-desktop plymouth-theme-spinner
install -d /usr/share/backgrounds/blackcomb /usr/share/blackcomb/branding /usr/local/bin /usr/local/sbin /etc/xdg/autostart
install -m 644 "$HERE"/backgrounds/*.png /usr/share/backgrounds/blackcomb/
install -m 644 "$HERE"/assets/branding/*.png "$HERE"/assets/branding/*.svg /usr/share/blackcomb/branding/
install -m 755 "$HERE/scripts/blackcomb-wallpaper.sh" /usr/local/bin/blackcomb-wallpaper
install -m 755 "$HERE/scripts/install-grub-background.sh" /usr/local/sbin/blackcomb-grub-background
install -m 644 "$HERE/scripts/blackcomb-wallpaper.desktop" /etc/xdg/autostart/
# Choose the Ubuntu release's own Plymouth artwork rather than Kubuntu's.
theme=/usr/share/plymouth/themes/bgrt/bgrt.plymouth
[[ -f $theme ]] || { echo "Ubuntu Plymouth theme missing: $theme" >&2; exit 1; }
update-alternatives --set default.plymouth "$theme"
update-initramfs -u -k all
printf '/usr/bin/sddm\n' > /etc/X11/default-display-manager
systemctl enable --force sddm.service
printf '\nBlackcomb setup complete. Reboot and select a Plasma session at login.\n'
