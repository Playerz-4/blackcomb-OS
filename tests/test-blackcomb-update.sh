#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$root/scripts/blackcomb-update.sh"
desktop="$root/scripts/blackcomb-update.desktop"
conf="$root/scripts/blackcomb-update.conf"
version="$root/scripts/blackcomb-version"

for file in "$script" "$desktop" "$conf" "$version" "$root/scripts/build-update-bundle.sh"; do
  [[ -f $file ]] || { echo "Missing Blackcomb Update file: $file" >&2; exit 1; }
done
grep -Fq 'api.github.com/repos/$repo/releases/latest' "$script"
grep -Fq 'dnf upgrade --refresh -y' "$script"
grep -Fq 'sha256sum "$archive"' "$script"
grep -Fq 'setup-blackcomb.sh' "$script"
grep -Fxq 'BLACKCOMB_UPDATE_REPO="Playerz-4/blackcomb-OS"' "$conf"
grep -Fxq 'BLACKCOMB_UPDATE_ASSET="blackcomb-update.tar.gz"' "$conf"
grep -Fxq 'Exec=pkexec /usr/local/bin/blackcomb-update' "$desktop"
grep -Fxq 'Icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png' "$desktop"
grep -Fxq 'Terminal=true' "$desktop"
grep -Fxq 'Categories=Settings;System;PackageManager;' "$desktop"
grep -Fq 'scripts/blackcomb-update.sh' "$root/scripts/build-iso.sh"
grep -Fq 'scripts/blackcomb-update.desktop' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'scripts/blackcomb-version' "$root/scripts/setup-blackcomb.sh"
grep -Fq 'blackcomb-update-bundle' "$root/.github/workflows/build-iso.yml"

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/work"

# Build and inspect the release bundle that users upload to GitHub Releases.
bash "$root/scripts/build-update-bundle.sh" "$tmp/blackcomb-update.tar.gz" >/dev/null
tar -tzf "$tmp/blackcomb-update.tar.gz" > "$tmp/bundle-list"
for path in blackcomb/setup-blackcomb.sh blackcomb/scripts/blackcomb-update.sh \
            blackcomb/scripts/blackcomb-update.desktop blackcomb/scripts/blackcomb-update.conf \
            blackcomb/scripts/blackcomb-version blackcomb/scripts/blackcomb-wine.sh \
            blackcomb/scripts/blackcomb-wine.desktop blackcomb/scripts/neofetch \
            blackcomb/backgrounds/kim-stargazer.png blackcomb/assets/branding/crescent-moon-start-icon.png \
            blackcomb/themes/opencode/OpenCode-Catppuccin.colors \
            blackcomb/themes/mountain/metadata.json blackcomb/wallpapers/kim-stargazer/metadata.json; do
  grep -Fxq "$path" "$tmp/bundle-list"
done
(cd "$tmp" && sha256sum -c blackcomb-update.tar.gz.sha256)

# --check must report a newer release without needing root or downloading the asset.
cat > "$tmp/release.json" <<'JSON'
{"tag_name":"v9.9.9","assets":[{"name":"blackcomb-update.tar.gz","browser_download_url":"https://example.invalid/blackcomb-update.tar.gz","digest":"sha256:0000000000000000000000000000000000000000000000000000000000000000"}]}
JSON
cat > "$tmp/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -eu
out=
while (($#)); do
  if [[ $1 == --output ]]; then out=$2; shift 2; else shift; fi
done
[[ -n $out ]]
cp "$FAKE_RELEASE_JSON" "$out"
MOCK
chmod +x "$tmp/bin/curl"
printf '1.0.0\n' > "$tmp/version"
cat > "$tmp/update.conf" <<EOF
BLACKCOMB_UPDATE_REPO="Playerz-4/blackcomb-OS"
BLACKCOMB_UPDATE_ASSET="blackcomb-update.tar.gz"
BLACKCOMB_UPDATE_API_URL="https://example.invalid/latest"
BLACKCOMB_UPDATE_VERSION_FILE="$tmp/version"
BLACKCOMB_UPDATE_WORK_ROOT="$tmp/work"
EOF
run_check() {
  PATH="$tmp/bin:$PATH" FAKE_RELEASE_JSON="$tmp/release.json" \
    BLACKCOMB_UPDATE_CONFIG="$tmp/update.conf" bash "$script" --check
}
output=$(run_check)
grep -Fq 'Blackcomb v9.9.9 is available (installed: 1.0.0).' <<<"$output"
printf 'v9.9.9\n' > "$tmp/version"
output=$(run_check)
grep -Fq 'Blackcomb is up to date (v9.9.9).' <<<"$output"

echo 'Blackcomb Update tests passed.'
