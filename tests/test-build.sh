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
    # the early Plymouth framebuffer, set a VM-friendly resolution and use KWin's
    # documented legacy-DRM/software-cursor VM path without falling back to
    # safe graphics (RHBZ 2404966, KDE 427060/478301).
    default_entry=$(sed -n '/menuentry "Boot Blackcomb"/,/^}/p' "$grub")
    grep -qw rhgb <<<"$default_entry" || exit 1
    grep -Fq 'plymouth.use-simpledrm=0' <<<"$default_entry" || exit 1
    grep -Fq 'video=1024x768' <<<"$default_entry" || exit 1
    grep -Fq 'systemd.setenv=KWIN_DRM_NO_AMS=1' <<<"$default_entry" || exit 1
    grep -Fq 'systemd.setenv=KWIN_FORCE_SW_CURSOR=1' <<<"$default_entry" || exit 1
    if grep -qw nomodeset <<<"$default_entry"; then exit 1; fi
    if grep -Fq 'Start Blackcomb (basic graphics, no splash)' "$grub"; then exit 1; fi
    if grep -q 'rd.live.check' "$grub"; then exit 1; fi
    test -f "$payload/setup-blackcomb.sh"
    if [[ -e $payload/scripts/blackcomb-update.sh || -e $payload/scripts/blackcomb-update.desktop || -e $payload/scripts/blackcomb-update.conf || -e $payload/scripts/blackcomb-version ]]; then
      echo 'Blackcomb Update must not be shipped' >&2
      exit 1
    fi
    test -f "$payload/scripts/blackcomb-wine.sh"
    test -f "$payload/scripts/blackcomb-wine.desktop"
    test -f "$payload/assets/branding/blackcomb-boot-watermark.png"
    test -f "$payload/live-keyboard.rules"
    test -f "$payload/live-keyboard.pkla"
    test -f "$payload/assets/branding/crescent-moon-start-icon.png"
    test -f "$payload/assets/branding/blackcomb-launcher.svg"
    test -f "$payload/scripts/blackcomb-launcher.sh"
    test -f "$payload/scripts/blackcomb-launcher.desktop"
    test -f "$payload/scripts/patch-breeze-wallpaper.sh"
    test -f "$payload/scripts/patch-lock-screen-wallpaper.sh"
    test -f "$payload/scripts/krunnerrc"
    test -f "$payload/scripts/kuriikwsfilterrc"
    test -f "$payload/scripts/sddm-autologin.conf"
    test -f "$payload/scripts/neofetch.conf"
    test -f "$payload/scripts/neofetch-ascii.conf"
    test -f "$payload/scripts/neofetch-launcher.sh"
    test -x "$payload/scripts/neofetch"
    test -f "$payload/scripts/neofetch-LICENSE.md"
    test -f "$payload/scripts/crescent-moon-neofetch.txt"
    test -f "$payload/backgrounds/kim-sunrise.png"
    test -f "$payload/backgrounds/blackcomb-christmas-village.png"
    test -f "$payload/backgrounds/kim-christmas-northern-lights.png"
    test -f "$payload/wallpapers/kim-stargazer/metadata.json"
    test -f "$payload/wallpapers/blackcomb-christmas-village/metadata.json"
    test -f "$payload/wallpapers/kim-christmas-northern-lights/metadata.json"
    applet=com.blackcomb.search-center
    test -f "$payload/applets/$applet/metadata.json"
    test -f "$payload/applets/$applet/contents/ui/main.qml"
    grep -Fq "\"Id\": \"$applet\"" "$payload/applets/$applet/metadata.json"
    applet=com.blackcomb.emoji-panel
    test -f "$payload/applets/$applet/metadata.json"
    test -f "$payload/applets/$applet/contents/ui/main.qml"
    grep -Fq "\"Id\": \"$applet\"" "$payload/applets/$applet/metadata.json"
    if [[ -e $payload/applets/com.blackcomb.dynamic-music ]]; then
      echo 'Scrapped Dynamic Music must not be shipped' >&2
      exit 1
    fi
    if [[ -e $payload/themes/mountain || -e $payload/scripts/mountain-lookandfeel.conf ]]; then
      echo 'Custom Mountain theme must not be shipped' >&2
      exit 1
    fi
    test -f "$payload/themes/opencode/OpenCode-Catppuccin.colors"
    test -f "$payload/themes/opencode/OpenCode-Dracula-Light.colors"
    test -f "$payload/themes/opencode/README.md"
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
test -f usr/lib/dracut/hooks/pre-pivot/99-blackcomb-live.sh
if [[ -e lib/dracut/hooks/pre-pivot/99-blackcomb-live.sh ]]; then
  echo 'Overlay must not stage /lib/dracut/hooks; it clobbers usr-merged /lib symlink' >&2
  exit 1
fi
test -f etc/dracut/hooks/pre-pivot/99-blackcomb-live.sh
test -f usr/share/blackcomb/live/live-keyboard.rules
test -f usr/share/blackcomb/live/live-keyboard.pkla
test -f usr/share/blackcomb/live/sddm-wait.conf
test -f usr/share/blackcomb/live/plasmalogin-wait.conf
test -f usr/share/blackcomb/live/plasmalogin-autologin.conf
test -f usr/share/blackcomb/live/plasmalogin-wallpaper.conf
test -f usr/share/blackcomb/live/sddm-autologin.conf
test -f usr/share/blackcomb/live/krunnerrc
test -f usr/share/blackcomb/live/kuriikwsfilterrc
test -f usr/share/blackcomb/live/crescent-moon-start-icon.png
test -f usr/share/blackcomb/live/blackcomb-launcher.sh
test -f usr/share/blackcomb/live/blackcomb-launcher.desktop
test -f usr/share/blackcomb/live/patch-breeze-wallpaper.sh
test -f usr/share/blackcomb/live/patch-lock-screen-wallpaper.sh
test -f usr/share/blackcomb/live/neofetch.conf
test -f usr/share/blackcomb/live/neofetch-ascii.conf
test -f usr/share/blackcomb/live/neofetch-launcher.sh
test -x usr/share/blackcomb/live/neofetch
test -f usr/share/blackcomb/live/neofetch-LICENSE.md
test -f usr/share/blackcomb/live/crescent-moon-neofetch.txt
test -f usr/share/blackcomb/live/kim-stargazer.png
test -f usr/share/blackcomb/live/kim-alpine.png
test -f usr/share/blackcomb/live/kim-sunrise.png
test -f usr/share/blackcomb/live/blackcomb-aurora.png
test -f usr/share/blackcomb/live/blackcomb-blue-hour.png
test -f usr/share/blackcomb/live/blackcomb-midnight.png
test -f usr/share/blackcomb/live/blackcomb-moonlit-forest.png
test -f usr/share/blackcomb/live/blackcomb-christmas-village.png
test -f usr/share/blackcomb/live/kim-christmas-northern-lights.png
test -f usr/share/blackcomb/live/wallpapers/kim-stargazer/metadata.json
test -f usr/share/blackcomb/live/wallpapers/blackcomb-aurora/metadata.json
test -f usr/share/blackcomb/live/wallpapers/blackcomb-christmas-village/metadata.json
test -f usr/share/blackcomb/live/wallpapers/kim-christmas-northern-lights/metadata.json
applet=com.blackcomb.search-center
test -f "usr/share/blackcomb/live/applets/$applet/metadata.json"
test -f "usr/share/blackcomb/live/applets/$applet/contents/ui/main.qml"
applet=com.blackcomb.emoji-panel
test -f "usr/share/blackcomb/live/applets/$applet/metadata.json"
test -f "usr/share/blackcomb/live/applets/$applet/contents/ui/main.qml"
if [[ -e usr/share/blackcomb/live/applets/com.blackcomb.dynamic-music ]]; then
  echo 'Scrapped Dynamic Music must not be in the live archive' >&2
  exit 1
fi
if [[ -e usr/share/blackcomb/live/lookandfeel/com.blackcomb.mountain.desktop ]]; then
  echo 'Custom Mountain theme must not be in the live archive' >&2
  exit 1
fi
grep -Fq 'LookAndFeelPackage=org.kde.breeze.desktop' var/lib/dracut/hooks/pre-pivot/99-blackcomb-live.sh
test -f usr/share/blackcomb/live/themes/OpenCode-Catppuccin.colors
test -f usr/share/blackcomb/live/themes/OpenCode-Dracula-Light.colors
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
python3 "$root/tests/test-opencode-themes.py"
python3 "$root/tests/test-wallpaper-theme.py"
bash "$root/tests/test-blackcomb-launcher.sh"
bash "$root/tests/test-blackcomb-wallpaper.sh"
bash "$root/tests/test-lock-screen-wallpaper.sh"
bash "$root/tests/test-blackcomb-wine.sh"
grep -Fxq 'image_backend="chafa"' "$root/scripts/neofetch.conf"
grep -Fxq 'image_source="/usr/share/blackcomb/branding/crescent-moon-start-icon.png"' "$root/scripts/neofetch.conf"
grep -Fxq 'image_backend="ascii"' "$root/scripts/neofetch-ascii.conf"
grep -Fxq 'image_source="/usr/local/lib/blackcomb/neofetch/crescent-moon-neofetch.txt"' "$root/scripts/neofetch-ascii.conf"
grep -Fq 'chafa.conf' "$root/scripts/neofetch-launcher.sh"
grep -Fq 'ascii.conf' "$root/scripts/neofetch-launcher.sh"
grep -Fq 'command -v convert' "$root/scripts/neofetch-launcher.sh"
grep -Fq 'command -v identify' "$root/scripts/neofetch-launcher.sh"
grep -Fq 'chafa imagemagick' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'removeScrappedMusic()' "$root/scripts/blackcomb-launcher.sh"
if grep -Fq 'addWidget("com.blackcomb.dynamic-music")' "$root/scripts/blackcomb-launcher.sh"; then
  echo 'Scrapped Dynamic Music is still being added' >&2
  exit 1
fi
grep -Fq 'com.blackcomb.search-center' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'com.blackcomb.emoji-panel' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'ensureCustomPanel' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'patch-lock-screen-wallpaper.sh' "$root/scripts/setup-blackcomb.sh"
if grep -Fq 'addWidget("org.kde.plasma.mediacontroller")' "$root/scripts/blackcomb-launcher.sh"; then
  echo 'Stock Media Player is still being added' >&2
  exit 1
fi
if grep -Fq 'addWidget("org.kde.plasma.notifications")' "$root/scripts/blackcomb-launcher.sh"; then
  echo 'Stock Notifications widget is still being added' >&2
  exit 1
fi
applet=com.blackcomb.search-center
test -f "$root/applets/$applet/metadata.json"
test -f "$root/applets/$applet/contents/ui/main.qml"
grep -Fq "\"Id\": \"$applet\"" "$root/applets/$applet/metadata.json"
applet=com.blackcomb.emoji-panel
test -f "$root/applets/$applet/metadata.json"
test -f "$root/applets/$applet/contents/ui/main.qml"
grep -Fq "\"Id\": \"$applet\"" "$root/applets/$applet/metadata.json"
if [[ -d $root/applets/com.blackcomb.dynamic-music ]]; then
  echo 'Scrapped Dynamic Music applet is still present' >&2
  exit 1
fi
grep -Fq 'LookAndFeelPackage=org.kde.breeze.desktop' "$root/scripts/setup-blackcomb.sh"
if grep -Fq 'com.blackcomb.mountain.desktop' "$root/scripts/setup-blackcomb.sh"; then
  echo 'Custom Mountain theme is still referenced by setup' >&2
  exit 1
fi
if grep -Rq 'blackcomb-update\|build-update-bundle\|blackcomb-version' "$root/scripts" "$root/README.md" "$root/.github"; then
  echo 'Blackcomb Update is still referenced' >&2
  exit 1
fi
echo 'Mock assembly and Plymouth theme tests passed.'
