#!/usr/bin/env bash
# Integration test for the real loop-mount and EROFS compressor toolchain.
set -Eeuo pipefail
[[ $EUID == 0 ]] || { echo 'Run as root.' >&2; exit 1; }
tmp=$(mktemp -d)
cleanup() {
  if mountpoint -q "$tmp/mount" && ! umount "$tmp/mount"; then
    echo "Could not unmount $tmp/mount; leaving work directory intact." >&2
    return 1
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT
mkdir -p "$tmp/tree" "$tmp/mount"
# Data compresses well enough that reading it exercises decompression.
yes 'Blackcomb Fedora EROFS compression test' | head -c 1048576 > "$tmp/tree/data" || [[ $? == 141 ]]
chmod 751 "$tmp/tree/data"
chown 123:456 "$tmp/tree/data"
setfattr -n user.blackcomb-test -v preserved "$tmp/tree/data"
ln "$tmp/tree/data" "$tmp/tree/hardlink"
ln -s data "$tmp/tree/symlink"
mkfs.erofs -zlz4hc,12 "$tmp/source.erofs" "$tmp/tree"
mount -t erofs -o loop,ro "$tmp/source.erofs" "$tmp/mount"
mkfs.erofs -zlzma,9 -C1048576 -Eall-fragments,fragdedupe=inode "$tmp/result.erofs" "$tmp/mount"
umount "$tmp/mount"
fsck.erofs --extract "$tmp/result.erofs"
mount -t erofs -o loop,ro "$tmp/result.erofs" "$tmp/mount"
cmp "$tmp/tree/data" "$tmp/mount/data"
[[ $(stat -c '%u:%g %a' "$tmp/mount/data") == '123:456 751' ]]
[[ $(getfattr --only-values -n user.blackcomb-test "$tmp/mount/data") == preserved ]]
[[ $(stat -c %i "$tmp/mount/data") == "$(stat -c %i "$tmp/mount/hardlink")" ]]
[[ $(readlink "$tmp/mount/symlink") == data ]]
umount "$tmp/mount"
echo 'Real EROFS compression and metadata test passed.'
