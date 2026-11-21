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
for file in "$HERE/scripts/blackcomb-wallpaper.sh" "$HERE/scripts/blackcomb-wallpaper.desktop" "$HERE/scripts/blackcomb-launcher.sh" "$HERE/scripts/blackcomb-launcher.desktop" "$HERE/scripts/install-grub-background.sh" "$HERE/scripts/install-plymouth-theme.sh" "$HERE/scripts/create-plymouth-theme.sh" "$HERE/backgrounds/kim-stargazer.png" "$HERE/assets/branding/grub-background.png" "$HERE/assets/branding/crescent-moon-start-icon.png" "$HERE/assets/branding/blackcomb-launcher.svg" "$HERE/assets/branding/blackcomb-boot-watermark.png" "$HERE/themes/opencode/OpenCode-Catppuccin.colors" "$HERE/wallpapers/kim-stargazer/metadata.json" "$HERE/themes/mountain/metadata.json" "$HERE/themes/mountain/contents/defaults" "$HERE/scripts/mountain-lookandfeel.conf" "$HERE/scripts/blackcomb-update.sh" "$HERE/scripts/blackcomb-update.desktop" "$HERE/scripts/blackcomb-update.conf" "$HERE/scripts/blackcomb-version" "$HERE/scripts/blackcomb-wine.sh" "$HERE/scripts/blackcomb-wine.desktop" "$HERE/scripts/blackcomb-macos.sh" "$HERE/scripts/blackcomb-macos.desktop" "$HERE/scripts/install-darling.sh" "$HERE/scripts/install-darling.desktop" "$HERE/scripts/neofetch.conf" "$HERE/scripts/neofetch-ascii.conf" "$HERE/scripts/neofetch-launcher.sh" "$HERE/scripts/neofetch" "$HERE/scripts/neofetch-LICENSE.md" "$HERE/assets/branding/crescent-moon-neofetch.txt"; do
  [[ -f $file ]] || { echo "Missing setup kit file: $file" >&2; exit 1; }
done
if [[ ${1:-} != --yes ]]; then
  printf 'Install Firefox and everyday apps, artwork and the Blackcomb boot splash? [y/N] '
  read -r answer
  [[ $answer == y || $answer == Y || $answer == yes || $answer == YES ]] || exit 0
fi
dnf install -y firefox vlc libreoffice-writer kcalc plymouth-theme-spinner chafa imagemagick curl tar python3 wine winetricks cabextract unzip
install -d /usr/share/backgrounds/blackcomb /usr/share/blackcomb/branding /usr/share/applications /usr/share/color-schemes /usr/share/wallpapers /usr/share/plasma/look-and-feel/com.blackcomb.mountain.desktop/contents/defaults /usr/share/plasma/look-and-feel/com.blackcomb.mountain.desktop/contents/previews /usr/local/bin /usr/local/sbin /usr/local/lib/blackcomb /usr/local/lib/blackcomb/neofetch /etc/xdg /etc/xdg/autostart /etc/skel/.config
install -m 644 "$HERE"/backgrounds/*.png /usr/share/backgrounds/blackcomb/

# Register each background as a Plasma wallpaper package. Loose PNGs are not
# listed in the wallpaper picker; Plasma 6 scans KPackages in /usr/share/wallpapers.
for package in "$HERE"/wallpapers/*; do
  [[ -d $package && -f $package/metadata.json ]] || continue
  name=${package##*/}
  install -d "/usr/share/wallpapers/$name/contents/images"
  install -m 644 "$package/metadata.json" "/usr/share/wallpapers/$name/"
  install -m 644 "$HERE/backgrounds/$name.png" \
    "/usr/share/wallpapers/$name/contents/images/$name.png"
  install -m 644 "$HERE/backgrounds/$name.png" \
    "/usr/share/wallpapers/$name/screenshot.png"
done

# Mountain is a Plasma global theme using Breeze's native components. It has
# no custom QML or SVG, so its appearance follows the active Plasma colors.
theme=/usr/share/plasma/look-and-feel/com.blackcomb.mountain.desktop
install -m 644 "$HERE/themes/mountain/metadata.json" "$theme/"
install -m 644 "$HERE/themes/mountain/contents/defaults" "$theme/contents/"
install -m 644 "$HERE/backgrounds/kim-stargazer.png" "$theme/contents/previews/preview.png"

install -m 644 "$HERE"/assets/branding/*.png "$HERE"/assets/branding/*.svg /usr/share/blackcomb/branding/
install -m 644 "$HERE"/themes/opencode/*.colors /usr/share/color-schemes/
install -m 755 "$HERE/scripts/blackcomb-wallpaper.sh" /usr/local/bin/blackcomb-wallpaper
install -m 755 "$HERE/scripts/blackcomb-launcher.sh" /usr/local/bin/blackcomb-launcher
install -m 755 "$HERE/scripts/install-grub-background.sh" /usr/local/sbin/blackcomb-grub-background
install -m 755 "$HERE/scripts/install-plymouth-theme.sh" /usr/local/sbin/blackcomb-plymouth
install -m 755 "$HERE/scripts/create-plymouth-theme.sh" /usr/local/lib/blackcomb/create-plymouth-theme.sh
install -m 644 "$HERE/scripts/blackcomb-wallpaper.desktop" /etc/xdg/autostart/
install -m 644 "$HERE/scripts/blackcomb-launcher.desktop" /etc/xdg/autostart/
install -m 755 "$HERE/scripts/neofetch" /usr/local/lib/blackcomb/neofetch/neofetch
install -m 644 "$HERE/scripts/neofetch.conf" /usr/local/lib/blackcomb/neofetch/chafa.conf
install -m 644 "$HERE/scripts/neofetch-ascii.conf" /usr/local/lib/blackcomb/neofetch/ascii.conf
install -m 644 "$HERE/assets/branding/crescent-moon-neofetch.txt" /usr/local/lib/blackcomb/neofetch/crescent-moon-neofetch.txt
install -m 644 "$HERE/scripts/neofetch-LICENSE.md" /usr/local/lib/blackcomb/neofetch/LICENSE.md
install -m 755 "$HERE/scripts/neofetch-launcher.sh" /usr/local/bin/neofetch

# Blackcomb Update appears under Settings and can also be run from a terminal.
install -m 755 "$HERE/scripts/blackcomb-update.sh" /usr/local/bin/blackcomb-update
install -m 644 "$HERE/scripts/blackcomb-update.desktop" /usr/share/applications/blackcomb-update.desktop
install -m 644 "$HERE/scripts/blackcomb-update.conf" /usr/local/lib/blackcomb/update.conf
install -m 644 "$HERE/scripts/blackcomb-version" /usr/local/lib/blackcomb/version

# Wine desktop integration. Fedora's wine.desktop no longer carries MIME types,
# so Blackcomb supplies its own launch action for Windows executables and a
# helper that also understands Wineskin-style macOS .app wrappers.
install -m 755 "$HERE/scripts/blackcomb-wine.sh" /usr/local/bin/blackcomb-wine
install -m 644 "$HERE/scripts/blackcomb-wine.desktop" /usr/share/applications/blackcomb-wine.desktop

# Native macOS .app/.dmg support is provided by Darling. The helper and its
# opt-in source installer are always installed; building Darling itself is
# optional because it is large and its GUI compatibility is still experimental.
install -m 755 "$HERE/scripts/blackcomb-macos.sh" /usr/local/bin/blackcomb-macos
install -m 644 "$HERE/scripts/blackcomb-macos.desktop" /usr/share/applications/blackcomb-macos.desktop
install -m 755 "$HERE/scripts/install-darling.sh" /usr/local/bin/blackcomb-install-darling
install -m 644 "$HERE/scripts/install-darling.desktop" /usr/share/applications/install-darling.desktop
printf '[Default Applications]\napplication/x-ms-dos-executable=blackcomb-wine.desktop\napplication/x-dosexec=blackcomb-wine.desktop\napplication/x-msi=blackcomb-wine.desktop\napplication/x-bat=blackcomb-wine.desktop\napplication/x-ms-shortcut=blackcomb-wine.desktop\napplication/x-apple-diskimage=blackcomb-macos.desktop\napplication/x-dmg=blackcomb-macos.desktop\napplication/vnd.apple.dmg=blackcomb-macos.desktop\napplication/x-macapplication=blackcomb-macos.desktop\napplication/x-apple-app=blackcomb-macos.desktop\napplication/x-apple-macos-pkg=blackcomb-macos.desktop\n' > /etc/xdg/mimeapps.list
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications >/dev/null 2>&1 || :
fi

# Start new users with Mountain and the matching OpenCode Catppuccin scheme.
# Mountain's package defaults do not set ColorScheme, so the active Plasma
# color scheme continues to control every themed element.
printf '[General]\nColorScheme=OpenCode-Catppuccin\nfontSmoothing=2\n\n[KDE]\nLookAndFeelPackage=com.blackcomb.mountain.desktop\nwidgetStyle=Breeze\n' > /etc/skel/.config/kdeglobals
printf '[Theme]\nname=default\n' > /etc/skel/.config/plasmarc
printf '[Mouse]\ncursorTheme=breeze_cursors\n' > /etc/skel/.config/kcminputrc
printf '[org.kde.kdecoration2]\nlibrary=org.kde.breeze\ntheme=Breeze\n' > /etc/skel/.config/kwinrc
printf '[KSplash]\nTheme=org.kde.breeze.desktop\n' > /etc/skel/.config/ksplashrc
if [[ -n ${SUDO_USER:-} && $SUDO_USER != root ]]; then
  user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  if [[ -n $user_home && -d $user_home ]]; then
    install -d -o "$SUDO_USER" -g "$(id -gn "$SUDO_USER")" "$user_home/.config"
    if command -v kwriteconfig6 >/dev/null 2>&1 && command -v runuser >/dev/null 2>&1; then
      set_user_config() {
        runuser -u "$SUDO_USER" -- kwriteconfig6 \
          --file "$1" --group "$2" --key "$3" "$4" || :
      }
      set_user_config kdeglobals General ColorScheme OpenCode-Catppuccin
      set_user_config kdeglobals General fontSmoothing 2
      set_user_config kdeglobals KDE LookAndFeelPackage com.blackcomb.mountain.desktop
      set_user_config kdeglobals KDE widgetStyle Breeze
      set_user_config plasmarc Theme name default
      set_user_config kcminputrc Mouse cursorTheme breeze_cursors
      set_user_config kwinrc org.kde.kdecoration2 library org.kde.breeze
      set_user_config kwinrc org.kde.kdecoration2 theme Breeze
      set_user_config ksplashrc KSplash Theme org.kde.breeze.desktop
    fi
  fi
fi

# Native macOS support is opt-in: Darling has no Fedora 45 package and must be
# built from its official source release. BLACKCOMB_INSTALL_DARLING=1 enables
# this in unattended installs; the interactive prompt defaults to no.
if [[ ${BLACKCOMB_INSTALL_DARLING:-0} == 1 ]]; then
  /usr/local/bin/blackcomb-install-darling --yes || \
    echo 'Warning: Darling installation failed; blackcomb-macos is installed but needs Darling.' >&2
elif [[ ${1:-} != --yes ]]; then
  printf 'Build and install experimental native macOS app support (Darling)? [y/N] '
  read -r answer
  if [[ $answer == y || $answer == Y || $answer == yes || $answer == YES ]]; then
    /usr/local/bin/blackcomb-install-darling --yes || \
      echo 'Warning: Darling installation failed; blackcomb-macos is installed but needs Darling.' >&2
  fi
fi

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
