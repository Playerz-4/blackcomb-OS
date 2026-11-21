#!/usr/bin/env bash
# Blackcomb Wine helper: run Windows apps and Wineskin-style macOS .app wrappers.
set -Eeuo pipefail

usage() {
  cat <<'HELP'
Usage: blackcomb-wine FILE [ARGS...]

Run Windows applications with the Fedora Wine package. Supported inputs:
  .exe / .com       Windows executable
  .msi              Windows installer (wine msiexec /i)
  .bat / .cmd       Windows batch file
  .lnk              Windows shortcut
  .app directory    Wineskin-style wrapper containing a Windows .exe
  .app / .zip / tar Wineskin wrapper archive containing a .app bundle

A true native macOS Mach-O app is not supported by Wine; the helper reports it
clearly instead of trying to run it.

Options:
  --check     Show the installed Wine and winetricks versions.
  --help      Show this help.
HELP
}

die() { printf 'blackcomb-wine: %s\n' "$*" >&2; exit 1; }

if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if [[ ${1:-} == --check ]]; then
  command -v wine >/dev/null 2>&1 || die 'Wine is not installed. Run: sudo dnf install wine winetricks'
  wine --version
  if command -v winetricks >/dev/null 2>&1; then
    printf 'winetricks: %s\n' "$(winetricks --version 2>/dev/null | head -n 1)"
  fi
  exit 0
fi
(( $# >= 1 )) || { usage >&2; exit 2; }

command -v wine >/dev/null 2>&1 || die 'Wine is not installed. Run: sudo dnf install wine winetricks'
for cmd in find mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || die "Missing dependency: $cmd"
done

target=$1
shift

is_wine_internal() {
  local base=${1##*/}
  base=${base%.*}
  case ${base,,} in
    wine|wine64|wine32|wineboot|winecfg|wineserver|wineshelllink|winepath|winegcc|start|cmd|msiexec|rundll32|regedit|notepad|explorer|iexplore)
      return 0 ;;
  esac
  return 1
}

find_app_exe() {
  local app=$1 name=${1##*/}
  name=${name%.app}
  local candidate largest= largest_size=0 exe size
  for candidate in "$app/Contents/Resources/$name.exe" "$app/Contents/MacOS/$name.exe"; do
    if [[ -f $candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  while IFS= read -r exe; do
    [[ -f $exe ]] || continue
    is_wine_internal "$exe" && continue
    size=$(wc -c < "$exe")
    if (( size > largest_size )); then
      largest=$exe
      largest_size=$size
    fi
  done < <(find "$app/Contents" -type f -iname '*.exe' 2>/dev/null)
  [[ -n $largest ]] || return 1
  printf '%s\n' "$largest"
}

native_macos_executable() {
  find "$1/Contents/MacOS" -maxdepth 1 -type f 2>/dev/null | head -n 1
}

run_app_bundle() {
  local app=$1 exe native
  [[ -d $app ]] || die "Not a Wineskin-style .app directory: $app"
  if exe=$(find_app_exe "$app"); then
    printf 'Running Windows executable from Wineskin bundle: %s\n' "$exe" >&2
    wine "$exe" "$@"
    return $?
  fi
  if native=$(native_macos_executable "$app") && [[ -n $native ]]; then
    if command -v blackcomb-macos >/dev/null 2>&1; then
      printf 'Native macOS app detected; handing off to blackcomb-macos (Darling).\n' >&2
      blackcomb-macos "$app" "$@"
      exit $?
    fi
    die 'This is a native macOS Mach-O app. Wine cannot run it; install Darling or use a virtual machine.'
  fi
  die 'No Windows .exe was found in this .app bundle.'
}

safe_entries() {
  local entry
  while IFS= read -r entry; do
    case $entry in
      /*|../*|*/../*|*/..) return 1 ;;
    esac
  done
}

extract_app_archive() {
  local archive=$1 dest=$2
  if command -v unzip >/dev/null 2>&1 && unzip -tqq "$archive" >/dev/null 2>&1; then
    unzip -Z1 "$archive" | safe_entries || return 1
    unzip -qq -o "$archive" -d "$dest" >/dev/null
    return
  fi
  if command -v tar >/dev/null 2>&1 && tar -tf "$archive" >/dev/null 2>&1; then
    tar -tf "$archive" | safe_entries || return 1
    tar -xf "$archive" -C "$dest"
    return
  fi
  return 1
}

find_app_in_tree() {
  find "$1" -type d -iname '*.app' 2>/dev/null | head -n 1
}

run_archive() {
  local archive=$1
  [[ -f $archive ]] || die "Not a file: $archive"
  local tmp app
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/blackcomb-wine.XXXXXXXX")
  # shellcheck disable=SC2064
  trap "rm -rf -- '$tmp'" EXIT
  extract_app_archive "$archive" "$tmp" || die "Could not extract Wineskin archive: $archive"
  app=$(find_app_in_tree "$tmp")
  [[ -n $app ]] || die "No .app bundle found in $archive"
  run_app_bundle "$app" "$@"
}

case ${target,,} in
  *.msi)
    wine msiexec /i "$target" "$@" ;;
  *.bat|*.cmd)
    wine cmd /c "$target" "$@" ;;
  *.lnk)
    wine start "$target" "$@" ;;
  *.app)
    if [[ -d $target ]]; then
      run_app_bundle "$target" "$@"
    elif [[ -f $target ]]; then
      run_archive "$target" "$@"
    else
      die "Not a .app bundle or archive: $target"
    fi
    ;;
  *.zip|*.tar|*.tar.gz|*.tgz|*.tar.xz|*.tar.bz2)
    run_archive "$target" "$@" ;;
  *)
    if [[ -d $target && -d $target/Contents ]]; then
      run_app_bundle "$target" "$@"
    else
      wine "$target" "$@"
    fi ;;
esac
