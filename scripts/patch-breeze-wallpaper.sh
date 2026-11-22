#!/bin/sh
# Make a Kim wallpaper the default used by the standard Breeze global theme.
#
# Fedora's Breeze package contains [Wallpaper] Image=Fedora (or another Fedora
# default) in its defaults file. When Global Theme/Defaults is applied, Plasma
# puts that image back over the user's choice. This only changes that one value
# inside the existing Breeze package; no custom global theme or icon asset is
# created.
#
# Usage: patch-breeze-wallpaper.sh [target-root]
set -eu

root=${1:-/}
defaults="$root/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/defaults"
[ -f "$defaults" ] || exit 0

tmp="$defaults.blackcomb.tmp"
awk '
  /^\[Wallpaper\][[:space:]]*$/ {
    wallpaper = 1
    written = 0
    print
    next
  }
  /^\[/ {
    if (wallpaper && !written) {
      print "Image=kim-stargazer"
      written = 1
    }
    wallpaper = 0
    written = 0
    print
    next
  }
  wallpaper && /^[[:space:]]*Image[[:space:]]*=/ {
    if (!written) {
      print "Image=kim-stargazer"
      written = 1
    }
    next
  }
  { print }
  END {
    if (wallpaper && !written) {
      print "Image=kim-stargazer"
    }
  }
' "$defaults" > "$tmp" 2>/dev/null || {
  rm -f "$tmp"
  exit 0
}

# Preserve the existing file's mode and owner by rewriting its contents in place.
cat "$tmp" > "$defaults" 2>/dev/null || :
rm -f "$tmp"
exit 0
