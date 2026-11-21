#!/usr/bin/env bash
# Blackcomb macOS helper: run native .app bundles and DMG images with Darling.
set -Eeuo pipefail

usage() {
  cat <<'HELP'
Usage: blackcomb-macos FILE [ARGS...]

Run native macOS software through Darling, an experimental macOS compatibility
layer for Linux. Supported inputs:
  .app directory    Native macOS application bundle
  .app / .zip / tar Archive containing a native .app bundle
  .dmg              macOS disk image; attaches it, copies out a .app and runs it
  .pkg              macOS installer package

Darling's graphical support is incomplete. Compatibility varies by app; check
https://appdb.darlinghq.org/ before expecting a specific program to work.
Use blackcomb-wine for Windows .exe/.msi files.

Options:
  --check     Show Darling status.
  --install   Install Darling from the official source release.
  --help      Show this help.
HELP
}

die() { printf 'blackcomb-macos: %s\n' "$*" >&2; exit 1; }

if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if [[ ${1:-} == --install ]]; then
  command -v blackcomb-install-darling >/dev/null 2>&1 || \
    die 'Darling installer not found. Run /usr/local/bin/blackcomb-install-darling.'
  exec blackcomb-install-darling --yes "${@:2}"
fi

darling_bin=${BLACKCOMB_DARLING:-darling}
prefix=${DPREFIX:-$HOME/.darling}
[[ $prefix == /* ]] || die 'DPREFIX must be an absolute path.'

require_darling() {
  command -v "$darling_bin" >/dev/null 2>&1 || \
    die 'Darling is not installed. Run "blackcomb-install-darling" or open Settings -> Install macOS App Support.'
}

init_prefix() {
  require_darling
  "$darling_bin" shell true >/dev/null 2>&1 || die 'Darling could not start; its prefix may be corrupt.'
  install -d "$prefix/Applications" "$prefix/blackcomb"
}

# Quote a value for the Bash 3.2 shell Darling uses inside the prefix.
shell_quote() {
  local value=${1//\'/\'\\\'\'}
  printf "'%s'" "$value"
}

absolute_path() {
  local dir base
  dir=$(cd -- "$(dirname -- "$1")" && pwd -P)
  base=$(basename -- "$1")
  printf '%s/%s\n' "$dir" "$base"
}

if [[ ${1:-} == --check ]]; then
  require_darling
  printf 'Darling command: %s\n' "$darling_bin"
  printf 'Darling prefix: %s\n' "$prefix"
  "$darling_bin" shell uname
  exit 0
fi

(( $# >= 1 )) || { usage >&2; exit 2; }

mac_executable() {
  local app=$1 plist="$1/Contents/Info.plist" exe= candidate
  if [[ -r $plist ]] && command -v python3 >/dev/null 2>&1; then
    exe=$(python3 - "$plist" <<'PY' 2>/dev/null || :
import plistlib
import sys

try:
    with open(sys.argv[1], "rb") as handle:
        value = plistlib.load(handle).get("CFBundleExecutable", "")
    if isinstance(value, str):
        print(value)
except Exception:
    pass
PY
    )
  fi
  if [[ -z $exe ]]; then
    for candidate in "$app"/Contents/MacOS/*; do
      [[ -f $candidate && -x $candidate ]] || continue
      exe=${candidate##*/}
      break
    done
  fi
  [[ -n $exe && $exe != */* && $exe != . && $exe != .. ]] || return 1
  printf '%s\n' "$exe"
}

wine_internal_name() {
  local base=${1##*/}
  base=${base%.*}
  case ${base,,} in
    wine|wine64|wine32|wineboot|winecfg|wineserver|wineshelllink|winepath|winegcc|start|cmd|msiexec|rundll32|regedit|notepad|explorer|iexplore)
      return 0 ;;
  esac
  return 1
}

find_windows_exe() {
  local app=$1 name=${1##*/} candidate largest= largest_size=0 exe size
  name=${name%.app}
  for candidate in "$app/Contents/Resources/$name.exe" "$app/Contents/MacOS/$name.exe"; do
    if [[ -f $candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  while IFS= read -r exe; do
    [[ -f $exe ]] || continue
    wine_internal_name "$exe" && continue
    size=$(wc -c < "$exe")
    if (( size > largest_size )); then
      largest=$exe
      largest_size=$size
    fi
  done < <(find "$app/Contents" -type f -iname '*.exe' 2>/dev/null)
  [[ -n $largest ]] || return 1
  printf '%s\n' "$largest"
}

copy_app_to_prefix() {
  local app=${1%/} name target src_real target_real=
  [[ -d $app/Contents ]] || die "Not a macOS .app bundle: $app"
  name=${app##*/}
  target="$prefix/Applications/$name"
  src_real=$(cd -- "$app" && pwd -P)
  if [[ -d $target ]]; then
    target_real=$(cd -- "$target" && pwd -P)
  fi
  if [[ $src_real != "$target_real" ]]; then
    rm -rf -- "$target"
    cp -R -- "$app" "$target"
  fi
  printf '%s\n' "$target"
}

run_app() {
  local app=$1 exe target name part run_script
  shift
  app=$(absolute_path "${app%/}")
  if ! exe=$(mac_executable "$app"); then
    if command -v blackcomb-wine >/dev/null 2>&1 && find_windows_exe "$app" >/dev/null; then
      printf 'Windows executable found in .app; handing off to blackcomb-wine.\n' >&2
      exec blackcomb-wine "$app" "$@"
    fi
    die 'Could not find a macOS executable or a Windows .exe in this .app bundle.'
  fi
  target=$(copy_app_to_prefix "$app")
  name=${target##*/}
  run_script="$prefix/blackcomb/run-app.sh"
  {
    printf '#!/bin/bash\nset -eu\n'
    printf 'exec'
    for part in "/Applications/$name/Contents/MacOS/$exe" "$@"; do
      printf ' %s' "$(shell_quote "$part")"
    done
    printf '\n'
  } > "$run_script"
  chmod +x "$run_script"
  "$darling_bin" shell /blackcomb/run-app.sh
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
  if tar -tf "$archive" >/dev/null 2>&1; then
    tar -tf "$archive" | safe_entries || return 1
    tar -xf "$archive" -C "$dest"
    return
  fi
  return 1
}

run_archive() {
  local archive app tmp
  archive=$(absolute_path "$1")
  shift
  [[ -f $archive ]] || die "Not a file: $archive"
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/blackcomb-macos.XXXXXXXX")
  # shellcheck disable=SC2064
  trap "rm -rf -- '$tmp'" EXIT
  extract_app_archive "$archive" "$tmp" || die "Could not extract an .app bundle from $archive"
  app=$(find "$tmp" -type d -iname '*.app' 2>/dev/null | head -n 1)
  [[ -n $app ]] || die "No .app bundle found in $archive"
  run_app "$app" "$@"
}

run_dmg() {
  local dmg=$1 output darling_app attach_script
  shift
  dmg=$(absolute_path "$dmg")
  [[ -f $dmg ]] || die "Not a DMG file: $dmg"
  attach_script="$prefix/blackcomb/attach-dmg.sh"
  cat > "$attach_script" <<EOF
#!/bin/bash
set -eu
dmg=$(shell_quote "$dmg")
mount=\$(hdiutil attach "\$dmg" | tail -n 1 | tr -d '\r')
case "\$mount" in /Volumes/*) ;; *) echo 'Could not mount the DMG.' >&2; exit 1 ;; esac
cleanup() { hdiutil detach "\$mount" >/dev/null 2>&1 || :; }
trap cleanup EXIT
app=
for candidate in "\$mount"/*.app "\$mount"/*/*.app; do
  if [[ -d \$candidate ]]; then app=\$candidate; break; fi
done
if [[ -z \$app ]]; then echo 'No .app bundle was found in the DMG.' >&2; exit 1; fi
name=\${app##*/}
rm -rf "/Applications/\$name"
cp -R "\$app" "/Applications/"
hdiutil detach "\$mount" >/dev/null
trap - EXIT
printf '%s\n' "/Applications/\$name"
EOF
  chmod +x "$attach_script"
  output=$("$darling_bin" shell /blackcomb/attach-dmg.sh)
  darling_app=$(printf '%s\n' "$output" | tail -n 1 | tr -d '\r')
  case $darling_app in
    /Applications/*.app) ;;
    *) die 'Darling did not report an installed .app from the DMG.' ;;
  esac
  run_app "$prefix$darling_app" "$@"
}

run_pkg() {
  local pkg=$1 install_script
  shift
  pkg=$(absolute_path "$pkg")
  [[ -f $pkg ]] || die "Not a PKG file: $pkg"
  cp -- "$pkg" "$prefix/blackcomb/install.pkg"
  install_script="$prefix/blackcomb/install-pkg.sh"
  cat > "$install_script" <<'EOF'
#!/bin/bash
set -eu
installer -pkg /blackcomb/install.pkg -target /
EOF
  chmod +x "$install_script"
  "$darling_bin" shell /blackcomb/install-pkg.sh
}

init_prefix
target=$1
shift
case ${target,,} in
  *.dmg)
    run_dmg "$target" "$@" ;;
  *.app)
    if [[ -d $target ]]; then
      run_app "$target" "$@"
    elif [[ -f $target ]]; then
      run_archive "$target" "$@"
    else
      die "Not a .app directory or archive: $target"
    fi ;;
  *.pkg)
    run_pkg "$target" "$@" ;;
  *.zip|*.tar|*.tar.gz|*.tgz|*.tar.xz|*.tar.bz2)
    run_archive "$target" "$@" ;;
  *)
    die 'Unsupported file type; use blackcomb-wine for Windows .exe/.msi files.' ;;
esac
