#!/bin/sh
# Configure the Plasma panel for the Blackcomb live/installed session:
#   - use the supplied crescent PNG for the Kickoff launcher button;
#   - dock the panel on the left edge as a vertical taskbar;
#   - add RAM, battery, GPU usage and digital clock widgets;
#   - add the stock Media Player widget (Dynamic Music) with track/artist;
#   - expose the stock Notifications center with a Meta+N shortcut.
#
# Plasma::Types::Location is 5 for LeftEdge and FormFactor is 3 for Vertical.
# Applet settings are appended to plasma-org.kde.plasma.desktop-appletsrc so
# they survive logout, and a guarded Plasma scripting call applies them to the
# running shell too. Only standard Plasma/systemmonitor plugins are used; no
# icon theme or SVG editing is needed.
set -eu

icon=/usr/share/blackcomb/branding/crescent-moon-start-icon.png
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

i=0
while [ ! -f "$cfg" ] && [ "$i" -lt 60 ]; do
  sleep 1
  i=$((i + 1))
done
[ -f "$cfg" ] || exit 0

parsed=$(mktemp)
panels=$(mktemp)
desktops=$(mktemp)
icon_groups=$(mktemp)
panel_groups=$(mktemp)
widgets=$(mktemp)
desktop_widgets=$(mktemp)
trap 'rm -f "$parsed" "$panels" "$desktops" "$icon_groups" "$panel_groups" "$widgets" "$desktop_widgets"' EXIT HUP INT TERM

# Collect existing panel containments, their applet plugins and the highest
# applet id in one pass. KConfig merges duplicate sections with later values
# winning, so parsing the file sequentially matches Plasma's own view.
awk -F= '
  /^\[Containments\]\[[^]]+\]$/ {
    group=$0
    sub(/^\[/, "", group)
    sub(/\]$/, "", group)
    containment=group
    applet=""
    plugin[containment]=""
    location[containment]=""
    formfactor[containment]=""
    next
  }
  /^\[Containments\]\[[^]]+\]\[Applets\]\[[0-9]+\]$/ {
    group=$0
    sub(/^\[/, "", group)
    sub(/\]$/, "", group)
    raw=group
    gsub(/\]\[/, "|", group)
    split(group, parts, /\|/)
    containment="Containments][" parts[2]
    applet=raw
    id=parts[4] + 0
    if (id > maxid) maxid=id
    next
  }
  /^\[/ { containment=""; applet=""; next }
  containment != "" {
    if (applet == "") {
      if ($1 == "plugin") plugin[containment]=$2
      else if ($1 == "location") location[containment]=$2
      else if ($1 == "formfactor") formfactor[containment]=$2
    } else if ($1 == "plugin") {
      print "APPLET\t" containment "\t" $2
      if ($2 == "org.kde.plasma.kickoff") print "ICON\t" applet
    }
  }
  END {
    for (group in plugin) {
      if (plugin[group] == "org.kde.panel") {
        print "PANEL\t" group "\t" location[group] "\t" formfactor[group]
      } else if (plugin[group] == "org.kde.plasma.desktop") {
        print "DESKTOP\t" group
      }
    }
    print "MAXID\t" maxid
  }
' "$cfg" > "$parsed"

awk -F '\t' '$1 == "PANEL" { print $2 }' "$parsed" | sort -u > "$panels"
awk -F '\t' '$1 == "DESKTOP" { print $2 }' "$parsed" | sort -u > "$desktops"
awk -F '\t' '$1 == "ICON" { print $2 }' "$parsed" | sort -u > "$icon_groups"
awk -F '\t' '$1 == "PANEL" && ($3 != "5" || $4 != "3") { print $2 }' "$parsed" | sort -u > "$panel_groups"
maxid=$(awk -F '\t' '$1 == "MAXID" && $2 + 0 > m { m = $2 + 0 } END { print m + 0 }' "$parsed")

cat > "$widgets" <<'EOF'
org.kde.plasma.systemmonitor.memory
org.kde.plasma.battery
org.kde.plasma.systemmonitor
org.kde.plasma.digitalclock
org.kde.plasma.mediacontroller
org.kde.plasma.notifications
EOF

# A desktop copy of the stock Media Player widget keeps the artist and track
# readable even when the left taskbar is too narrow for the compact layout.
cat > "$desktop_widgets" <<'EOF'
org.kde.plasma.mediacontroller
EOF

has_applet() {
  group=$1
  plugin=$2
  awk -F '\t' -v g="$group" -v p="$plugin" '
    $1 == "APPLET" && $2 == g && $3 == p { found=1; exit }
    END { exit !found }
  ' "$parsed"
}

has_icon() {
  group=$1
  awk -v g="$group" -v i="$icon" '
    $0 == "[" g "][General]" { in_group=1; next }
    /^\[/ { in_group=0; next }
    in_group && $0 == "icon=" i { found=1; exit }
    END { exit !found }
  ' "$cfg"
}

append_widget() {
  group=$1
  plugin=$2
  id=$3
  printf '\n[%s][Applets][%s]\nplugin=%s\n' "$group" "$id" "$plugin" >> "$cfg"
  case "$plugin" in
    org.kde.plasma.systemmonitor.memory)
      printf '[%s][Applets][%s][Configuration][Appearance]\ntitle=RAM\nchartFace=org.kde.ksysguard.horizontalbars\n' "$group" "$id" >> "$cfg"
      printf '[%s][Applets][%s][Configuration][Sensors]\nsensorIds=["memory/physical/usedPercent"]\nhighPrioritySensorIds=["memory/physical/usedPercent"]\ntotalSensors=["memory/physical/usedPercent"]\nlowPrioritySensorIds=["memory/physical/total"]\n' "$group" "$id" >> "$cfg"
      ;;
    org.kde.plasma.systemmonitor)
      printf '[%s][Applets][%s][Configuration][Appearance]\ntitle=GPU\nchartFace=org.kde.ksysguard.horizontalbars\nblackcombWidget=gpu\n' "$group" "$id" >> "$cfg"
      printf '[%s][Applets][%s][Configuration][Sensors]\nsensorIds=["gpu/all/usage"]\nhighPrioritySensorIds=["gpu/all/usage"]\ntotalSensors=["gpu/all/usage"]\nlowPrioritySensorIds=\n' "$group" "$id" >> "$cfg"
      ;;
    org.kde.plasma.notifications)
      # Meta+N opens the stock notification history from anywhere in Plasma.
      printf '[%s][Applets][%s][Shortcuts]\nglobal=Meta+N\n' "$group" "$id" >> "$cfg"
      ;;
  esac
}

while IFS= read -r group; do
  [ -n "$group" ] || continue
  if has_icon "$group"; then continue; fi
  printf '\n[%s][General]\nicon=%s\n' "$group" "$icon" >> "$cfg"
done < "$icon_groups"

while IFS= read -r group; do
  [ -n "$group" ] || continue
  printf '\n[%s]\nlocation=5\nformfactor=3\n' "$group" >> "$cfg"
done < "$panel_groups"

# Add each missing standard widget once per panel. The dedicated memory applet
# supplies RAM; the generic systemmonitor applet uses the ksystemstats GPU usage
# sensor because Plasma has no built-in analog speedometer face.
while IFS= read -r group; do
  [ -n "$group" ] || continue
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    if has_applet "$group" "$plugin"; then continue; fi
    maxid=$((maxid + 1))
    append_widget "$group" "$plugin" "$maxid"
  done < "$widgets"
done < "$panels"

# Dynamic Music is also placed on the desktop, where Plasma renders the full
# Media Player representation with the current track and artist.
while IFS= read -r group; do
  [ -n "$group" ] || continue
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    if has_applet "$group" "$plugin"; then continue; fi
    maxid=$((maxid + 1))
    append_widget "$group" "$plugin" "$maxid"
  done < "$desktop_widgets"
done < "$desktops"

# Ask a running Plasma shell to apply the changes immediately. The config
# append only takes full effect on the next Plasma start, so this keeps the
# live session correct without restarting the shell. qdbus and dbus-send are
# optional; a missing tool or shell can never break the helper.
layout_js=$(cat <<EOF
var allPanels = panels();
var allDesktops = desktops();
var moved = 0;
var icons = 0;
var added = 0;
var blackcombWidgets = [
  {id:"org.kde.plasma.systemmonitor.memory", title:"RAM", face:"org.kde.ksysguard.horizontalbars", sensors:'["memory/physical/usedPercent"]', total:'["memory/physical/usedPercent"]', low:'["memory/physical/total"]', marker:"", shortcut:""},
  {id:"org.kde.plasma.battery", title:"", face:"", sensors:"", total:"", low:"", marker:"", shortcut:""},
  {id:"org.kde.plasma.systemmonitor", title:"GPU", face:"org.kde.ksysguard.horizontalbars", sensors:'["gpu/all/usage"]', total:'["gpu/all/usage"]', low:"", marker:"gpu", shortcut:""},
  {id:"org.kde.plasma.digitalclock", title:"", face:"", sensors:"", total:"", low:"", marker:"", shortcut:""},
  {id:"org.kde.plasma.mediacontroller", title:"", face:"", sensors:"", total:"", low:"", marker:"", shortcut:""},
  {id:"org.kde.plasma.notifications", title:"", face:"", sensors:"", total:"", low:"", marker:"", shortcut:"Meta+N"}
];
function addWidgetTo(containment, spec, seen) {
  if (seen[spec.id]) return;
  try {
    var widget = containment.addWidget(spec.id);
    if (!widget) return;
    if (spec.title) {
      widget.currentConfigGroup = ["Configuration", "Appearance"];
      widget.writeConfig("title", spec.title);
      widget.writeConfig("chartFace", spec.face);
      if (spec.marker) widget.writeConfig("blackcombWidget", spec.marker);
    }
    if (spec.sensors) {
      widget.currentConfigGroup = ["Configuration", "Sensors"];
      widget.writeConfig("sensorIds", spec.sensors);
      widget.writeConfig("highPrioritySensorIds", spec.sensors);
      widget.writeConfig("totalSensors", spec.total);
      widget.writeConfig("lowPrioritySensorIds", spec.low);
    }
    if (spec.shortcut) {
      widget.currentConfigGroup = ["Shortcuts"];
      widget.writeConfig("global", spec.shortcut);
    }
    widget.reloadConfig();
    added++;
  } catch (error) {
    // A missing optional plugin must never break the layout helper.
  }
}
for (var i = 0; i < allPanels.length; i++) {
  var panel = allPanels[i];
  panel.location = "left";
  moved++;
  var seen = {};
  var widgets = panel.widgets();
  for (var j = 0; j < widgets.length; j++) {
    var current = widgets[j];
    seen[current.type] = true;
    if (current.type === "org.kde.plasma.kickoff") {
      current.currentConfigGroup = ["General"];
      current.writeConfig("icon", "$icon");
      current.reloadConfig();
      icons++;
    }
  }
  for (var k = 0; k < blackcombWidgets.length; k++) {
    addWidgetTo(panel, blackcombWidgets[k], seen);
  }
}
// Dynamic Music gets a desktop copy too, where Plasma shows the full
// representation with the artist and track name instead of a narrow icon.
for (var d = 0; d < allDesktops.length; d++) {
  var desktop = allDesktops[d];
  var desktopSeen = {};
  var desktopWidgets = desktop.widgets();
  for (var m = 0; m < desktopWidgets.length; m++) {
    desktopSeen[desktopWidgets[m].type] = true;
  }
  addWidgetTo(desktop, blackcombWidgets[4], desktopSeen);
}
print("BLACKCOMB_OK:" + moved + ":" + icons + ":" + added);
EOF
)

apply_live_layout() {
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.plasmashell /PlasmaShell \
      org.kde.PlasmaShell.evaluateScript "$layout_js"
  elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.plasmashell /PlasmaShell \
      org.kde.PlasmaShell.evaluateScript "$layout_js"
  elif command -v dbus-send >/dev/null 2>&1; then
    dbus-send --session --print-reply --dest=org.kde.plasmashell \
      /PlasmaShell org.kde.PlasmaShell.evaluateScript string:"$layout_js"
  else
    return 1
  fi
}

if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  i=0
  while [ "$i" -lt 30 ]; do
    result=$(apply_live_layout 2>/dev/null || :)
    counts=$(printf '%s\n' "$result" |
      sed -n 's/.*BLACKCOMB_OK:\([0-9][0-9]*\):\([0-9][0-9]*\):\([0-9][0-9]*\).*/\1:\2/p' |
      head -n 1)
    if [ -n "$counts" ]; then
      panel_count=${counts%%:*}
      kickoff_count=${counts##*:}
      if [ "$panel_count" -gt 0 ] && [ "$kickoff_count" -gt 0 ]; then
        break
      fi
    fi
    i=$((i + 1))
    sleep 1
  done
fi

exit 0
