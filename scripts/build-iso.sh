#!/usr/bin/env bash
# Add the Blackcomb post-install kit to Fedora KDE's live installer media.
set -Eeuo pipefail
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ISO_URL=${FEDORA_ISO_URL:-https://download.fedoraproject.org/pub/fedora/linux/releases/45/KDE/x86_64/iso/Fedora-KDE-Desktop-Live-45-1.4.x86_64.iso}
OUTPUT_ISO=${OUTPUT_ISO:-$ROOT_DIR/blackcomb-fedora-45-x86_64.iso}
WORK_DIR=${WORK_DIR:-$ROOT_DIR/.build}
EROFS_COMPRESSION_LEVEL=${EROFS_COMPRESSION_LEVEL:-9}
# Published by Fedora for this exact image. Override only with a trusted checksum.
ISO_SHA256=${ISO_SHA256:-79703d9f3b21a4f7873f2874ec129d6511cb00a08532d8f9b36daacaa96e97a5}
usage() {
  cat <<'HELP'
Usage: ./scripts/build-iso.sh

Recompress Fedora 45 KDE's live filesystem and add the Blackcomb setup kit.
The live desktop and Fedora's Anaconda installer are not otherwise customized.
FEDORA_ISO              Path to the Fedora 45 KDE x86_64 ISO (otherwise download).
FEDORA_ISO_URL          Override download URL.
ISO_SHA256              Trusted input SHA-256 (defaults to Fedora 45-1.4 hash).
EROFS_COMPRESSION_LEVEL LZMA level 0-9 (default: 9).
OUTPUT_ISO              Output path (default: ./blackcomb-fedora-45-x86_64.iso).
WORK_DIR                Temporary directory (default: ./.build).
Requires root, loop mounting support, xorriso, curl, isomd5sum, rsync,
erofs-utils with LZMA support, and ample disk space.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($#)); then usage >&2; exit 2; fi
[[ $EUID == 0 ]] || { echo 'Run as root for the read-only EROFS loop mount.' >&2; exit 1; }
for cmd in xorriso curl sha256sum realpath implantisomd5 checkisomd5 mkfs.erofs fsck.erofs mount mountpoint umount rsync; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
[[ $EROFS_COMPRESSION_LEVEL =~ ^[0-9]$ ]] || { echo 'EROFS_COMPRESSION_LEVEL must be 0-9.' >&2; exit 1; }
mkdir -p "$WORK_DIR" "$(dirname -- "$OUTPUT_ISO")"
work=$(mktemp -d "$WORK_DIR/blackcomb.XXXXXXXX")
cleanup() {
  local dir failed=0
  for dir in "$work/new-root" "$work/live-root"; do
    if mountpoint -q "$dir" && ! umount "$dir"; then
      echo "Could not unmount $dir; leaving work directory intact." >&2
      failed=1
    fi
  done
  ((failed == 0)) || return 1
  rm -rf -- "$work"
}
trap cleanup EXIT
if [[ -n ${FEDORA_ISO:-} ]]; then
  input=$(realpath -- "$FEDORA_ISO")
  [[ -f $input ]] || { echo 'Input ISO not found.' >&2; exit 1; }
else
  input=$work/fedora.iso
  echo "Downloading $ISO_URL"
  curl --silent --show-error --fail --location --retry 3 --output "$input" "$ISO_URL"
fi
[[ $(realpath -m -- "$OUTPUT_ISO") != "$input" ]] || { echo 'Input and output ISO must differ.' >&2; exit 1; }
[[ $ISO_SHA256 =~ ^[[:xdigit:]]{64}$ ]] || { echo 'Invalid ISO_SHA256.' >&2; exit 1; }
printf '%s  %s\n' "$ISO_SHA256" "$input" | sha256sum --check --status || { echo 'Input ISO SHA-256 mismatch.' >&2; exit 1; }
# Do not change the ISO volume ID: dracut's root=live:CDLABEL refers to it.
xorriso -indev "$input" -pvd_info > "$work/pvd-info" 2>&1
grep -Fq 'Fedora-KDE-Live-45' "$work/pvd-info" || { echo 'Expected Fedora 45 KDE live media volume label.' >&2; exit 1; }
# Fedora 45's historic squashfs.img name contains an EROFS filesystem. Mount
# the original read-only rather than extracting files: this preserves metadata
# such as ownership, hardlinks, capabilities, SELinux labels and other xattrs.
# mkfs.erofs rebuild mode cannot import already-compressed EROFS files.
xorriso -osirrox on -indev "$input" -extract /LiveOS/squashfs.img "$work/original.erofs"
echo 'Checking the original Fedora live filesystem...'
fsck.erofs --extract "$work/original.erofs"
original_size=$(stat -c %s "$work/original.erofs")
mkdir "$work/live-root" "$work/new-root"
mount -t erofs -o loop,ro "$work/original.erofs" "$work/live-root"
# Without --quiet, mkfs writes a progress message for every file, overwhelming
# CI logs. Errors remain visible and a nonzero exit still stops the build.
echo 'Recompressing the live filesystem (this may take a long time; per-file output is disabled)...'
mkfs.erofs --quiet -zlzma,"$EROFS_COMPRESSION_LEVEL" -C1048576 \
  -Eall-fragments,fragdedupe=inode "$work/compressed.erofs" "$work/live-root"
echo 'Checking the recompressed filesystem...'
fsck.erofs --extract "$work/compressed.erofs"
# Verify readable content and metadata before accepting the replacement image.
echo 'Comparing live filesystem contents and metadata...'
mount -t erofs -o loop,ro "$work/compressed.erofs" "$work/new-root"
rsync -aHAXnc --delete --numeric-ids --itemize-changes \
  "$work/live-root/" "$work/new-root/" > "$work/differences"
if [[ -s $work/differences ]]; then
  echo 'Recompressed filesystem differs from the original:' >&2
  head -100 "$work/differences" >&2
  exit 1
fi
umount "$work/new-root"
umount "$work/live-root"
compressed_size=$(stat -c %s "$work/compressed.erofs")
echo "Live filesystem: $original_size bytes -> $compressed_size bytes"
rm -f "$work/original.erofs"
mkdir -p "$work/blackcomb/scripts" "$work/blackcomb/backgrounds" "$work/blackcomb/assets/branding"
install -m 755 "$ROOT_DIR/scripts/setup-blackcomb.sh" "$work/blackcomb/setup-blackcomb.sh"
for script in blackcomb-wallpaper.sh install-grub-background.sh create-plymouth-theme.sh install-plymouth-theme.sh; do
  install -m 755 "$ROOT_DIR/scripts/$script" "$work/blackcomb/scripts/$script"
done
install -m 644 "$ROOT_DIR/scripts/blackcomb-wallpaper.desktop" "$work/blackcomb/scripts/"
install -m 644 "$ROOT_DIR"/backgrounds/*.png "$work/blackcomb/backgrounds/"
install -m 644 "$ROOT_DIR"/assets/branding/*.png "$ROOT_DIR"/assets/branding/*.svg "$work/blackcomb/assets/branding/"
install -m 644 "$ROOT_DIR/scripts/MEDIA-README.txt" "$work/blackcomb/README.txt"
echo 'Writing Fedora installer media with the Blackcomb kit...'
xorriso -indev "$input" -outdev "$OUTPUT_ISO" -boot_image any replay \
  -map "$work/compressed.erofs" /LiveOS/squashfs.img \
  -map "$work/blackcomb" /blackcomb -commit
# Fedora's boot-time media check uses the embedded ISO checksum, not a sidecar.
implantisomd5 --force "$OUTPUT_ISO"
checkisomd5 "$OUTPUT_ISO"
(cd "$(dirname -- "$OUTPUT_ISO")" && sha256sum "$(basename -- "$OUTPUT_ISO")") > "$OUTPUT_ISO.sha256"
echo "Done: $OUTPUT_ISO"
echo 'Install Fedora first, then run blackcomb/setup-blackcomb.sh from the media.'
