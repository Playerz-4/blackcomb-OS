#!/usr/bin/env bash
# Add the Blackcomb setup kit to the official Ubuntu 26.10 installer ISO.
set -Eeuo pipefail
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ISO_URL=${UBUNTU_ISO_URL:-https://releases.ubuntu.com/26.10/ubuntu-26.10-desktop-amd64.iso}
OUTPUT_ISO=${OUTPUT_ISO:-$ROOT_DIR/blackcomb-26.10-amd64.iso}
WORK_DIR=${WORK_DIR:-$ROOT_DIR/.build}

usage() {
  cat <<'HELP'
Usage: ./scripts/build-iso.sh

Build a bootable Ubuntu 26.10 installer ISO with the Blackcomb post-install kit.
The live session and installer remain Ubuntu; install Plasma after installation.
UBUNTU_ISO      Existing official Ubuntu 26.10 desktop amd64 ISO, or download it.
UBUNTU_ISO_URL  Download URL if UBUNTU_ISO is unset.
ISO_SHA256      Expected input SHA-256 (strongly recommended).
OUTPUT_ISO      Output path (default: ./blackcomb-26.10-amd64.iso).
WORK_DIR        Temporary file directory (default: ./.build).
Requires xorriso, curl, and roughly 20 GB free. Root is not required.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($#)); then usage >&2; exit 2; fi
for cmd in xorriso curl sha256sum md5sum realpath; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
mkdir -p "$WORK_DIR" "$(dirname -- "$OUTPUT_ISO")"
work=$(mktemp -d "$WORK_DIR/blackcomb.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT

if [[ -n ${UBUNTU_ISO:-} ]]; then
  input=$(realpath -- "$UBUNTU_ISO")
  [[ -f $input ]] || { echo 'Input ISO not found.' >&2; exit 1; }
else
  input=$work/ubuntu.iso
  echo "Downloading $ISO_URL"
  curl --fail --location --retry 3 --output "$input" "$ISO_URL"
fi
[[ $(realpath -m -- "$OUTPUT_ISO") != "$input" ]] || { echo 'Input and output ISO must differ.' >&2; exit 1; }
if [[ -n ${ISO_SHA256:-} ]]; then
  printf '%s  %s\n' "$ISO_SHA256" "$input" | sha256sum --check --status || { echo 'Input ISO SHA-256 mismatch.' >&2; exit 1; }
else
  echo 'WARNING: input ISO is not checksum-verified. Set ISO_SHA256 to a trusted published hash.' >&2
fi

# Check the release before modifying anything; keep all layered filesystems,
# Ubuntu's installer, and its kernel and initramfs intact.
xorriso -osirrox on -indev "$input" \
  -extract /.disk/info "$work/ubuntu-info" \
  -extract /casper/install-sources.yaml "$work/install-sources.yaml" \
  -extract /md5sum.txt "$work/md5sum.txt"
grep -Eiq 'Ubuntu 26\.10' "$work/ubuntu-info" || { echo 'Expected the official Ubuntu 26.10 desktop ISO.' >&2; exit 1; }

mkdir -p "$work/payload/scripts" "$work/payload/backgrounds" "$work/payload/assets/branding"
install -m 755 "$ROOT_DIR/scripts/setup-blackcomb.sh" "$work/payload/setup-blackcomb.sh"
install -m 755 "$ROOT_DIR/scripts/blackcomb-wallpaper.sh" "$work/payload/scripts/blackcomb-wallpaper.sh"
install -m 755 "$ROOT_DIR/scripts/install-grub-background.sh" "$work/payload/scripts/install-grub-background.sh"
install -m 644 "$ROOT_DIR/scripts/blackcomb-wallpaper.desktop" "$work/payload/scripts/blackcomb-wallpaper.desktop"
install -m 644 "$ROOT_DIR"/backgrounds/*.png "$work/payload/backgrounds/"
install -m 644 "$ROOT_DIR"/assets/branding/*.png "$ROOT_DIR"/assets/branding/*.svg "$work/payload/assets/branding/"
install -m 644 "$ROOT_DIR/scripts/MEDIA-README.txt" "$work/payload/README.txt"
# The input ISO's checksum list remains valid; add the new payload entries.
(cd "$work" && mv payload blackcomb && find blackcomb -type f -print0 | sort -z | xargs -0 md5sum | sed 's|  blackcomb/|  ./blackcomb/|' >> md5sum.txt)

echo 'Writing installer media (Ubuntu live session and installer remain unchanged)...'
xorriso -indev "$input" -outdev "$OUTPUT_ISO" -boot_image any replay \
  -map "$work/blackcomb" /blackcomb \
  -map "$work/md5sum.txt" /md5sum.txt -commit
(cd "$(dirname -- "$OUTPUT_ISO")" && sha256sum "$(basename -- "$OUTPUT_ISO")") > "$OUTPUT_ISO.sha256"
echo "Done: $OUTPUT_ISO"
echo 'Install Ubuntu first, then run blackcomb/setup-blackcomb.sh from the media.'
