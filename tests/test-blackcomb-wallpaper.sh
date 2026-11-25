#!/usr/bin/env bash
# Verify the Kim wallpaper default fix and the persistent wallpaper guard.
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

defaults_dir="$tmp/root/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents"
mkdir -p "$defaults_dir"
cat > "$defaults_dir/defaults" <<'EOF'
[kdeglobals][KDE]
widgetStyle=Breeze

[Wallpaper]
Image=Fedora

[ksplashrc][KSplash]
Theme=org.kde.breeze.desktop
EOF

sh "$root/scripts/patch-breeze-wallpaper.sh" "$tmp/root"
grep -Fxq 'Image=kim-stargazer' "$defaults_dir/defaults"
if grep -Fxq 'Image=Fedora' "$defaults_dir/defaults"; then
  echo 'Fedora wallpaper default was not replaced' >&2
  exit 1
fi
grep -Fxq 'widgetStyle=Breeze' "$defaults_dir/defaults"
grep -Fxq 'Theme=org.kde.breeze.desktop' "$defaults_dir/defaults"
cp "$defaults_dir/defaults" "$tmp/defaults.before"
sh "$root/scripts/patch-breeze-wallpaper.sh" "$tmp/root"
cmp "$defaults_dir/defaults" "$tmp/defaults.before"

helper="$root/scripts/blackcomb-wallpaper.sh"
grep -Fxq 'default_image=/usr/share/wallpapers/kim-stargazer' "$helper"
grep -Fq 'wallpaper-selection' "$helper"
grep -Fq 'BLACKCOMB_WALLPAPER_OK' "$helper"
grep -Fq 'set_image_config()' "$helper"
grep -Fq 'is_default_wallpaper()' "$helper"
grep -Fq 'set_image "$saved"' "$helper"
grep -Fq 'Keep a Kim wallpaper selected' "$root/scripts/blackcomb-wallpaper.desktop"
echo 'Kim wallpaper persistence tests passed.'
