#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$root/scripts/blackcomb-macos.sh"
installer="$root/scripts/install-darling.sh"
desktop="$root/scripts/blackcomb-macos.desktop"
installer_desktop="$root/scripts/install-darling.desktop"

for file in "$script" "$installer" "$desktop" "$installer_desktop"; do
  [[ -f $file ]] || { echo "Missing macOS support file: $file" >&2; exit 1; }
done
grep -Fq 'hdiutil attach' "$script"
grep -Fq 'installer -pkg /blackcomb/install.pkg' "$script"
grep -Fq 'shell /blackcomb/run-app.sh' "$script"
grep -Fq 'handing off to blackcomb-wine' "$script"
grep -Fxq 'Exec=blackcomb-macos %f' "$desktop"
grep -Fq 'application/x-apple-diskimage;' "$desktop"
grep -Fq 'Exec=pkexec /usr/local/bin/blackcomb-install-darling --yes' "$installer_desktop"
grep -Fq 'darling-source.tar.xz' "$installer"
grep -Fq 'scripts/blackcomb-macos.sh' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'scripts/install-darling.sh' "$root/scripts/build-iso.sh"
grep -Fq 'application/x-apple-diskimage=blackcomb-macos.desktop' "$root/scripts/setup-blackcomb.sh"

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/prefix" "$tmp/Fixture.app/Contents/MacOS"
cat > "$tmp/bin/blackcomb-wine" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$WINE_HANDOFF_LOG"
MOCK
cat > "$tmp/bin/darling" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$DARLING_LOG"
case "$1 ${2:-}" in
  'shell true') exit 0 ;;
  'shell uname') printf 'Darwin\n'; exit 0 ;;
  'shell /blackcomb/run-app.sh')
    cat "$DPREFIX/blackcomb/run-app.sh" >> "$DARLING_LOG"
    exit 0 ;;
  'shell /blackcomb/install-pkg.sh')
    cat "$DPREFIX/blackcomb/install-pkg.sh" >> "$DARLING_LOG"
    exit 0 ;;
  'shell /blackcomb/attach-dmg.sh')
    cat "$DPREFIX/blackcomb/attach-dmg.sh" >> "$DARLING_LOG"
    name=${FAKE_DMG_APP##*/}
    rm -rf -- "$DPREFIX/Applications/$name"
    cp -R -- "$FAKE_DMG_APP" "$DPREFIX/Applications/$name"
    printf '/Volumes/FakeMount\n'
    printf '/Applications/%s\n' "$name"
    exit 0 ;;
  *)
    printf 'Unexpected Darling call: %s\n' "$*" >&2
    exit 1 ;;
esac
MOCK
chmod +x "$tmp/bin/darling" "$tmp/bin/blackcomb-wine"
export PATH="$tmp/bin:$PATH" DPREFIX="$tmp/prefix" DARLING_LOG="$tmp/darling.log" WINE_HANDOFF_LOG="$tmp/wine-handoff.log"
cat > "$tmp/Fixture.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>Fixture</string></dict></plist>
PLIST
printf '#!/bin/sh\nexit 0\n' > "$tmp/Fixture.app/Contents/MacOS/Fixture"
chmod +x "$tmp/Fixture.app/Contents/MacOS/Fixture"

bash "$script" --check > "$tmp/check.out"
grep -Fxq 'Darwin' "$tmp/check.out"

# A native .app is copied into the Darling prefix and launched from there.
bash "$script" "$tmp/Fixture.app" --flag 'two words'
test -x "$tmp/prefix/Applications/Fixture.app/Contents/MacOS/Fixture"
grep -Fq "'/Applications/Fixture.app/Contents/MacOS/Fixture' '--flag' 'two words'" "$DARLING_LOG"

# A DMG is attached through Darling's hdiutil, then its .app is launched.
: > "$tmp/Game.dmg"
FAKE_DMG_APP="$tmp/Fixture.app" bash "$script" "$tmp/Game.dmg"
grep -Fq 'hdiutil attach' "$DARLING_LOG"
grep -Fq 'hdiutil detach' "$DARLING_LOG"

# Archives containing .app bundles work too.
tar -czf "$tmp/App.app.tar.gz" -C "$tmp" Fixture.app
bash "$script" "$tmp/App.app.tar.gz"
grep -Fq "'/Applications/Fixture.app/Contents/MacOS/Fixture'" "$DARLING_LOG"

# macOS installer packages go through Darling's installer command.
: > "$tmp/Package.pkg"
bash "$script" "$tmp/Package.pkg"
grep -Fq 'installer -pkg /blackcomb/install.pkg -target /' "$DARLING_LOG"

# Wineskin-style .app wrappers handed to the macOS launcher go back to Wine.
mkdir -p "$tmp/Wrapper.app/Contents/Resources"
printf 'windows payload' > "$tmp/Wrapper.app/Contents/Resources/Wrapper.exe"
bash "$script" "$tmp/Wrapper.app" > "$tmp/wrapper.out" 2>&1
grep -Fq 'Wrapper.app' "$WINE_HANDOFF_LOG"
grep -Fq 'handing off to blackcomb-wine' "$tmp/wrapper.out"

echo 'Blackcomb macOS support tests passed.'
