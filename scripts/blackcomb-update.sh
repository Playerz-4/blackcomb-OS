#!/usr/bin/env bash
# Blackcomb Update: install Fedora package updates and refresh Blackcomb assets
# from the newest GitHub release of Playerz-4/blackcomb-OS.
set -Eeuo pipefail

config=${BLACKCOMB_UPDATE_CONFIG:-/usr/local/lib/blackcomb/update.conf}
if [[ -r $config ]]; then
  # shellcheck disable=SC1090
  . "$config"
fi

repo=${BLACKCOMB_UPDATE_REPO:-Playerz-4/blackcomb-OS}
asset=${BLACKCOMB_UPDATE_ASSET:-blackcomb-update.tar.gz}
api_url=${BLACKCOMB_UPDATE_API_URL:-https://api.github.com/repos/$repo/releases/latest}
version_file=${BLACKCOMB_UPDATE_VERSION_FILE:-/usr/local/lib/blackcomb/version}
work_root=${BLACKCOMB_UPDATE_WORK_ROOT:-/var/tmp}

usage() {
  cat <<'HELP'
Usage: blackcomb-update [--check] [--yes] [--force]

Check the latest Blackcomb GitHub release and install it. By default this:
  1. verifies the release asset's SHA-256,
  2. runs "dnf upgrade --refresh -y",
  3. refreshes Blackcomb wallpapers, themes, splash and configs,
  4. records the installed release version.

Options:
  --check       Only report whether a newer release exists. No root needed.
  --yes         Skip the confirmation prompt.
  --force       Install the newest release even if it is already current.
  --version     Print the installed Blackcomb version.
  --help        Show this help.

Environment overrides are documented in /usr/local/lib/blackcomb/update.conf.
HELP
}

die() { printf 'blackcomb-update: %s\n' "$*" >&2; exit 1; }

args=("$@")
mode=update
assume_yes=0
force=0
while (($#)); do
  case $1 in
    --check) mode=check ;;
    --yes|-y) assume_yes=1 ;;
    --force) force=1 ;;
    --version)
      if [[ -r $version_file ]]; then tr -d '[:space:]' < "$version_file"; printf '\n'; else printf '0.0.0\n'; fi
      exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

installed_version() {
  if [[ -r $version_file ]]; then tr -d '[:space:]' < "$version_file"; else printf '0.0.0'; fi
}

normalize_version() {
  local version=${1#v}
  version=${version#blackcomb-}
  printf '%s' "${version%%+*}"
}

version_is_newer() {
  local candidate current
  candidate=$(normalize_version "$1")
  current=$(normalize_version "$2")
  [[ $candidate != "$current" ]] || return 1
  [[ $(printf '%s\n%s\n' "$candidate" "$current" | sort -V | tail -n 1) == "$candidate" ]]
}

# The Settings launcher uses pkexec; terminal users can also just run the
# command. --check stays unprivileged so it never triggers a password prompt.
if [[ $mode == update && $EUID -ne 0 ]]; then
  if command -v pkexec >/dev/null 2>&1 && [[ -t 0 ]]; then
    exec pkexec "$0" "${args[@]}"
  elif command -v sudo >/dev/null 2>&1; then
    exec sudo "$0" "${args[@]}"
  fi
  die 'Run as root, or install pkexec/sudo.'
fi

for cmd in curl python3 sha256sum tar sort awk mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || die "Missing dependency: $cmd"
done
[[ -n $api_url ]] || die 'No GitHub Releases API URL is configured.'

work=$(mktemp -d "$work_root/blackcomb-update.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
release_json="$work/release.json"

curl --silent --show-error --fail --location --retry 3 \
  --header 'Accept: application/vnd.github+json' \
  --header 'User-Agent: blackcomb-update' \
  --output "$release_json" "$api_url" || die 'Could not contact GitHub Releases.'

python3 - "$release_json" "$asset" > "$work/release-fields" <<'PY'
import json
import sys

release_path, preferred = sys.argv[1:]
try:
    with open(release_path, encoding='utf-8') as handle:
        release = json.load(handle)
except (OSError, ValueError) as exc:
    sys.exit(f'Invalid release response: {exc}')

tag = str(release.get('tag_name') or '').strip()
assets = [item for item in (release.get('assets') or []) if item.get('name')]
if not tag:
    sys.exit('Release has no tag_name')

matches = [item for item in assets if item['name'] == preferred]
if not matches:
    matches = [item for item in assets
               if item['name'].startswith('blackcomb-update')
               and item['name'].endswith('.tar.gz')]
if not matches:
    sys.exit(f'Release has no asset named {preferred} or blackcomb-update*.tar.gz')

chosen = matches[0]
name = chosen['name']
digest = str(chosen.get('digest') or '').strip()
if digest.lower().startswith('sha256:'):
    digest = digest[7:]
checksums = [item for item in assets if item['name'] == f'{name}.sha256']
checksum_url = str(checksums[0].get('browser_download_url') or '') if checksums else ''

print(tag)
print(name)
print(str(chosen.get('browser_download_url') or ''))
print(digest)
print(checksum_url)
PY
mapfile -t release_fields < "$work/release-fields"
[[ ${#release_fields[@]} -eq 5 ]] || die 'Could not read the release metadata.'
for index in "${!release_fields[@]}"; do
  release_fields[$index]=${release_fields[$index]%$'\r'}
done
tag=${release_fields[0]}
release_asset=${release_fields[1]}
asset_url=${release_fields[2]}
expected=${release_fields[3]}
checksum_url=${release_fields[4]}
[[ -n $tag ]] || die 'Release has no tag name.'
[[ -n $release_asset && $release_asset != */* ]] || die 'Invalid release asset name.'
[[ -n $asset_url ]] || die 'Release asset has no download URL.'

current=$(installed_version)
if [[ $mode == check ]]; then
  if version_is_newer "$tag" "$current"; then
    printf 'Blackcomb %s is available (installed: %s).\n' "$tag" "$current"
  else
    printf 'Blackcomb is up to date (%s).\n' "$current"
  fi
  exit 0
fi

if [[ $force != 1 ]] && ! version_is_newer "$tag" "$current"; then
  printf 'Blackcomb %s is already installed; use --force to reinstall.\n' "$current"
  exit 0
fi

printf 'Blackcomb %s is available (installed: %s).\n' "$tag" "$current"
if [[ $assume_yes != 1 ]]; then
  printf 'Upgrade Fedora and refresh Blackcomb assets? [y/N] '
  read -r answer
  case $answer in
    y|Y|yes|YES) ;;
    *) printf 'Cancelled.\n'; exit 0 ;;
  esac
fi

archive="$work/$release_asset"
curl --silent --show-error --fail --location --retry 3 \
  --output "$archive" "$asset_url" || die 'Could not download the release asset.'

if [[ -z $expected && -n $checksum_url ]]; then
  checksum="$work/$release_asset.sha256"
  curl --silent --show-error --fail --location --retry 3 \
    --output "$checksum" "$checksum_url" || die 'Could not download the release checksum.'
  expected=$(awk 'NR == 1 { print $1 }' "$checksum")
fi
[[ $expected =~ ^[[:xdigit:]]{64}$ ]] || die 'Release asset has no usable SHA-256 checksum.'

actual=$(sha256sum "$archive" | awk '{ print $1 }')
[[ ${actual,,} == ${expected,,} ]] || die 'Release asset SHA-256 mismatch; update aborted.'

# Refuse archives that try to write outside the extraction directory.
tar -tzf "$archive" | while IFS= read -r entry; do
  case $entry in
    /*|../*|*/../*|*/..) die "Unsafe path in release asset: $entry" ;;
  esac
done
[[ ${PIPESTATUS[0]} -eq 0 ]] || die 'Could not read the release archive.'

extract="$work/extract"
mkdir -p "$extract"
tar -xzf "$archive" -C "$extract" --no-same-owner || die 'Could not extract the release asset.'

kit="$extract/blackcomb"
[[ -f $kit/setup-blackcomb.sh ]] || kit=$extract
[[ -f $kit/setup-blackcomb.sh ]] || die 'Release asset has no setup-blackcomb.sh.'

printf 'Upgrading Fedora packages...\n'
command -v dnf >/dev/null 2>&1 || die 'DNF is required.'
dnf upgrade --refresh -y || die 'DNF upgrade failed.'

printf 'Refreshing Blackcomb assets...\n'
bash "$kit/setup-blackcomb.sh" --yes || die 'Blackcomb asset refresh failed.'
mkdir -p "$(dirname -- "$version_file")"
printf '%s\n' "$tag" > "$version_file"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications >/dev/null 2>&1 || :
fi
if command -v notify-send >/dev/null 2>&1 && [[ -n ${SUDO_USER:-} && $SUDO_USER != root ]]; then
  runuser -u "$SUDO_USER" -- notify-send 'Blackcomb Update' "Installed Blackcomb $tag." >/dev/null 2>&1 || :
fi
printf 'Blackcomb %s installed successfully.\n' "$tag"
