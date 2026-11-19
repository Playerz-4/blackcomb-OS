#!/usr/bin/env bash
# Compress an already-built ISO for distribution; this does not change its contents.
set -Eeuo pipefail
usage() {
  cat <<'HELP'
Usage: ./scripts/compress-iso.sh [--require-target] INPUT.iso [OUTPUT.iso.zst]

Compress an ISO with zstd and write an accompanying SHA-256 file. The input ISO
is left untouched. The target is 2 GiB (2147483648 bytes); --require-target
returns a nonzero status when the compressed file exceeds it, but retains the
file. Images containing already-compressed data may not reach that target.
Requires zstd, sha256sum and enough free space for both files.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
require_target=0
if [[ ${1:-} == --require-target ]]; then require_target=1; shift; fi
if (($# < 1 || $# > 2)); then usage >&2; exit 2; fi
for cmd in zstd sha256sum stat realpath; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
input=$(realpath -- "$1")
[[ -f $input ]] || { echo 'Input ISO not found.' >&2; exit 1; }
output=${2:-$1.zst}
[[ $(realpath -m -- "$output") != "$input" ]] || { echo 'Input and output must differ.' >&2; exit 1; }
[[ ! -e $output && ! -e $output.sha256 ]] || { echo 'Output or its checksum already exists; choose another path.' >&2; exit 1; }
mkdir -p "$(dirname -- "$output")"
tmp=$(mktemp "${output}.partial.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
# Single-threaded level 19 limits peak memory compared with parallel max compression.
zstd -19 -T1 -f -o "$tmp" -- "$input"
zstd -t -- "$tmp"
mv -- "$tmp" "$output"
(cd "$(dirname -- "$output")" && sha256sum "$(basename -- "$output")") > "$output.sha256"
bytes=$(stat -c %s -- "$output")
target=2147483648
printf 'Compressed file: %s (%s bytes; target: %s bytes)\n' "$output" "$bytes" "$target"
if ((bytes > target)); then
  echo 'WARNING: the compressed image exceeds the 2 GiB target. Ubuntu ISO data is already largely compressed.' >&2
  if ((require_target)); then exit 1; fi
fi
