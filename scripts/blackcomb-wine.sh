#!/usr/bin/env bash
# Blackcomb Wine helper: run standard Windows applications.
set -Eeuo pipefail

usage() {
  cat <<'HELP'
Usage: blackcomb-wine FILE [ARGS...]

Run Windows applications with the Fedora Wine package. Supported inputs:
  .exe / .com       Windows executable
  .msi              Windows installer (wine msiexec /i)
  .bat / .cmd       Windows batch file
  .lnk              Windows shortcut

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

target=$1
shift
[[ -e $target ]] || die "No such file: $target"

case ${target,,} in
  *.msi)
    wine msiexec /i "$target" "$@" ;;
  *.bat|*.cmd)
    wine cmd /c "$target" "$@" ;;
  *.lnk)
    wine start "$target" "$@" ;;
  *)
    wine "$target" "$@" ;;
esac
