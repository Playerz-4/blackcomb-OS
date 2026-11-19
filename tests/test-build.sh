#!/usr/bin/env bash
# Mocked assembly test; does not test ISO bootability or actual xorriso behavior.
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/work"
printf 'test Fedora ISO\n' > "$tmp/input.iso"
cat > "$tmp/bin/xorriso" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$TEST_LOG"
case " $* " in
  *' -pvd_info '*) echo 'Volume id    : Fedora-KDE-Live-45' ;;
  *' -extract '*)
    [[ ${FAIL_EXTRACT:-0} != 1 ]]
    while (($#)); do
      if [[ $1 == -extract ]]; then printf 'fake erofs\n' > "$3"; break; fi
      shift
    done ;;
  *' -map '*)
    while (($#)); do
      case "$1" in
        -outdev) output=$2; shift 2 ;;
        -map)
          if [[ $3 == /blackcomb ]]; then payload=$2; else test -f "$2"; fi
          shift 3 ;;
        *) shift ;;
      esac
    done
    test -f "$payload/setup-blackcomb.sh"
    test -f "$payload/assets/branding/blackcomb-boot-watermark.png"
    test -f "$payload/assets/branding/blackcomb-launcher.svg"
    test -f "$payload/backgrounds/kim-sunrise.png"
    printf 'fake output ISO\n' > "$output" ;;
  *) exit 1 ;;
esac
MOCK
cat > "$tmp/bin/fsck.erofs" <<'MOCK'
#!/usr/bin/env bash
set -eu
[[ $1 == --extract && -f $2 ]]
printf 'fsck %s\n' "$2" >> "$TEST_LOG"
MOCK
cat > "$tmp/bin/mkfs.erofs" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf 'mkfs %s\n' "$*" >> "$TEST_LOG"
[[ $1 == --quiet && $2 == -zlzma,9 && $3 == -C1048576 && $4 == -Eall-fragments,fragdedupe=inode ]]
if [[ ${FAIL_MKFS:-0} == 1 ]]; then echo 'mock compression error' >&2; exit 42; fi
printf 'compressed erofs\n' > "$5"
MOCK
cat > "$tmp/bin/mount" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf 'mount %s\n' "$*" >> "$TEST_LOG"
MOCK
cat > "$tmp/bin/mountpoint" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
cat > "$tmp/bin/umount" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf 'umount %s\n' "$*" >> "$TEST_LOG"
MOCK
cat > "$tmp/bin/rsync" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf 'rsync %s\n' "$*" >> "$TEST_LOG"
if [[ ${FAIL_COMPARE:-0} == 1 ]]; then echo 'changed-file'; fi
MOCK
cat > "$tmp/bin/implantisomd5" <<'MOCK'
#!/usr/bin/env bash
set -eu
[[ $1 == --force && -f $2 ]]
printf 'implant\n' >> "$TEST_LOG"
MOCK
cat > "$tmp/bin/checkisomd5" <<'MOCK'
#!/usr/bin/env bash
set -eu
[[ -f $1 ]]
printf 'check\n' >> "$TEST_LOG"
MOCK
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" TEST_LOG="$tmp/log"
export FEDORA_ISO="$tmp/input.iso" ISO_SHA256
ISO_SHA256=$(sha256sum "$FEDORA_ISO" | cut -d' ' -f1)
export OUTPUT_ISO="$tmp/output.iso" WORK_DIR="$tmp/work"
"$root/scripts/build-iso.sh"
(cd "$tmp" && sha256sum -c output.iso.sha256)
grep -q -- '-boot_image any replay' "$TEST_LOG"
grep -q '^mkfs --quiet -zlzma,9 -C1048576' "$TEST_LOG"
grep -q '/LiveOS/squashfs.img' "$TEST_LOG"
grep -q '^implant$' "$TEST_LOG"
grep -q '^check$' "$TEST_LOG"
if ISO_SHA256=$(printf '0%.0s' {1..64}) "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Bad input hash accepted' >&2; exit 1
fi
if FAIL_EXTRACT=1 "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Missing LiveOS extraction accepted' >&2; exit 1
fi
if FAIL_COMPARE=1 "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Filesystem differences accepted' >&2; exit 1
fi
if FAIL_MKFS=1 "$root/scripts/build-iso.sh" > "$tmp/compression-error.log" 2>&1; then
  echo 'Compression failure accepted' >&2; exit 1
fi
grep -q 'mock compression error' "$tmp/compression-error.log"
mkdir -p "$tmp/spinner"
printf '[Plymouth Theme]\nName=Spinner\nModuleName=two-step\n[two-step]\nImageDir=/usr/share/plymouth/themes/spinner\n' > "$tmp/spinner/spinner.plymouth"
printf 'spinner data' > "$tmp/spinner/throbber-0001.png"
ln -s /not/a/file "$tmp/spinner/watermark.png"
bash "$root/scripts/create-plymouth-theme.sh" "$tmp/spinner/spinner.plymouth" "$tmp/spinner" "$root/assets/branding/blackcomb-boot-watermark.png" "$tmp/theme"
cmp "$tmp/theme/watermark.png" "$root/assets/branding/blackcomb-boot-watermark.png"
grep -Fxq "ImageDir=$tmp/theme" "$tmp/theme/blackcomb.plymouth"
grep -Fxq 'ModuleName=two-step' "$tmp/theme/blackcomb.plymouth"
echo 'Mock assembly and Plymouth theme tests passed.'
