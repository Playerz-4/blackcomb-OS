#!/usr/bin/env bash
# Fail-closed compatibility check for an experimental Ubuntu 26.10 Ubiquity ISO.
set -Eeuo pipefail
usage() {
  cat <<'HELP'
Usage: ./scripts/check-ubiquity-iso.sh IMAGE.iso

Inspect a local Ubuntu 26.10 image for a single Ubiquity-compatible live
filesystem and Ubiquity's GTK frontend. This is a preliminary check, not an
installer or a boot test; it does not modify the ISO. Requires xorriso.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# != 1)); then usage >&2; exit 2; fi
command -v xorriso >/dev/null || { echo 'Missing dependency: xorriso' >&2; exit 1; }
[[ -f $1 ]] || { echo "ISO not found: $1" >&2; exit 1; }
input=$(realpath -- "$1")
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

# Metadata inspection alone cannot prove Ubiquity will boot or install safely.
if ! xorriso -osirrox on -indev "$input" \
    -extract /.disk/info "$work/info" \
    -extract /casper/filesystem.manifest "$work/manifest"; then
  echo 'Unable to read Ubuntu live-image metadata.' >&2
  exit 1
fi
if ! grep -Eiq 'Ubuntu 26\.10' "$work/info"; then
  echo 'Expected an Ubuntu 26.10-based image.' >&2
  exit 1
fi
# The official 26.10 desktop ISO uses multiple minimal.* layers. Ubiquity
# requires a separately rebuilt, single-filesystem image and its metadata.
if ! xorriso -indev "$input" -find /casper -name filesystem.squashfs -type f -print 2>/dev/null | grep -Fq '/casper/filesystem.squashfs'; then
  echo 'Not Ubiquity-ready: /casper/filesystem.squashfs is missing (a layered image must be rebuilt).' >&2
  exit 1
fi
if ! grep -Eq '^ubiquity([:[:space:]])' "$work/manifest" || \
   ! grep -Eq '^ubiquity-frontend-gtk([:[:space:]])' "$work/manifest"; then
  echo 'Not Ubiquity-ready: the live manifest does not list Ubiquity and its GTK frontend.' >&2
  exit 1
fi
printf '%s\n' 'Preliminary checks passed: single live filesystem and Ubiquity GTK packages found.'
printf '%s\n' 'This does NOT prove the image boots or installs correctly; test in a disposable VM.'
