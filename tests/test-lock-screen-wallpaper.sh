#!/usr/bin/env bash
# Verify Kim becomes the lock-screen/greeter default without replacing themes.
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

image='Image=file:///usr/share/backgrounds/blackcomb/kim-stargazer.png'
background='background=/usr/share/backgrounds/blackcomb/kim-stargazer.png'

mkdir -p "$tmp/root/etc/xdg" \
  "$tmp/root/etc/skel/.config" \
  "$tmp/root/usr/share/kde-settings/kde-profile/default/xdg" \
  "$tmp/root/home/liveuser/.config" \
  "$tmp/root/usr/share/sddm/themes/breeze"

cat > "$tmp/root/etc/plasmalogin.conf" <<'EOF'
[Autologin][seat0]
User=liveuser
Session=plasma.desktop

[Greeter]
WallpaperPluginId=org.kde.image

[Greeter][Wallpaper][org.kde.image][General]
Image=file:///usr/share/backgrounds/fedora/f45.png
PreviewImage=file:///usr/share/backgrounds/fedora/f45.png
EOF

for cfg in "$tmp/root/etc/xdg/kscreenlockerrc" \
           "$tmp/root/usr/share/kde-settings/kde-profile/default/xdg/kscreenlockerrc" \
           "$tmp/root/home/liveuser/.config/kscreenlockerrc"; do
  cat > "$cfg" <<'EOF'
[Daemon]
Timeout=10

[Greeter]
WallpaperPlugin=org.kde.image

[Greeter][Wallpaper][org.kde.image][General]
Image=file:///usr/share/backgrounds/fedora/f45.png
PreviewImage=file:///usr/share/backgrounds/fedora/f45.png
FillMode=2
EOF
done

cat > "$tmp/root/etc/sddm.conf" <<'EOF'
[Autologin]
User=nobody
Session=plasmawayland.desktop
EOF

cat > "$tmp/root/usr/share/sddm/themes/breeze/theme.conf" <<'EOF'
[General]
type=image
background=/usr/share/backgrounds/default.jxl
EOF
cp "$tmp/root/usr/share/sddm/themes/breeze/theme.conf" \
  "$tmp/root/usr/share/sddm/themes/breeze/theme.conf.user"

sh "$root/scripts/patch-lock-screen-wallpaper.sh" "$tmp/root" --live-autologin

grep -Fxq '[Autologin][seat0]' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq 'User=liveuser' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq 'Session=plasma.desktop' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq 'WallpaperPluginId=org.kde.image' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq "$image" "$tmp/root/etc/plasmalogin.conf"
grep -Fxq '[Autologin]' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq 'User=liveuser' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq 'Session=plasma.desktop' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq 'Relogin=true' "$tmp/root/etc/plasmalogin.conf"
grep -Fxq 'User=liveuser' "$tmp/root/etc/sddm.conf"
grep -Fxq 'Session=plasma.desktop' "$tmp/root/etc/sddm.conf"
grep -Fxq 'Timeout=10' "$tmp/root/etc/xdg/kscreenlockerrc"
grep -Fxq 'WallpaperPlugin=org.kde.image' "$tmp/root/etc/xdg/kscreenlockerrc"
grep -Fxq 'FillMode=2' "$tmp/root/etc/xdg/kscreenlockerrc"

for cfg in "$tmp/root/etc/plasmalogin.conf" \
           "$tmp/root/etc/xdg/kscreenlockerrc" \
           "$tmp/root/etc/skel/.config/kscreenlockerrc" \
           "$tmp/root/usr/share/kde-settings/kde-profile/default/xdg/kscreenlockerrc" \
           "$tmp/root/home/liveuser/.config/kscreenlockerrc"; do
  test -f "$cfg"
  grep -Fxq 'WallpaperPlugin=org.kde.image' "$cfg"
  grep -Fxq 'WallpaperPluginId=org.kde.image' "$cfg"
  grep -Fxq "$image" "$cfg"
  grep -Fxq "PreviewImage=file:///usr/share/backgrounds/blackcomb/kim-stargazer.png" "$cfg"
  if grep -qi 'fedora' "$cfg"; then
    echo "Fedora wallpaper survived in $cfg" >&2
    exit 1
  fi
done

theme="$tmp/root/usr/share/sddm/themes/breeze/theme.conf.user"
grep -Fxq 'type=image' "$theme"
grep -Fxq "$background" "$theme"
if grep -q 'default.jxl' "$theme"; then
  echo 'SDDM theme wallpaper was not replaced' >&2
  exit 1
fi
grep -Fxq 'background=/usr/share/backgrounds/default.jxl' \
  "$tmp/root/usr/share/sddm/themes/breeze/theme.conf"

# The explicit file mode is used for an installed user's own lock-screen config.
standalone="$tmp/user-kscreenlockerrc"
sh "$root/scripts/patch-lock-screen-wallpaper.sh" --file "$standalone"
grep -Fxq '[Greeter]' "$standalone"
grep -Fxq "$image" "$standalone"

cp -R "$tmp/root" "$tmp/before"
sh "$root/scripts/patch-lock-screen-wallpaper.sh" "$tmp/root"
diff -r "$tmp/before" "$tmp/root"

echo 'Lock-screen and greeter wallpaper tests passed.'
