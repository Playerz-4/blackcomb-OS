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
  *' -pvd_info '*)
    if [[ ${BAD_LABEL:-0} == 1 ]]; then echo 'Volume id : Not-Fedora'; else echo 'Volume id : Fedora-KDE-Live-45'; fi ;;
  *' -find '*)
    [[ ${FAIL_FIND:-0} != 1 ]]
    [[ $* == *'-find /LiveOS/squashfs.img -type f'* ]] ;;
  *' -extract '*)
    while (($#)); do
      if [[ $1 == -extract ]]; then
        if [[ $2 == /boot/grub2/grub.cfg ]]; then cp "$TEST_ROOT/tests/fixtures/fedora-live-grub.cfg" "$3"; else printf 'fake initrd' > "$3"; fi
        shift 3
      else shift; fi
    done ;;
  *' -map '*)
    maps=0
    while (($#)); do
      case "$1" in
        -outdev) output=$2; shift 2 ;;
        -map)
          case "$3" in
            /blackcomb) payload=$2 ;;
            /blackcomb-boot) boot=$2 ;;
            /boot/grub2/grub.cfg) grub=$2 ;;
            *) echo "Unexpected ISO modification: $3" >&2; exit 1 ;;
          esac
          maps=$((maps + 1)); shift 3 ;;
        *) shift ;;
      esac
    done
    [[ $maps == 3 ]]
    test -f "$boot/plymouth.cpio"
    grep -Fq '($root)/blackcomb-boot/plymouth.cpio' "$grub"
    grep -Fq 'menuentry "Boot Blackcomb"' "$grub"
    # The splash fix must be present in the assembled ISO: keep rhgb, disable
    # the early Plymouth framebuffer, and set a VM-friendly resolution without
    # falling back to safe graphics (RHBZ 2404966).
    default_entry=$(sed -n '/menuentry "Boot Blackcomb"/,/^}/p' "$grub")
    grep -qw rhgb <<<"$default_entry" || exit 1
    grep -Fq 'plymouth.use-simpledrm=0' <<<"$default_entry" || exit 1
    grep -Fq 'video=1024x768' <<<"$default_entry" || exit 1
    if grep -qw nomodeset <<<"$default_entry"; then exit 1; fi
    if grep -Fq 'Start Blackcomb (basic graphics, no splash)' "$grub"; then exit 1; fi
    if grep -q 'rd.live.check' "$grub"; then exit 1; fi
    test -f "$payload/setup-blackcomb.sh"
    test -f "$payload/assets/branding/blackcomb-boot-watermark.png"
    test -f "$payload/assets/branding/blackcomb-launcher.svg"
    test -f "$payload/backgrounds/kim-sunrise.png"
    printf 'fake output ISO\n' > "$output" ;;
  *) exit 1 ;;
esac
MOCK
cat > "$tmp/bin/lsinitrd" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf 'usr/sbin/plymouthd\nusr/lib64/plymouth/two-step.so\n'
if [[ ${MISSING_SPINNER:-0} != 1 ]]; then echo 'usr/share/plymouth/themes/spinner/throbber-0001.png'; fi
MOCK
cat > "$tmp/bin/cpio" <<'MOCK'
#!/usr/bin/env bash
set -eu
[[ $* == '--null -o -H newc --owner 0:0 --quiet' ]]
test -f usr/share/plymouth/themes/spinner/watermark.png
test -f usr/share/plymouth/themes/blackcomb-live/blackcomb-live.plymouth
grep -qx 'Theme=blackcomb-live' etc/plymouth/plymouthd.conf
test -f var/lib/dracut/hooks/pre-pivot/99-blackcomb-live.sh
test -f usr/share/blackcomb/live/sddm-wait.conf
test -f usr/share/blackcomb/live/plasmalogin-wait.conf
test -f usr/share/blackcomb/live/kim-stargazer.png
printf 'mock archive'
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
[[ ${FAIL_MEDIA_CHECK:-0} != 1 ]]
MOCK
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" TEST_LOG="$tmp/log" TEST_ROOT="$root"
export FEDORA_ISO="$tmp/input.iso" ISO_SHA256
ISO_SHA256=$(sha256sum "$FEDORA_ISO" | cut -d' ' -f1)
export OUTPUT_ISO="$tmp/output.iso" WORK_DIR="$tmp/work"
"$root/scripts/build-iso.sh"
(cd "$tmp" && sha256sum -c output.iso.sha256)
grep -q -- '-boot_image any replay' "$TEST_LOG"
grep -q '^implant$' "$TEST_LOG"
grep -q '^check$' "$TEST_LOG"
if ISO_SHA256=$(printf '0%.0s' {1..64}) "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Bad input hash accepted' >&2; exit 1
fi
if BAD_LABEL=1 "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Bad volume label accepted' >&2; exit 1
fi
if FAIL_FIND=1 "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Missing LiveOS filesystem accepted' >&2; exit 1
fi
if MISSING_SPINNER=1 "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Missing Plymouth assets accepted' >&2; exit 1
fi
if OUTPUT_ISO="$FEDORA_ISO" "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Input and output may not be the same' >&2; exit 1
fi
rm -f "$OUTPUT_ISO.sha256"
if FAIL_MEDIA_CHECK=1 "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Bad media checksum accepted' >&2; exit 1
fi
[[ ! -e $OUTPUT_ISO.sha256 ]] || { echo 'Checksum written after failed media check' >&2; exit 1; }
mkdir -p "$tmp/spinner"
printf '[Plymouth Theme]\nName=Spinner\nModuleName=two-step\n[two-step]\nImageDir=/usr/share/plymouth/themes/spinner\n' > "$tmp/spinner/spinner.plymouth"
printf 'spinner data' > "$tmp/spinner/throbber-0001.png"
ln -s /not/a/file "$tmp/spinner/watermark.png"
bash "$root/scripts/create-plymouth-theme.sh" "$tmp/spinner/spinner.plymouth" "$tmp/spinner" "$root/assets/branding/blackcomb-boot-watermark.png" "$tmp/theme"
cmp "$tmp/theme/watermark.png" "$root/assets/branding/blackcomb-boot-watermark.png"
grep -Fxq "ImageDir=$tmp/theme" "$tmp/theme/blackcomb.plymouth"
grep -Fxq 'ModuleName=two-step' "$tmp/theme/blackcomb.plymouth"
python3 "$root/tests/test-live-boot.py"
echo 'Mock assembly and Plymouth theme tests passed.'
