#!/usr/bin/env bash
# Install Darling from its official source release for native macOS app support.
set -Eeuo pipefail

usage() {
  cat <<'HELP'
Usage: blackcomb-install-darling [--yes]

Build and install Darling, the experimental macOS compatibility layer used by
blackcomb-macos for native .app, .dmg and .pkg files. Fedora has no packaged
Darling build, so this downloads the official source release from GitHub and
compiles it locally. The build is large and can take a long time.

Options:
  --yes   Do not ask for confirmation.
  --help  Show this help.
HELP
}

die() { printf 'blackcomb-install-darling: %s\n' "$*" >&2; exit 1; }

if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi

if command -v darling >/dev/null 2>&1; then
  printf 'Darling is already installed: %s\n' "$(command -v darling)"
  exit 0
fi

if (( EUID != 0 )); then
  if command -v pkexec >/dev/null 2>&1; then
    exec pkexec "$0" "$@"
  fi
  die 'This installer needs root. Run it with sudo or from the Settings launcher.'
fi

[[ -r /etc/os-release ]] || die 'Cannot identify this Linux distribution.'
# shellcheck disable=SC1091
. /etc/os-release
[[ ${ID:-} == fedora && ${VERSION_ID:-} == 45 ]] || \
  die 'This installer targets Fedora 45.'

if [[ ${1:-} != --yes ]]; then
  printf 'Build and install Darling from source? This needs several GB of disk space and can take a long time. [y/N] '
  read -r answer
  [[ $answer == y || $answer == Y || $answer == yes || $answer == YES ]] || exit 0
fi

command -v dnf >/dev/null 2>&1 || die 'DNF is required to install Darling build dependencies.'

deps=(cmake make clang bison flex dbus-devel glibc-devel fuse-devel fuse
      systemd-devel elfutils-libelf-devel cairo-devel freetype-devel
      libjpeg-turbo-devel fontconfig-devel libglvnd-devel mesa-libGL-devel
      mesa-libEGL-devel mesa-libGLU-devel libtiff-devel libxml2-devel libbsd-devel
      git libXcursor-devel libXrandr-devel giflib-devel pulseaudio-libs-devel
      libxkbfile-devel openssl-devel llvm libcap-devel libavcodec-free-devel
      libavformat-free-devel curl tar xz python3)
if [[ ${DARLING_32BIT:-0} == 1 ]]; then
  deps+=(glibc-devel.i686 freetype-devel.i686 libjpeg-turbo-devel.i686
         fontconfig-devel.i686 libglvnd-devel.i686 mesa-libGL-devel.i686
         mesa-libEGL-devel.i686 mesa-libGLU-devel.i686)
fi
dnf install -y "${deps[@]}"

work=$(mktemp -d "${TMPDIR:-/tmp}/blackcomb-darling.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT

tag=${DARLING_VERSION:-}
source_url=${DARLING_SOURCE_URL:-}
source_sha=${DARLING_SOURCE_SHA256:-}
if [[ -z $source_url ]]; then
  release_json=$(curl --silent --show-error --fail --location \
    --header 'Accept: application/vnd.github+json' \
    https://api.github.com/repos/darlinghq/darling/releases/latest)
  mapfile -t release_fields < <(printf '%s\n' "$release_json" | python3 -c '
import json
import sys

release = json.load(sys.stdin)
asset = next((item for item in release.get("assets", [])
              if item.get("name") == "darling-source.tar.xz"), None)
if asset is None:
    raise SystemExit("Darling source asset not found")
print(release.get("tag_name", ""))
print(asset.get("browser_download_url", ""))
print(asset.get("digest", "") or "")
')
  [[ ${#release_fields[@]} -eq 3 ]] || die 'Could not read the Darling release metadata.'
  for index in "${!release_fields[@]}"; do
    release_fields[$index]=${release_fields[$index]%$'\r'}
  done
  [[ -n ${release_fields[0]} && -n ${release_fields[1]} ]] || die 'Darling release metadata is incomplete.'
  tag=${tag:-${release_fields[0]}}
  source_url=${release_fields[1]}
  source_sha=${source_sha:-${release_fields[2]}}
fi
[[ -n $source_url ]] || die 'No Darling source URL was provided.'

printf 'Downloading Darling %s...\n' "${tag:-latest}"
curl --silent --show-error --fail --location --retry 3 \
  --output "$work/darling-source.tar.xz" "$source_url"

if [[ -n $source_sha ]]; then
  expected=${source_sha#sha256:}
  actual=$(sha256sum "$work/darling-source.tar.xz" | awk '{print $1}')
  [[ $actual == "$expected" ]] || die 'Darling source checksum mismatch.'
fi

src="/usr/local/src/darling-${tag:-custom}"
build="/usr/local/src/darling-build-${tag:-custom}"
rm -rf -- "$src" "$build"
mkdir -p "$src" /usr/local/src
tar -xJf "$work/darling-source.tar.xz" -C "$src" --strip-components=1

cmake_args=(-S "$src" -B "$build")
if [[ ${DARLING_32BIT:-0} != 1 ]]; then
  cmake_args+=(-DTARGET_i386=OFF)
fi
printf 'Configuring Darling...\n'
cmake "${cmake_args[@]}"
printf 'Building Darling with %s jobs...\n' "$(nproc)"
cmake --build "$build" --parallel "$(nproc)"
printf 'Installing Darling...\n'
cmake --install "$build"

printf '\nDarling installed. Check it with "blackcomb-macos --check".\n'
printf 'Graphical support is experimental; compatibility details: https://appdb.darlinghq.org/\n'
