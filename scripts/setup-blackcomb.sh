#!/usr/bin/env bash
# Run on the installed system, not inside the live installer.
set -Eeuo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# The media places this script at the kit root; a checkout keeps it in scripts/.
if [[ ! -d $HERE/backgrounds && -d $HERE/../backgrounds ]]; then HERE=$(cd "$HERE/.." && pwd); fi
usage() {
  cat <<'HELP'
Usage: sudo ./setup-blackcomb.sh [--yes]

Install KDE Plasma, Firefox, everyday apps and Blackcomb artwork on Ubuntu 26.04.
This changes the default login manager to SDDM and installs the Blackcomb boot splash.
Internet access and a reboot are required. It does not remove the Ubuntu desktop.
The separate GRUB background and launcher icon must be enabled manually.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# > 1)) || [[ ${1:-} != '' && ${1:-} != --yes ]]; then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root using sudo.' >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo 'Cannot identify this system.' >&2; exit 1; }
. /etc/os-release
[[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 26.04 ]] || { echo 'This setup is intended only for installed Ubuntu 26.04.' >&2; exit 1; }
if grep -Eq '(^| )boot=casper( |$)' /proc/cmdline; then
  echo 'This appears to be the live session. Install Ubuntu and reboot first.' >&2
  exit 1
fi
for file in "$HERE/scripts/blackcomb-wallpaper.sh" "$HERE/scripts/blackcomb-wallpaper.desktop" "$HERE/scripts/install-grub-background.sh" "$HERE/scripts/install-plymouth-theme.sh" "$HERE/scripts/create-plymouth-theme.sh" "$HERE/backgrounds/blackcomb-midnight.png" "$HERE/backgrounds/kim-alpine.png" "$HERE/backgrounds/blackcomb-blue-hour.png" "$HERE/backgrounds/kim-stargazer.png" "$HERE/assets/branding/grub-background.png" "$HERE/assets/branding/blackcomb-launcher.svg" "$HERE/assets/branding/blackcomb-logo.png" "$HERE/assets/branding/blackcomb-boot-watermark.png"; do
  [[ -f $file ]] || { echo "Missing setup kit file: $file" >&2; exit 1; }
done
if [[ ${1:-} != --yes ]]; then
  printf 'This installs KDE Plasma, Firefox and everyday apps, changes the boot splash and switches to SDDM. Continue? [y/N] '
  read -r answer
  [[ $answer == y || $answer == Y || $answer == yes || $answer == YES ]] || exit 0
fi
export DEBIAN_FRONTEND=noninteractive
printf 'sddm shared/default-x-display-manager select sddm\n' | debconf-set-selections
apt-get update
# The Ubuntu desktop installer and the apps below are downloaded separately;
# these packages are not baked into the installer ISO.
apt-get install -y kubuntu-desktop plymouth-theme-spinner snapd
apt-get install -y --no-install-recommends vlc libreoffice-writer kcalc
# Ubuntu distributes Firefox as a snap. Avoid re-downloading it if already installed.
if ! snap list firefox >/dev/null 2>&1; then
  snap install firefox
fi
install -d /usr/share/backgrounds/blackcomb /usr/share/blackcomb/branding /usr/local/bin /usr/local/sbin /usr/local/lib/blackcomb /etc/xdg/autostart
install -m 644 "$HERE"/backgrounds/*.png /usr/share/backgrounds/blackcomb/
install -m 644 "$HERE"/assets/branding/*.png "$HERE"/assets/branding/*.svg /usr/share/blackcomb/branding/
install -m 755 "$HERE/scripts/blackcomb-wallpaper.sh" /usr/local/bin/blackcomb-wallpaper
install -m 755 "$HERE/scripts/install-grub-background.sh" /usr/local/sbin/blackcomb-grub-background
install -m 755 "$HERE/scripts/install-plymouth-theme.sh" /usr/local/sbin/blackcomb-plymouth
install -m 755 "$HERE/scripts/create-plymouth-theme.sh" /usr/local/lib/blackcomb/create-plymouth-theme.sh
install -m 644 "$HERE/scripts/blackcomb-wallpaper.desktop" /etc/xdg/autostart/
# Preserve Ubuntu's BGRT spinner while using Blackcomb's transparent logo.
/usr/local/sbin/blackcomb-plymouth
printf '/usr/bin/sddm\n' > /etc/X11/default-display-manager
systemctl enable --force sddm.service
printf '\nBlackcomb setup complete. Reboot and select a Plasma session at login.\n'
