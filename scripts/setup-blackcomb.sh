#!/usr/bin/env bash
# Run on the installed Fedora KDE system, not inside the live installer.
set -Eeuo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ! -d $HERE/backgrounds && -d $HERE/../backgrounds ]]; then HERE=$(cd "$HERE/.." && pwd); fi
usage() {
  cat <<'HELP'
Usage: sudo ./setup-blackcomb.sh [--yes]

Install Firefox, everyday apps and Blackcomb artwork on installed Fedora 45 KDE.
This also installs a Blackcomb Plymouth boot splash. Internet and a reboot are
required. The GRUB background remains a separate manual choice.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# > 1)) || [[ ${1:-} != '' && ${1:-} != --yes ]]; then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root using sudo.' >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo 'Cannot identify this system.' >&2; exit 1; }
. /etc/os-release
[[ ${ID:-} == fedora && ${VERSION_ID:-} == 45 ]] || { echo 'This setup is intended only for installed Fedora 45.' >&2; exit 1; }
if grep -Eq '(^|[[:space:]])(root=live:|rd.live.image)' /proc/cmdline; then
  echo 'This appears to be the live session. Install Fedora and reboot first.' >&2
  exit 1
fi
command -v dnf >/dev/null || { echo 'DNF is required; this script is for standard Fedora KDE, not an immutable variant.' >&2; exit 1; }
for file in "$HERE/scripts/blackcomb-wallpaper.sh" "$HERE/scripts/blackcomb-wallpaper.desktop" "$HERE/scripts/blackcomb-launcher.sh" "$HERE/scripts/blackcomb-launcher.desktop" "$HERE/scripts/install-grub-background.sh" "$HERE/scripts/install-plymouth-theme.sh" "$HERE/scripts/create-plymouth-theme.sh" "$HERE/backgrounds/kim-stargazer.png" "$HERE/assets/branding/grub-background.png" "$HERE/assets/branding/blackcomb-launcher.png" "$HERE/assets/branding/blackcomb-launcher.svg" "$HERE/assets/branding/blackcomb-boot-watermark.png"; do
  [[ -f $file ]] || { echo "Missing setup kit file: $file" >&2; exit 1; }
done
if [[ ${1:-} != --yes ]]; then
  printf 'Install Firefox and everyday apps, artwork and the Blackcomb boot splash? [y/N] '
  read -r answer
  [[ $answer == y || $answer == Y || $answer == yes || $answer == YES ]] || exit 0
fi
dnf install -y firefox vlc libreoffice-writer kcalc plymouth-theme-spinner
install -d /usr/share/backgrounds/blackcomb /usr/share/blackcomb/branding /usr/local/bin /usr/local/sbin /usr/local/lib/blackcomb /etc/xdg/autostart
install -m 644 "$HERE"/backgrounds/*.png /usr/share/backgrounds/blackcomb/
install -m 644 "$HERE"/assets/branding/*.png "$HERE"/assets/branding/*.svg /usr/share/blackcomb/branding/
install -m 755 "$HERE/scripts/blackcomb-wallpaper.sh" /usr/local/bin/blackcomb-wallpaper
install -m 755 "$HERE/scripts/blackcomb-launcher.sh" /usr/local/bin/blackcomb-launcher
install -m 755 "$HERE/scripts/install-grub-background.sh" /usr/local/sbin/blackcomb-grub-background
install -m 755 "$HERE/scripts/install-plymouth-theme.sh" /usr/local/sbin/blackcomb-plymouth
install -m 755 "$HERE/scripts/create-plymouth-theme.sh" /usr/local/lib/blackcomb/create-plymouth-theme.sh
install -m 644 "$HERE/scripts/blackcomb-wallpaper.desktop" /etc/xdg/autostart/
install -m 644 "$HERE/scripts/blackcomb-launcher.desktop" /etc/xdg/autostart/
/usr/local/sbin/blackcomb-plymouth

# Fedora 42+ starts Plymouth on the early EFI framebuffer (simpledrm), which
# can keep a /dev/dri/card device busy while SDDM/KWin starts and leave the
# Plasma desktop black (Red Hat bug 2404966). Keep "rhgb" so the Blackcomb
# splash is still shown, but ask Plymouth to wait for the real GPU driver
# instead. This is Fedora's documented plymouth.use-simpledrm=0 switch.
if command -v grubby >/dev/null 2>&1; then
  if ! grubby --update-kernel=ALL --args="plymouth.use-simpledrm=0"; then
    echo 'Warning: could not apply the Plymouth DRM fix to the installed kernels.' >&2
  fi
fi
printf '\nBlackcomb setup complete. Reboot to use the new boot splash.\n'
