#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$root/scripts/blackcomb-wine.sh"
desktop="$root/scripts/blackcomb-wine.desktop"

[[ -f $script && -f $desktop ]] || { echo 'Missing Blackcomb Wine files' >&2; exit 1; }
grep -Fq 'wine winetricks cabextract unzip' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'scripts/blackcomb-wine.sh' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'scripts/blackcomb-wine.desktop' "$root/scripts/build-iso.sh"
grep -Fq 'blackcomb-wine.sh' "$root/scripts/build-update-bundle.sh"
grep -Fxq 'Exec=blackcomb-wine %f' "$desktop"
grep -Fq 'MimeType=application/x-ms-dos-executable;' "$desktop"
grep -Fq 'application/x-msi=' "$desktop" || grep -Fq 'application/x-msi;' "$desktop"
grep -Fq 'Wineskin-style .app directory' "$script"
grep -Fq 'native macOS Mach-O app' "$script"

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/app/Contents/Resources" "$tmp/native/Contents/MacOS" "$tmp/tarroot"
cat > "$tmp/bin/wine" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$WINE_LOG"
MOCK
chmod +x "$tmp/bin/wine"
export PATH="$tmp/bin:$PATH" WINE_LOG="$tmp/wine.log"

# A Wineskin wrapper must launch its embedded Windows executable.
printf 'windows payload' > "$tmp/app/Contents/Resources/TestApp.exe"
bash "$script" "$tmp/app" >/dev/null 2>&1
grep -Fq "$tmp/app/Contents/Resources/TestApp.exe" "$tmp/wine.log"

# MSI files go through msiexec.
: > "$tmp/setup.msi"
bash "$script" "$tmp/setup.msi" >/dev/null 2>&1
grep -Fq "msiexec /i $tmp/setup.msi" "$tmp/wine.log"

# A compressed Wineskin wrapper containing a .app bundle must also work.
cp -R "$tmp/app" "$tmp/tarroot/TestApp.app"
tar -czf "$tmp/wrapper.tar.gz" -C "$tmp/tarroot" TestApp.app
bash "$script" "$tmp/wrapper.tar.gz" >/dev/null 2>&1
grep -Fq 'TestApp.app/Contents/Resources/TestApp.exe' "$tmp/wine.log"

# A true Mach-O macOS app must be rejected clearly, not passed to Wine.
printf '#!/bin/sh\n' > "$tmp/native/Contents/MacOS/NativeApp"
chmod +x "$tmp/native/Contents/MacOS/NativeApp"
if bash "$script" "$tmp/native" > "$tmp/native.out" 2>&1; then
  echo 'Native macOS app was accepted by Wine' >&2
  exit 1
fi
grep -Fq 'native macOS Mach-O app' "$tmp/native.out"

echo 'Blackcomb Wine tests passed.'
