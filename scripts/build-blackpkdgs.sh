#!/usr/bin/env bash
# Build the noarch blackpkdgs RPM from the checked-in spec and helper files.
set -Eeuo pipefail
umask 022
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT=${1:-$ROOT_DIR/blackpkdgs.rpm}
command -v rpmbuild >/dev/null || { echo 'Missing dependency: rpmbuild' >&2; exit 1; }
for file in "$ROOT_DIR/packaging/blackpkdgs.spec" \
            "$ROOT_DIR/scripts/blackpkdgs.sh" \
            "$ROOT_DIR/scripts/blackpkdgs-README.md"; do
  [[ -f $file ]] || { echo "Missing package file: $file" >&2; exit 1; }
done
mkdir -p "$(dirname -- "$OUTPUT")"
work=$(mktemp -d "${TMPDIR:-/tmp}/blackpkdgs.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/BUILD" "$work/RPMS" "$work/SOURCES" "$work/SPECS" "$work/SRPMS"
install -m 644 "$ROOT_DIR/scripts/blackpkdgs.sh" "$work/SOURCES/blackpkdgs.sh"
install -m 644 "$ROOT_DIR/scripts/blackpkdgs-README.md" "$work/SOURCES/blackpkdgs-README.md"
rpmbuild --define "_topdir $work" --define 'dist .fc45' \
  -bb "$ROOT_DIR/packaging/blackpkdgs.spec"
rpm=$(find "$work/RPMS" -type f -name 'blackpkdgs-*.rpm' -print -quit)
[[ -n $rpm ]] || { echo 'rpmbuild produced no blackpkdgs RPM' >&2; exit 1; }
install -m 644 "$rpm" "$OUTPUT"
echo "Built $OUTPUT"
