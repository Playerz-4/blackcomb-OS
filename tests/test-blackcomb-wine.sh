#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$root/scripts/blackcomb-wine.sh"
desktop="$root/scripts/blackcomb-wine.desktop"

[[ -f $script && -f $desktop ]] || { echo 'Missing Blackcomb Wine files' >&2; exit 1; }
grep -Fq 'wine winetricks cabextract unzip' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'scripts/blackcomb-wine.sh' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'scripts/blackcomb-wine.desktop' "$root/scripts/build-iso.sh"
grep -Fq 'scripts/blackcomb-wine.sh' "$root/scripts/build-iso.sh"
grep -Fxq 'Exec=blackcomb-wine %f' "$desktop"
grep -Fq 'MimeType=application/x-ms-dos-executable;' "$desktop"
grep -Fq 'application/x-msi=' "$desktop" || grep -Fq 'application/x-msi;' "$desktop"

# Standard Wine only: no Darling, macOS wrapper or .app code paths.
if grep -Eqi 'darling|macos|wineskin|\.app' "$script" "$desktop" "$root/scripts/setup-blackcomb.sh"; then
  echo 'macOS compatibility code is still present' >&2
  exit 1
fi
[[ ! -e $root/scripts/blackcomb-macos.sh ]] || { echo 'blackcomb-macos.sh still present' >&2; exit 1; }
[[ ! -e $root/scripts/install-darling.sh ]] || { echo 'install-darling.sh still present' >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/wine" <<'MOCK'
#!/usr/bin/env bash
set -eu
if [[ ${1:-} == --version ]]; then
  printf 'wine-11.20\n'
  exit 0
fi
printf '%s\n' "$*" >> "$WINE_LOG"
MOCK
chmod +x "$tmp/bin/wine"
export PATH="$tmp/bin:$PATH" WINE_LOG="$tmp/wine.log"

bash "$script" --check > "$tmp/check.out"
grep -Fxq 'wine-11.20' "$tmp/check.out"

printf 'exe payload' > "$tmp/Program.exe"
bash "$script" "$tmp/Program.exe" --option
grep -Fq "$tmp/Program.exe --option" "$WINE_LOG"

: > "$tmp/setup.msi"
bash "$script" "$tmp/setup.msi"
grep -Fq "msiexec /i $tmp/setup.msi" "$WINE_LOG"

printf 'echo hi' > "$tmp/run.bat"
bash "$script" "$tmp/run.bat"
grep -Fq "cmd /c $tmp/run.bat" "$WINE_LOG"

: > "$tmp/shortcut.lnk"
bash "$script" "$tmp/shortcut.lnk"
grep -Fq "start $tmp/shortcut.lnk" "$WINE_LOG"

echo 'Blackcomb Wine tests passed.'
