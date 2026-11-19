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
  *' -find '*) [[ ${FAIL_FIND:-0} != 1 ]] ;;
  *' -map '*)
    while (($#)); do
      case "$1" in
        -outdev) output=$2; shift 2 ;;
        -map) payload=$2; shift 3 ;;
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
grep -q '^implant$' "$TEST_LOG"
grep -q '^check$' "$TEST_LOG"
if ISO_SHA256=$(printf '0%.0s' {1..64}) "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Bad input hash accepted' >&2; exit 1
fi
if FAIL_FIND=1 "$root/scripts/build-iso.sh" 2>/dev/null; then
  echo 'Missing LiveOS image accepted' >&2; exit 1
fi
mkdir -p "$tmp/spinner"
printf '[Plymouth Theme]\nName=Spinner\nModuleName=two-step\n[two-step]\nImageDir=/usr/share/plymouth/themes/spinner\n' > "$tmp/spinner/spinner.plymouth"
printf 'spinner data' > "$tmp/spinner/throbber-0001.png"
ln -s /not/a/file "$tmp/spinner/watermark.png"
bash "$root/scripts/create-plymouth-theme.sh" "$tmp/spinner/spinner.plymouth" "$tmp/spinner" "$root/assets/branding/blackcomb-boot-watermark.png" "$tmp/theme"
cmp "$tmp/theme/watermark.png" "$root/assets/branding/blackcomb-boot-watermark.png"
grep -Fxq "ImageDir=$tmp/theme" "$tmp/theme/blackcomb.plymouth"
grep -Fxq 'ModuleName=two-step' "$tmp/theme/blackcomb.plymouth"
echo 'Mock assembly and Plymouth theme tests passed.'
