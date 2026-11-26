#!/bin/sh
# dracut pre-pivot hook (run as 99-blackcomb-live.sh), after the live overlay
# is mounted. /sysroot is the mounted live root. Copy Blackcomb's session
# fixes into its writable overlay so the next systemd startup sees them.
#
# This is deliberately NOT a systemd unit and is not a switch-root dependency:
# it runs inside the existing dracut-pre-pivot.service and always returns 0, so
# a failed copy cannot block switch-root or drop the session into emergency
# mode. It is sourced by dracut, so use return rather than exit to avoid
# terminating dracut's init early. Every operation is best effort.
src=/usr/share/blackcomb/live
dst=/sysroot

[ -d "$src" ] || { return 0 2>/dev/null || exit 0; }
[ -d "$dst/etc" ] || { return 0 2>/dev/null || exit 0; }

mkdir -p "$dst/etc/systemd/system/plasmalogin.service.d" \
         "$dst/etc/systemd/system/sddm.service.d" \
         "$dst/etc/sddm.conf.d" \
         "$dst/etc/plasmalogin.conf.d" \
         "$dst/etc/skel/.config" \
         "$dst/etc/skel/.config/neofetch" \
         "$dst/home/liveuser/.config" \
         "$dst/home/liveuser/.config/neofetch" \
         "$dst/etc/xdg/autostart" \
         "$dst/etc/profile.d" \
         "$dst/etc/polkit-1/rules.d" \
         "$dst/usr/share/polkit-1/rules.d" \
         "$dst/var/lib/polkit-1/localauthority/50-local.d" \
         "$dst/home/liveuser/.config/plasma-workspace/env" \
         "$dst/usr/local/bin" \
         "$dst/usr/local/lib/blackcomb/neofetch" \
         "$dst/usr/share/backgrounds/blackcomb" \
         "$dst/usr/share/blackcomb/branding" \
         "$dst/usr/share/wallpapers" \
         "$dst/usr/share/plasma/plasmoids" \
         "$dst/usr/share/color-schemes" \
         "$dst/usr/share/kde-settings/kde-profile/default/xdg" 2>/dev/null || { return 0 2>/dev/null || exit 0; }

# Fedora 44+ KDE uses Plasma Login Manager; older media use SDDM. Both can
# start before Plymouth releases the DRM device (RHBZ 2404966). Wait only for
# plymouth-quit.service; plymouth-quit-wait.service is ordered after the
# display manager and would create a cycle. Drop-ins for absent units are
# ignored, so shipping both is harmless.
cp -f "$src/plasmalogin-wait.conf" \
  "$dst/etc/systemd/system/plasmalogin.service.d/10-blackcomb-wait.conf" 2>/dev/null || :
cp -f "$src/sddm-wait.conf" \
  "$dst/etc/systemd/system/sddm.service.d/10-blackcomb-wait.conf" 2>/dev/null || :

# Reinforce Fedora's runtime autologin in both display managers. PLM reads
# named [Autologin][seatN] groups separately from the main config, while older
# builds and SDDM only read the global group. livesys-late writes the main
# config before the display manager starts; the wait drop-in reapplies these
# settings with --live-autologin so no greeter password is ever requested.
cp -f "$src/plasmalogin-autologin.conf" \
  "$dst/etc/plasmalogin.conf.d/99-blackcomb-live.conf" 2>/dev/null || :
cp -f "$src/sddm-autologin.conf" \
  "$dst/etc/sddm.conf.d/99-blackcomb-live.conf" 2>/dev/null || :
cp -f "$src/plasmalogin-wallpaper.conf" \
  "$dst/etc/plasmalogin.conf.d/50-blackcomb-wallpaper.conf" 2>/dev/null || :

# Search Center's live web suggestions need KRunner's webshortcut runner and a
# default search provider. Write them as user defaults for liveuser, new users
# created by the installer, and the KDE profile used to seed home directories.
for config_dir in "$dst/home/liveuser/.config" \
                  "$dst/etc/skel/.config" \
                  "$dst/usr/share/kde-settings/kde-profile/default/xdg"; do
  mkdir -p "$config_dir" 2>/dev/null || :
  cp -f "$src/krunnerrc" "$config_dir/krunnerrc" 2>/dev/null || :
  cp -f "$src/kuriikwsfilterrc" "$config_dir/kuriikwsfilterrc" 2>/dev/null || :
done

# KWin in a VM: legacy DRM mode plus software cursor, per KDE's VirtualBox
# documentation. Also set from the kernel command line so the greeter inherits
# it; these copies cover the live user's Plasma session even if it is restarted.
cp -f "$src/kwin-vm-env.sh" "$dst/etc/profile.d/99-blackcomb-kwin-vm.sh" 2>/dev/null || :
cp -f "$src/kwin-vm-env.sh" \
  "$dst/home/liveuser/.config/plasma-workspace/env/99-blackcomb-kwin-vm.sh" 2>/dev/null || :

# VM display autostart. This keeps working when Plasma loads; the helper uses
# KScreen on Wayland and xrandr if an X11 session is ever present.
cp -f "$src/live-vm-display.sh" "$dst/usr/local/bin/blackcomb-vm-display" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-vm-display" 2>/dev/null || :
cp -f "$src/live-vm-display.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-vm-display.desktop" 2>/dev/null || :

# Keyboard/locale changes and the installer's pkexec helper need no root
# password on live media. Polkit uses the first matching rule, so 00- takes
# precedence over Fedora's packaged rules that would ask for authentication.
cp -f "$src/live-keyboard.rules" \
  "$dst/etc/polkit-1/rules.d/00-blackcomb-live-keyboard.rules" 2>/dev/null || :
cp -f "$src/live-keyboard.rules" \
  "$dst/usr/share/polkit-1/rules.d/00-blackcomb-live-keyboard.rules" 2>/dev/null || :
# Legacy pklocalauthority fallback for the same live-only actions.
cp -f "$src/live-keyboard.pkla" \
  "$dst/var/lib/polkit-1/localauthority/50-local.d/00-blackcomb-live-keyboard.pkla" 2>/dev/null || :

# Initial wallpaper for new live users and the PLM greeter. Copy every staged
# background so the live wallpaper picker has all Kim/Blackcomb images, not only
# the default stargazer image.
for bg in "$src"/*.png; do
  [ -e "$bg" ] || continue
  case "$(basename "$bg")" in
    crescent-moon-start-icon.png) continue ;;
  esac
  cp -f "$bg" "$dst/usr/share/backgrounds/blackcomb/" 2>/dev/null || :
done

# Register every image as a Plasma wallpaper package. Copying loose PNGs into
# /usr/share/backgrounds is not enough: Plasma 6's picker scans KPackages in
# /usr/share/wallpapers, so each staged metadata.json needs its image too.
for package in "$src/wallpapers"/*; do
  [ -d "$package" ] || continue
  [ -f "$package/metadata.json" ] || continue
  id=$(basename "$package")
  mkdir -p "$dst/usr/share/wallpapers/$id/contents/images" 2>/dev/null || :
  cp -f "$package/metadata.json" "$dst/usr/share/wallpapers/$id/" 2>/dev/null || :
  [ -f "$src/$id.png" ] || continue
  cp -f "$src/$id.png" "$dst/usr/share/wallpapers/$id/contents/images/$id.png" 2>/dev/null || :
  cp -f "$src/$id.png" "$dst/usr/share/wallpapers/$id/screenshot.png" 2>/dev/null || :
done

# Install Blackcomb's pure-QML Plasma applets as KPackages. Search Center is
# placed on a bottom-center panel by the launcher helper; this loop only makes
# the applet discoverable.
for package in "$src/applets"/*; do
  [ -d "$package" ] || continue
  [ -f "$package/metadata.json" ] || continue
  id=$(basename "$package")
  mkdir -p "$dst/usr/share/plasma/plasmoids/$id/contents/ui" 2>/dev/null || :
  cp -f "$package/metadata.json" "$dst/usr/share/plasma/plasmoids/$id/" 2>/dev/null || :
  for qml in "$package"/contents/ui/*.qml; do
    [ -f "$qml" ] || continue
    cp -f "$qml" "$dst/usr/share/plasma/plasmoids/$id/contents/ui/" 2>/dev/null || :
  done
done

# Keep the standard Breeze global theme, but make its advertised default
# wallpaper the Kim Stargazer package. Without this, applying Global Theme or
# Defaults inside the live session puts Fedora's wallpaper back over the user's
# Kim selection. This only edits Breeze's defaults file; no custom theme is used.
if [ -f "$src/patch-breeze-wallpaper.sh" ]; then
  sh "$src/patch-breeze-wallpaper.sh" "$dst" 2>/dev/null || :
fi

# Patch the main PLM config, kscreenlockerrc and SDDM theme overrides now, and
# install the script so the display-manager drop-in can reapply both the
# wallpaper and autologin settings after live setup finishes writing them.
cp -f "$src/patch-lock-screen-wallpaper.sh" \
  "$dst/usr/local/bin/blackcomb-lock-screen-wallpaper" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-lock-screen-wallpaper" 2>/dev/null || :
if [ -f "$dst/usr/local/bin/blackcomb-lock-screen-wallpaper" ]; then
  sh "$dst/usr/local/bin/blackcomb-lock-screen-wallpaper" "$dst" \
    --live-autologin 2>/dev/null || :
fi

# Install the desktop wallpaper helper and write its initial config directly.
# The autostart copy cannot fix a black desktop if Plasma never reaches the
# saved-layout stage, so the pre-pivot hook seeds every live config location.
cp -f "$src/blackcomb-wallpaper.sh" "$dst/usr/local/bin/blackcomb-wallpaper" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-wallpaper" 2>/dev/null || :
cp -f "$src/blackcomb-wallpaper.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-wallpaper.desktop" 2>/dev/null || :
if [ -f "$dst/usr/local/bin/blackcomb-wallpaper" ]; then
  for desktop_cfg in \
    "$dst/home/liveuser/.config/plasma-org.kde.plasma.desktop-appletsrc" \
    "$dst/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc" \
    "$dst/usr/share/kde-settings/kde-profile/default/xdg/plasma-org.kde.plasma.desktop-appletsrc"; do
    sh "$dst/usr/local/bin/blackcomb-wallpaper" --file "$desktop_cfg" 2>/dev/null || :
  done
fi

# Plasma application-launcher icon supplied with Blackcomb.
cp -f "$src/crescent-moon-start-icon.png" \
  "$dst/usr/share/blackcomb/branding/crescent-moon-start-icon.png" 2>/dev/null || :
cp -f "$src/blackcomb-launcher.sh" \
  "$dst/usr/local/bin/blackcomb-launcher" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/blackcomb-launcher" 2>/dev/null || :
cp -f "$src/blackcomb-launcher.desktop" \
  "$dst/etc/xdg/autostart/blackcomb-launcher.desktop" 2>/dev/null || :

# Plasma color schemes converted from OpenCode's built-in themes. All variants
# are available in System Settings; start the live session with Catppuccin.
for theme in "$src/themes"/*.colors; do
  [ -e "$theme" ] || continue
  cp -f "$theme" "$dst/usr/share/color-schemes/" 2>/dev/null || :
done
# neofetch shows the Blackcomb crescent image instead of the default Fedora
# ASCII art. Fedora 45 does not ship neofetch, so the wrapper and bundled script
# are installed here as well. chafa is not on the live media, so the wrapper
# falls back to the bundled ASCII rendering of the same PNG.
cp -f "$src/neofetch" "$dst/usr/local/lib/blackcomb/neofetch/neofetch" 2>/dev/null || :
chmod 755 "$dst/usr/local/lib/blackcomb/neofetch/neofetch" 2>/dev/null || :
for conf in chafa:neofetch.conf ascii:neofetch-ascii.conf; do
  name=${conf%%:*}
  file=${conf#*:}
  cp -f "$src/$file" \
    "$dst/usr/local/lib/blackcomb/neofetch/$name.conf" 2>/dev/null || :
done
cp -f "$src/crescent-moon-neofetch.txt" \
  "$dst/usr/local/lib/blackcomb/neofetch/crescent-moon-neofetch.txt" 2>/dev/null || :
cp -f "$src/neofetch-LICENSE.md" \
  "$dst/usr/local/lib/blackcomb/neofetch/LICENSE.md" 2>/dev/null || :
cp -f "$src/neofetch-launcher.sh" "$dst/usr/local/bin/neofetch" 2>/dev/null || :
chmod 755 "$dst/usr/local/bin/neofetch" 2>/dev/null || :
# Also give a packaged /usr/bin/neofetch the same settings if one is present.
for neofetch_dir in "$dst/home/liveuser/.config/neofetch" \
                    "$dst/etc/skel/.config/neofetch"; do
  cp -f "$src/neofetch.conf" "$neofetch_dir/config.conf" 2>/dev/null || :
done

# Start the live session with the standard Breeze global theme. The OpenCode
# Catppuccin color scheme changes colors without replacing Plasma components.
for config_dir in "$dst/home/liveuser/.config" "$dst/etc/skel/.config"; do
  mkdir -p "$config_dir" 2>/dev/null || :
  cat > "$config_dir/kdeglobals" <<'EOF' 2>/dev/null || :
[General]
ColorScheme=OpenCode-Catppuccin
fontSmoothing=2

[KDE]
LookAndFeelPackage=org.kde.breeze.desktop
widgetStyle=Breeze
EOF
  cat > "$config_dir/plasmarc" <<'EOF' 2>/dev/null || :
[Theme]
name=default
EOF
  cat > "$config_dir/kcminputrc" <<'EOF' 2>/dev/null || :
[Mouse]
cursorTheme=breeze_cursors
EOF
  cat > "$config_dir/kwinrc" <<'EOF' 2>/dev/null || :
[org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze
EOF
  cat > "$config_dir/ksplashrc" <<'EOF' 2>/dev/null || :
[KSplash]
Theme=org.kde.breeze.desktop
EOF
done

return 0 2>/dev/null || exit 0
