#!/usr/bin/env bash
# Add the Blackcomb post-install kit to Fedora KDE's live installer media.
set -Eeuo pipefail
umask 022
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ISO_URL=${FEDORA_ISO_URL:-https://download.fedoraproject.org/pub/fedora/linux/releases/45/KDE/x86_64/iso/Fedora-KDE-Desktop-Live-45-1.4.x86_64.iso}
OUTPUT_ISO=${OUTPUT_ISO:-$ROOT_DIR/blackcomb-fedora-45-x86_64.iso}
WORK_DIR=${WORK_DIR:-$ROOT_DIR/.build}
# Published by Fedora for this exact image. Override only with a trusted checksum.
ISO_SHA256=${ISO_SHA256:-79703d9f3b21a4f7873f2874ec129d6511cb00a08532d8f9b36daacaa96e97a5}
usage() {
  cat <<'HELP'
Usage: ./scripts/build-iso.sh

Add the Blackcomb setup kit to Fedora 45 KDE x86_64 live media.
Fedora's live filesystem, desktop and Anaconda installer remain unchanged.
The live boot menu and Plymouth theme are customized for Blackcomb.
FEDORA_ISO              Path to the Fedora 45 KDE x86_64 ISO (otherwise download).
FEDORA_ISO_URL          Override download URL.
ISO_SHA256              Trusted input SHA-256 (defaults to Fedora 45-1.4 hash).
OUTPUT_ISO              Output path (default: ./blackcomb-fedora-45-x86_64.iso).
WORK_DIR                Temporary directory (default: ./.build).
Requires xorriso, curl, Python 3, cpio, lsinitrd, isomd5sum utilities, and ample disk space.
Root access is not required.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($#)); then usage >&2; exit 2; fi
for cmd in xorriso curl sha256sum realpath implantisomd5 checkisomd5 python3 lsinitrd cpio; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
mkdir -p "$WORK_DIR" "$(dirname -- "$OUTPUT_ISO")"
work=$(realpath -- "$(mktemp -d "$WORK_DIR/blackcomb.XXXXXXXX")")
trap 'rm -rf -- "$work"' EXIT
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
# Verify the live filesystem is present; never extract or replace it. Fedora
# 42+ uses EROFS here despite the legacy filename, so leave it untouched.
xorriso -indev "$input" -find /LiveOS/squashfs.img -type f -exec lsdl -- >/dev/null
# Verify the original live initrd contains Plymouth and the two-step spinner
# before pointing GRUB at a small, uncompressed logo/theme overlay.
xorriso -osirrox on -indev "$input" \
  -extract /boot/grub2/grub.cfg "$work/original-grub.cfg" \
  -extract /boot/x86_64/loader/initrd "$work/live-initrd"
lsinitrd "$work/live-initrd" > "$work/initrd-list"
for pattern in '(^|/)plymouthd([[:space:]]|$)' '(^|/)two-step\.so([[:space:]]|$)' 'usr/share/plymouth/themes/spinner/'; do
  grep -Eq "$pattern" "$work/initrd-list" || { echo "Live initrd missing Plymouth component: $pattern" >&2; exit 1; }
done
python3 "$ROOT_DIR/scripts/prepare-live-boot.py" "$work/original-grub.cfg" "$work/grub.cfg" "$work/boot-overlay"
mkdir -p "$work/blackcomb-boot"
"$ROOT_DIR/scripts/create-live-boot-archive.sh" "$work/boot-overlay" \
  "$ROOT_DIR/assets/branding/blackcomb-boot-watermark.png" "$work/blackcomb-boot/plymouth.cpio"
mkdir -p "$work/blackcomb/scripts" "$work/blackcomb/backgrounds" "$work/blackcomb/assets/branding" "$work/blackcomb/themes/opencode" "$work/blackcomb/themes/mountain/contents" "$work/blackcomb/wallpapers"
install -m 755 "$ROOT_DIR/scripts/setup-blackcomb.sh" "$work/blackcomb/setup-blackcomb.sh"
install -m 755 "$ROOT_DIR/scripts/blackcomb-update.sh" "$work/blackcomb/scripts/blackcomb-update.sh"
install -m 644 "$ROOT_DIR/scripts/blackcomb-update.desktop" "$ROOT_DIR/scripts/blackcomb-update.conf" "$ROOT_DIR/scripts/blackcomb-version" "$work/blackcomb/scripts/"
for script in blackcomb-wallpaper.sh blackcomb-launcher.sh install-grub-background.sh create-plymouth-theme.sh install-plymouth-theme.sh; do
  install -m 755 "$ROOT_DIR/scripts/$script" "$work/blackcomb/scripts/$script"
done
install -m 644 "$ROOT_DIR/scripts/blackcomb-wallpaper.desktop" "$work/blackcomb/scripts/"
install -m 644 "$ROOT_DIR/scripts/blackcomb-launcher.desktop" "$work/blackcomb/scripts/"
install -m 644 "$ROOT_DIR/scripts/neofetch.conf" "$ROOT_DIR/scripts/neofetch-ascii.conf" "$work/blackcomb/scripts/"
install -m 755 "$ROOT_DIR/scripts/neofetch-launcher.sh" "$work/blackcomb/scripts/"
install -m 755 "$ROOT_DIR/third-party/neofetch/neofetch" "$work/blackcomb/scripts/neofetch"
install -m 644 "$ROOT_DIR/third-party/neofetch/LICENSE.md" "$work/blackcomb/scripts/neofetch-LICENSE.md"
install -m 644 "$ROOT_DIR/third-party/neofetch/README.md" "$ROOT_DIR/assets/branding/crescent-moon-neofetch.txt" "$work/blackcomb/scripts/"
# Opt-in live-session fixes: shipped on the media but never run at boot.
install -m 755 "$ROOT_DIR/scripts/apply-live-fixes.sh" "$work/blackcomb/apply-live-fixes.sh"
install -m 644 "$ROOT_DIR/scripts/live-keyboard.rules" "$ROOT_DIR/scripts/live-keyboard.pkla" "$work/blackcomb/"
install -m 755 "$ROOT_DIR/scripts/live-vm-display.sh" "$work/blackcomb/live-vm-display.sh"
install -m 644 "$ROOT_DIR/scripts/live-vm-display.desktop" "$work/blackcomb/live-vm-display.desktop"
install -m 644 "$ROOT_DIR"/backgrounds/*.png "$work/blackcomb/backgrounds/"
install -m 644 "$ROOT_DIR"/assets/branding/*.png "$ROOT_DIR"/assets/branding/*.svg "$work/blackcomb/assets/branding/"
install -m 644 "$ROOT_DIR"/themes/opencode/*.colors "$ROOT_DIR/themes/opencode/README.md" "$work/blackcomb/themes/opencode/"
for package in "$ROOT_DIR"/wallpapers/*; do
  [ -d "$package" ] || continue
  name=$(basename -- "$package")
  install -d "$work/blackcomb/wallpapers/$name"
  install -m 644 "$package/metadata.json" "$work/blackcomb/wallpapers/$name/"
done
install -m 644 "$ROOT_DIR/themes/mountain/metadata.json" "$work/blackcomb/themes/mountain/"
install -m 644 "$ROOT_DIR/themes/mountain/contents/defaults" "$work/blackcomb/themes/mountain/contents/"
install -m 644 "$ROOT_DIR/scripts/mountain-lookandfeel.conf" "$work/blackcomb/scripts/"
install -m 644 "$ROOT_DIR/scripts/MEDIA-README.txt" "$work/blackcomb/README.txt"
echo 'Writing Fedora installer media with the Blackcomb kit...'
xorriso -indev "$input" -outdev "$OUTPUT_ISO" -boot_image any replay \
  -map "$work/grub.cfg" /boot/grub2/grub.cfg \
  -map "$work/blackcomb-boot" /blackcomb-boot \
  -map "$work/blackcomb" /blackcomb -commit
# Fedora's boot-time media check uses the embedded ISO checksum, not a sidecar.
implantisomd5 --force "$OUTPUT_ISO"
checkisomd5 "$OUTPUT_ISO"
(cd "$(dirname -- "$OUTPUT_ISO")" && sha256sum "$(basename -- "$OUTPUT_ISO")") > "$OUTPUT_ISO.sha256"
echo "Done: $OUTPUT_ISO"
echo 'Install Fedora first, then run blackcomb/setup-blackcomb.sh from the media.'
