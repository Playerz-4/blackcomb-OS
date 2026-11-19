#!/usr/bin/env bash
# Create the small uncompressed initramfs overlay; does not rebuild Fedora's initrd.
set -Eeuo pipefail
if (($# != 3)); then
  echo 'Usage: create-live-boot-archive.sh STAGING_DIR LOGO_PNG OUTPUT_CPIO' >&2
  exit 2
fi
stage=$(realpath -- "$1")
logo=$(realpath -- "$2")
output=$(realpath -m -- "$3")
[[ -f $logo && -f $stage/etc/plymouth/plymouthd.conf && -f $stage/usr/share/plymouth/themes/blackcomb-live/blackcomb-live.plymouth ]] || { echo 'Live Plymouth files missing.' >&2; exit 1; }
install -m 644 "$logo" "$stage/usr/share/plymouth/themes/spinner/watermark.png"
(cd "$stage" && find . -print0 | cpio --null -o -H newc --owner 0:0 --quiet > "$output")
