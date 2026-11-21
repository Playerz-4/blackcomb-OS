#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
spec="$root/packaging/blackpkdgs.spec"
grep -Fxq 'Name:           blackpkdgs' "$spec"
grep -Fxq 'BuildArch:      noarch' "$spec"
for package in firefox vlc libreoffice-writer kcalc chafa imagemagick; do
  grep -Fxq "Requires:       $package" "$spec"
done
grep -Fq 'exec dnf install -y firefox vlc libreoffice-writer kcalc chafa imagemagick' \
  "$root/scripts/blackpkdgs.sh"
grep -Fq 'scripts/blackpkdgs.sh' "$root/scripts/build-blackpkdgs.sh"
grep -Fq 'scripts/blackpkdgs-README.md' "$root/scripts/build-blackpkdgs.sh"
grep -Fq "'blackpkdgs.sh', 'blackpkdgs-README.md'," \
  "$root/scripts/prepare-live-boot.py"
grep -Fq '/usr/local/bin/blackpkdgs' "$root/scripts/live-boot-hook.sh"
grep -Fq '"$HERE/scripts/blackpkdgs.sh" /usr/local/bin/blackpkdgs' \
  "$root/scripts/setup-blackcomb.sh"
echo 'blackpkdgs package tests passed.'
