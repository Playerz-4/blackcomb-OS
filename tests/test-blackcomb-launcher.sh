#!/usr/bin/env bash
# Verify that the launcher helper docks the main taskbar left, sets the
# crescent PNG as the Kickoff icon, adds the standard system widgets, hosts the
# Search Center and Meta+. emoji applets on a dedicated panel, removes the old
# stock-widget approximation and scrapped Dynamic Music, and stays idempotent.
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/.config"
cfg="$tmp/home/.config/plasma-org.kde.plasma.desktop-appletsrc"
cat > "$cfg" <<'EOF'
[Containments][1]
activityId=
formfactor=2
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][1][Applets][2]
plugin=org.kde.plasma.kickoff

[Containments][3]
activityId=
formfactor=0
lastScreen=0
location=1
plugin=org.kde.plasma.desktop
wallpaperplugin=org.kde.image
EOF

DBUS_SESSION_BUS_ADDRESS= HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"

grep -Fxq 'location=5' "$cfg"
grep -Fxq 'formfactor=3' "$cfg"
grep -Fq 'org.kde.PlasmaShell.evaluateScript' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'allPanels[i].location = "left"' "$root/scripts/blackcomb-launcher.sh" || grep -Fq 'panel.location = "left"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'current.writeConfig("icon"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'currentConfigGroup = ["General"]' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'BLACKCOMB_OK:' "$root/scripts/blackcomb-launcher.sh"
grep -Fq -- '--print-reply' "$root/scripts/blackcomb-launcher.sh"
grep -Fxq '[Containments][1][Applets][2][General]' "$cfg"
grep -Fxq 'icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png' "$cfg"
test "$(grep -Ec '^location=5$' "$cfg")" -eq 1
test "$(grep -Ec '^plugin=org.kde.plasma.desktop$' "$cfg")" -eq 1

for plugin in org.kde.plasma.systemmonitor.memory org.kde.plasma.battery \
              org.kde.plasma.systemmonitor org.kde.plasma.digitalclock; do
  grep -Fxq "plugin=$plugin" "$cfg"
  test "$(grep -Ec "^plugin=$plugin\$" "$cfg")" -eq 1
done

# Dynamic Music is scrapped. Search Center keeps its own centered bottom panel.
if grep -Fq 'com.blackcomb.dynamic-music' "$cfg"; then
  echo 'Scrapped Dynamic Music was added to the saved layout' >&2
  exit 1
fi
test "$(grep -Ec '^plugin=com\.blackcomb\.search-center$' "$cfg")" -eq 1
grep -Fxq '[Containments][4][Applets][3]' "$cfg"
if grep -Fxq 'location=3' "$cfg"; then
  echo 'No empty top panel may be left behind' >&2
  exit 1
fi
search_panel=$(sed -n '/^\[Containments\]\[4\]$/,/^\[/p' "$cfg")
grep -Fxq 'location=4' <<<"$search_panel"
grep -Fxq 'formfactor=2' <<<"$search_panel"
grep -Fxq 'alignment=132' <<<"$search_panel"
grep -Fxq 'panelLengthMode=1' <<<"$search_panel"
grep -Fxq 'plugin=org.kde.panel' <<<"$search_panel"
grep -Fxq '[Containments][4][Applets][3][Shortcuts]' "$cfg"
grep -Fxq 'global=Meta+N' "$cfg"
grep -Fxq '[Containments][4][Applets][4]' "$cfg"
grep -Fxq '[Containments][4][Applets][4][Shortcuts]' "$cfg"
grep -Fxq 'global=Meta+.' "$cfg"
test "$(grep -Ec '^plugin=com\.blackcomb\.emoji-panel$' "$cfg")" -eq 1

# The earlier stock-widget approximation must be gone from the saved layout.
if grep -Eq '^plugin=org\.kde\.plasma\.(mediacontroller|notifications)$' "$cfg"; then
  echo 'Stock media/notification widgets were added to the layout' >&2
  exit 1
fi

grep -Fxq 'title=RAM' "$cfg"
grep -Fxq 'chartFace=org.kde.ksysguard.horizontalbars' "$cfg"
grep -Fxq 'sensorIds=["memory/physical/usedPercent"]' "$cfg"
grep -Fxq 'title=GPU' "$cfg"
grep -Fxq 'blackcombWidget=gpu' "$cfg"
grep -Fxq 'sensorIds=["gpu/all/usage"]' "$cfg"
grep -Fq 'containment.addWidget(spec.id)' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'addWidgetTo(panel, blackcombWidgets[k], seen)' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'memory/physical/usedPercent' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'gpu/all/usage' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'org.kde.plasma.digitalclock' "$root/scripts/blackcomb-launcher.sh"
# The obsolete plugin id may appear only in removal/cleanup code.
grep -Fq 'removeScrappedMusic()' "$root/scripts/blackcomb-launcher.sh"
if grep -Eq 'addWidget\("com\.blackcomb\.dynamic-music"|ensureCustomPanel\("com\.blackcomb\.dynamic-music"|append_widget.*com\.blackcomb\.dynamic-music' "$root/scripts/blackcomb-launcher.sh"; then
  echo 'Scrapped Dynamic Music is still being added' >&2
  exit 1
fi
grep -Fq 'com.blackcomb.search-center' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'com.blackcomb.emoji-panel' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'globalShortcut = "Meta+."' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'ensureCustomPanel("com.blackcomb.search-center", "bottom", "center", 44)' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'ensureCustomPanel("com.blackcomb.emoji-panel", "bottom", "center", 44, ["com.blackcomb.search-center"])' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'panel.location = location' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'panel.alignment = alignment' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'panel.lengthMode = "fit"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'append_custom_panels()' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'if [ "$layout_ok" -eq 0 ] && [ "$want_config_panels" -eq 0 ]; then' "$root/scripts/blackcomb-launcher.sh"
grep -Fq '[ "$want_config_panels" -eq 1 ] && append_custom_panels' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'removeStock(panel)' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'type === "org.kde.plasma.mediacontroller"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'type === "org.kde.plasma.notifications"' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'Meta+N' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'var allDesktops = desktops();' "$root/scripts/blackcomb-launcher.sh"
grep -Fq 'BLACKCOMB_OK:' "$root/scripts/blackcomb-launcher.sh"

# The remaining custom applets must use guaranteed Breeze icon names.
if [[ -d $root/applets/com.blackcomb.dynamic-music ]]; then
  echo 'Scrapped Dynamic Music applet is still present' >&2
  exit 1
fi
search_qml="$root/applets/com.blackcomb.search-center/contents/ui/main.qml"
grep -Fq '"system-search"' "$search_qml"
grep -Fq 'Canvas {' "$search_qml"
grep -Fq 'ctx.arc(' "$search_qml"
grep -Fq 'ListModel {' "$search_qml"
grep -Fq 'DuckDuckGo' "$search_qml"
grep -Fq 'Web suggestions' "$search_qml"
grep -Fq 'XMLHttpRequest' "$search_qml"
grep -Fq 'suggestqueries.google.com/complete/search' "$search_qml"
grep -Fq 'Live web suggestions' "$search_qml"
grep -Fq 'limit: 2' "$search_qml"
# The installed-application browser was scrapped; keep Search Center unchanged.
if grep -Eq 'KICKER_ALL_MODEL|appsModel|i18n\("Applications"\)|flat: true' "$search_qml"; then
  echo 'Search Center still contains the scrapped installed-apps browser' >&2
  exit 1
fi
grep -Fq '"Icon": "system-search"' "$root/applets/com.blackcomb.search-center/metadata.json"

emoji_qml="$root/applets/com.blackcomb.emoji-panel/contents/ui/main.qml"
grep -Fq '"Id": "com.blackcomb.emoji-panel"' "$root/applets/com.blackcomb.emoji-panel/metadata.json"
grep -Fq '"Icon": "face-smile"' "$root/applets/com.blackcomb.emoji-panel/metadata.json"
grep -Fq 'Meta+.' "$emoji_qml"
grep -Fq 'Noto Color Emoji' "$emoji_qml"
grep -Fq 'clipboardProbe.copy()' "$emoji_qml"
grep -Fq 'clipboardProbe.paste()' "$emoji_qml"
grep -Fq 'i18n("ASCII")' "$emoji_qml"
grep -Fq 'i18n("Symbols")' "$emoji_qml"
grep -Fq 'i18n("Clipboard")' "$emoji_qml"
if grep -Eq 'icon\.name: "search"|Plasmoid\.icon: "search"|"Icon": "search"' "$search_qml" "$root/applets/com.blackcomb.search-center/metadata.json"; then
  echo 'Search Center still uses the non-guaranteed search icon name' >&2
  exit 1
fi

cp "$cfg" "$tmp/before"
DBUS_SESSION_BUS_ADDRESS= HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"
cmp "$cfg" "$tmp/before"

# When Plasma scripting succeeds, it creates and persists the panels itself,
# so the shell must not also append them to the saved config.
mkdir -p "$tmp/bin" "$tmp/dbus-home/.config"
cat > "$tmp/bin/qdbus6" <<'MOCK'
#!/usr/bin/env bash
printf 'BLACKCOMB_OK:1:1:4:0:2\n'
MOCK
chmod +x "$tmp/bin/qdbus6"
dbus_cfg="$tmp/dbus-home/.config/plasma-org.kde.plasma.desktop-appletsrc"
cat > "$dbus_cfg" <<'EOF'
[Containments][1]
activityId=
formfactor=2
lastScreen=0
location=4
plugin=org.kde.panel

[Containments][1][Applets][2]
plugin=org.kde.plasma.kickoff
EOF
PATH="$tmp/bin:$PATH" DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/blackcomb-fake-bus \
  HOME="$tmp/dbus-home" XDG_CONFIG_HOME="$tmp/dbus-home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"
if grep -Eq '^plugin=com\.blackcomb\.(dynamic-music|search-center|emoji-panel)$' "$dbus_cfg"; then
  echo 'The custom panel was appended even though Plasma scripting succeeded' >&2
  exit 1
fi

# A layout saved by the previous stock-widget build is cleaned up on upgrade.
mkdir -p "$tmp/stock-home/.config"
stock_cfg="$tmp/stock-home/.config/plasma-org.kde.plasma.desktop-appletsrc"
cat > "$stock_cfg" <<'EOF'
[Containments][1]
activityId=
formfactor=2
lastScreen=0
location=4
plugin=org.kde.panel

[Containments][1][Applets][2]
plugin=org.kde.plasma.kickoff

[Containments][3]
activityId=
formfactor=0
lastScreen=0
location=1
plugin=org.kde.plasma.desktop
wallpaperplugin=org.kde.image

[Containments][1][Applets][9]
plugin=org.kde.plasma.mediacontroller

[Containments][1][Applets][10]
plugin=org.kde.plasma.mediacontroller

[Containments][1][Applets][11]
plugin=org.kde.plasma.notifications

[Containments][1][Applets][11][Shortcuts]
global=Meta+N
EOF
DBUS_SESSION_BUS_ADDRESS= HOME="$tmp/stock-home" XDG_CONFIG_HOME="$tmp/stock-home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"
if grep -Eq '^plugin=org\.kde\.plasma\.(mediacontroller|notifications)$' "$stock_cfg"; then
  echo 'Old stock widgets survived the upgrade cleanup' >&2
  exit 1
fi
if grep -Fq '[Containments][1][Applets][11][Shortcuts]' "$stock_cfg"; then
  echo 'Old notification shortcut survived the upgrade cleanup' >&2
  exit 1
fi
if grep -Fq 'com.blackcomb.dynamic-music' "$stock_cfg"; then
  echo 'Scrapped Dynamic Music survived the upgrade cleanup' >&2
  exit 1
fi
grep -Fxq 'plugin=com.blackcomb.search-center' "$stock_cfg"
grep -Fxq 'plugin=com.blackcomb.emoji-panel' "$stock_cfg"

# Configs saved by the previous build had a dedicated top music panel. It must
# be removed without re-creating the scrapped applet.
mkdir -p "$tmp/legacy-home/.config"
legacy_cfg="$tmp/legacy-home/.config/plasma-org.kde.plasma.desktop-appletsrc"
cat > "$legacy_cfg" <<'EOF'
[Containments][1]
activityId=
formfactor=2
lastScreen=0
location=3
plugin=org.kde.panel
wallpaperplugin=org.kde.image
alignment=2
panelLengthMode=1

[Containments][1][Applets][5]
plugin=com.blackcomb.dynamic-music

[Containments][2]
activityId=
formfactor=2
lastScreen=0
location=4
plugin=org.kde.panel

[Containments][2][Applets][6]
plugin=org.kde.plasma.kickoff

[Containments][3]
activityId=
formfactor=0
lastScreen=0
location=1
plugin=org.kde.plasma.desktop
wallpaperplugin=org.kde.image
EOF
DBUS_SESSION_BUS_ADDRESS= HOME="$tmp/legacy-home" XDG_CONFIG_HOME="$tmp/legacy-home/.config" \
  sh "$root/scripts/blackcomb-launcher.sh"
if grep -q '^\[Containments\]\[1\]' "$legacy_cfg"; then
  echo 'Old dedicated Dynamic Music panel survived the upgrade cleanup' >&2
  exit 1
fi
if grep -Fxq 'location=3' "$legacy_cfg"; then
  echo 'Old top music panel was not removed' >&2
  exit 1
fi
if grep -Fq 'com.blackcomb.dynamic-music' "$legacy_cfg"; then
  echo 'Scrapped Dynamic Music survived the legacy layout cleanup' >&2
  exit 1
fi
grep -Fxq '[Containments][4][Applets][7]' "$legacy_cfg"
grep -Fxq 'plugin=com.blackcomb.search-center' "$legacy_cfg"
grep -Fxq 'plugin=com.blackcomb.emoji-panel' "$legacy_cfg"

echo 'Plasma taskbar, launcher and panel widget tests passed.'
