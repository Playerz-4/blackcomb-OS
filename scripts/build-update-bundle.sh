#!/usr/bin/env bash
# Assemble the GitHub release asset consumed by blackcomb-update.
set -Eeuo pipefail
umask 022
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT=${1:-$ROOT_DIR/blackcomb-update.tar.gz}
for cmd in install tar sha256sum mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd" >&2; exit 1; }
done

work=$(mktemp -d "${TMPDIR:-/tmp}/blackcomb-update-bundle.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
stage="$work/blackcomb"
mkdir -p "$stage/scripts" "$stage/backgrounds" "$stage/assets/branding" \
  "$stage/themes/opencode" "$stage/themes/mountain/contents" "$stage/wallpapers"

install -m 755 "$ROOT_DIR/scripts/setup-blackcomb.sh" "$stage/setup-blackcomb.sh"
for script in blackcomb-wallpaper.sh blackcomb-launcher.sh install-grub-background.sh \
              create-plymouth-theme.sh install-plymouth-theme.sh blackcomb-update.sh blackcomb-wine.sh; do
  install -m 755 "$ROOT_DIR/scripts/$script" "$stage/scripts/$script"
done
for file in blackcomb-wallpaper.desktop blackcomb-launcher.desktop blackcomb-update.desktop \
            blackcomb-wine.desktop blackcomb-update.conf blackcomb-version mountain-lookandfeel.conf \
            neofetch.conf neofetch-ascii.conf; do
  install -m 644 "$ROOT_DIR/scripts/$file" "$stage/scripts/$file"
done
install -m 755 "$ROOT_DIR/third-party/neofetch/neofetch" "$stage/scripts/neofetch"
install -m 644 "$ROOT_DIR/third-party/neofetch/LICENSE.md" "$stage/scripts/neofetch-LICENSE.md"
install -m 644 "$ROOT_DIR/third-party/neofetch/README.md" "$stage/scripts/README.md"
install -m 644 "$ROOT_DIR/assets/branding/crescent-moon-neofetch.txt" "$stage/scripts/"
install -m 644 "$ROOT_DIR"/backgrounds/*.png "$stage/backgrounds/"
install -m 644 "$ROOT_DIR"/assets/branding/*.png "$ROOT_DIR"/assets/branding/*.svg "$stage/assets/branding/"
install -m 644 "$ROOT_DIR"/themes/opencode/*.colors "$ROOT_DIR/themes/opencode/README.md" "$stage/themes/opencode/"
for package in "$ROOT_DIR"/wallpapers/*; do
  [[ -d $package ]] || continue
  name=$(basename -- "$package")
  install -d "$stage/wallpapers/$name"
  install -m 644 "$package/metadata.json" "$stage/wallpapers/$name/"
done
install -m 644 "$ROOT_DIR/themes/mountain/metadata.json" "$stage/themes/mountain/"
install -m 644 "$ROOT_DIR/themes/mountain/contents/defaults" "$stage/themes/mountain/contents/"
install -m 644 "$ROOT_DIR/scripts/MEDIA-README.txt" "$stage/README.txt"

mkdir -p "$(dirname -- "$OUTPUT")"
temporary="$OUTPUT.tmp.$$"
tar -czf "$temporary" -C "$work" blackcomb
mv -f -- "$temporary" "$OUTPUT"
(cd "$(dirname -- "$OUTPUT")" && sha256sum "$(basename -- "$OUTPUT")" > "$(basename -- "$OUTPUT").sha256")
echo "Built $OUTPUT"
