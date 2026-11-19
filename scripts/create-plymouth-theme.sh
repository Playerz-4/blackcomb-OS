#!/usr/bin/env bash
# Copy the distribution's spinner assets and adapt its two-step config.
set -Eeuo pipefail
if (($# != 4)); then
  echo 'Usage: create-plymouth-theme.sh THEME_CONFIG SPINNER_DIR LOGO_PNG OUTPUT_DIR' >&2
  exit 2
fi
config=$1 spinner=$2 logo=$3 dest=$4
[[ -f $config && -d $spinner && -f $logo ]] || { echo 'Plymouth theme inputs are missing.' >&2; exit 1; }
[[ $dest = /* && $dest != / && $dest != "$spinner" && $dest != *$'\n'* ]] || { echo 'Invalid theme directory.' >&2; exit 1; }
[[ $(grep -c '^ImageDir=' "$config" || true) == 1 ]] || { echo 'Unexpected spinner theme: expected exactly one ImageDir.' >&2; exit 1; }
[[ $(grep -c '^ModuleName=two-step' "$config" || true) == 1 ]] || { echo 'Unexpected spinner theme: expected two-step module.' >&2; exit 1; }
mkdir -p "$dest"
# Distribution watermark files may be symlinks; never follow them when writing.
rm -f "$dest/watermark.png" "$dest/bgrt-fallback.png"
cp -a "$spinner/." "$dest/"
rm -f "$dest/watermark.png" "$dest/bgrt-fallback.png"
install -m 644 "$logo" "$dest/watermark.png"
install -m 644 "$logo" "$dest/bgrt-fallback.png"
awk -v image_dir="$dest" '
  /^ImageDir=/ {print "ImageDir=" image_dir; next}
  /^Name=/ {print "Name=Blackcomb"; next}
  {print}
' "$config" > "$dest/blackcomb.plymouth"
chmod 644 "$dest/blackcomb.plymouth"
