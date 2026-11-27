#!/bin/sh
# Configure the Blackcomb Plasma layout:
#   - use the supplied crescent PNG for the Kickoff launcher button;
#   - keep the existing taskbar docked on the left edge;
#   - add RAM, battery, GPU usage and digital clock widgets;
#   - place Blackcomb Search Center and the Meta+. emoji/clipboard panel in a
#     dedicated bottom-center panel;
#   - remove the stock Media Player and Notifications approximations and any
#     legacy Dynamic Music panel from an older Blackcomb layout.
#
# Plasma::Types::Location is 3 for TopEdge, 4 for BottomEdge and 5 for
# LeftEdge. FormFactor is 2 for Horizontal and 3 for Vertical. Applet settings
# are appended to plasma-org.kde.plasma.desktop-appletsrc so they survive
# logout, and a guarded Plasma scripting call applies them to the running
# shell too. The custom applets are plain QML packages; no SVG editing or new
# binary dependency is needed.
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
removed=$(mktemp)
legacy=$(mktemp)
clean=$(mktemp)
trap 'rm -f "$parsed" "$panels" "$desktops" "$icon_groups" "$panel_groups" "$widgets" "$removed" "$legacy" "$clean"' EXIT HUP INT TERM

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
    # The helper appends a second [Containments][N] section when it docks a
    # panel left. Preserve values from the first section instead of wiping
    # them, so the panel is still recognized on the next run.
    if (!(containment in seen)) {
      plugin[containment]=""
      location[containment]=""
      formfactor[containment]=""
      legacyMusic[containment]=0
      customSearch[containment]=0
      customEmoji[containment]=0
      seen[containment]=1
    }
    next
  }
  /^\[Containments\]\[[^]]+\]\[Applets\]\[[0-9]+\]$/ {
    section=$0
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
      print "APPLET\t" containment "\t" $2 "\t" section "\t" location[containment] "\t" plugin[containment]
      if ($2 == "org.kde.plasma.kickoff") print "ICON\t" applet
      if ($2 == "com.blackcomb.dynamic-music") legacyMusic[containment]=1
      if ($2 == "com.blackcomb.search-center") customSearch[containment]=1
      if ($2 == "com.blackcomb.emoji-panel") customEmoji[containment]=1
    }
  }
  END {
    for (group in plugin) {
      special = (legacyMusic[group] || customSearch[group] || customEmoji[group]) ? 1 : 0
      if (plugin[group] == "org.kde.panel") {
        print "PANEL\t" group "\t" location[group] "\t" formfactor[group] "\t" special
        # The old dedicated music panel must go away: a hidden applet would
        # otherwise leave an empty strip at the top of the screen.
        if (legacyMusic[group] && !customSearch[group]) {
          print "LEGACY\t" group
        }
      } else if (plugin[group] == "org.kde.plasma.desktop") {
        print "DESKTOP\t" group "\t" special
      }
    }
    print "MAXID\t" maxid
  }
' "$cfg" > "$parsed"

awk -F '\t' '$1 == "PANEL" && $5 != "1" { print $2 }' "$parsed" | sort -u > "$panels"
awk -F '\t' '$1 == "DESKTOP" { print $2 }' "$parsed" | sort -u > "$desktops"
awk -F '\t' '$1 == "ICON" { print $2 }' "$parsed" | sort -u > "$icon_groups"
awk -F '\t' '$1 == "PANEL" && ($3 != "5" || $4 != "3") && $5 != "1" { print $2 }' "$parsed" | sort -u > "$panel_groups"
awk -F '\t' '$1 == "LEGACY" { print $2 }' "$parsed" | sort -u > "$legacy"
maxid=$(awk -F '\t' '$1 == "MAXID" && $2 + 0 > m { m = $2 + 0 } END { print m + 0 }' "$parsed")

# Replace the earlier stock-widget approximation. Removing the applet sections
# (including their shortcut subsections) keeps the config free of duplicate
# media and notification widgets on later runs.
awk -F '\t' '
  $1 == "APPLET" && ($3 == "org.kde.plasma.mediacontroller" || $3 == "org.kde.plasma.notifications" || $3 == "com.blackcomb.dynamic-music") {
    print $4
  }
' "$parsed" > "$removed"
awk -v prefixes="$removed" -v legacy="$legacy" '
  BEGIN {
    while ((getline prefix < prefixes) > 0) bad[prefix] = 1
    close(prefixes)
    while ((getline group < legacy) > 0) badcontainment[group] = 1
    close(legacy)
  }
  /^\[Containments\]\[[0-9]+\]$/ {
    skipContainment = 0
    for (group in badcontainment) {
      if ($0 == "[" group "]") {
        skipContainment = 1
        break
      }
    }
    skipSection = skipContainment
    if (!skipSection) print
    next
  }
  /^\[/ {
    if (skipContainment) next
    skipSection = 0
    for (prefix in bad) {
      if (index($0, prefix) == 1) {
        skipSection = 1
        break
      }
    }
    if (!skipSection) print
    next
  }
  !skipSection { print }
' "$cfg" > "$clean"
cp "$clean" "$cfg"

cat > "$widgets" <<'EOF'
org.kde.plasma.systemmonitor.memory
org.kde.plasma.battery
org.kde.plasma.systemmonitor
org.kde.plasma.digitalclock
EOF

has_applet() {
  group=$1
  plugin=$2
  awk -F '\t' -v g="$group" -v p="$plugin" '
    $1 == "APPLET" && $2 == g && $3 == p { found=1; exit }
    END { exit !found }
  ' "$parsed"
}

has_applet_at() {
  plugin=$1
  location=$2
  awk -F '\t' -v p="$plugin" -v l="$location" '
    $1 == "APPLET" && $3 == p && $5 == l { found=1; exit }
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
    com.blackcomb.search-center)
      # Meta+N opens the Blackcomb Search Center from anywhere in Plasma.
      printf '[%s][Applets][%s][Shortcuts]\nglobal=Meta+N\n' "$group" "$id" >> "$cfg"
      ;;
    com.blackcomb.emoji-panel)
      # Meta+. opens the emoji/ASCII/symbol/clipboard panel from anywhere.
      printf '[%s][Applets][%s][Shortcuts]\nglobal=Meta+.\n' "$group" "$id" >> "$cfg"
      ;;
  esac
}

# Fallback for sessions without a working Plasma scripting bridge. Search
# Center keeps its bottom-center panel. alignment=132 is Qt.AlignCenter. When
# scripting works, it creates and persists the panel itself, so doing both
# would duplicate it on next start.
maxcontainment=$(sed -n 's/^\[Containments\]\[\([0-9][0-9]*\)\]$/\1/p' "$cfg" | sort -n | tail -n 1)
[ -n "$maxcontainment" ] || maxcontainment=0

append_custom_panels() {
  search_group=$(awk -F '\t' '$1 == "APPLET" && $3 == "com.blackcomb.search-center" && $5 == "4" { print $2; exit }' "$parsed")
  if [ -z "$search_group" ]; then
    maxcontainment=$((maxcontainment + 1))
    search_group="Containments][$maxcontainment"
    maxid=$((maxid + 1))
    printf '\n[Containments][%s]\nactivityId=\nformfactor=2\nlastScreen=0\nlocation=4\nplugin=org.kde.panel\nwallpaperplugin=org.kde.image\nalignment=132\npanelLengthMode=1\n' "$maxcontainment" >> "$cfg"
    printf '\n[%s][Applets][%s]\nplugin=com.blackcomb.search-center\n' "$search_group" "$maxid" >> "$cfg"
    printf '[%s][Applets][%s][Shortcuts]\nglobal=Meta+N\n' "$search_group" "$maxid" >> "$cfg"
  fi
  # The emoji panel shares the Search Center panel instead of adding a second
  # centered strip. Upgrades from earlier builds gain it in place.
  if ! has_applet "$search_group" com.blackcomb.emoji-panel; then
    maxid=$((maxid + 1))
    printf '\n[%s][Applets][%s]\nplugin=com.blackcomb.emoji-panel\n' "$search_group" "$maxid" >> "$cfg"
    printf '[%s][Applets][%s][Shortcuts]\nglobal=Meta+.\n' "$search_group" "$maxid" >> "$cfg"
  fi
}

# Without a session bus, write the layout immediately so the fallback keeps
# the usual id order ahead of the system widgets. With a bus, wait for the
# scripting result below and only fall back if it fails.
want_config_panels=1
[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] || want_config_panels=0
[ "$want_config_panels" -eq 1 ] && append_custom_panels

while IFS= read -r group; do
  [ -n "$group" ] || continue
  if has_icon "$group"; then continue; fi
  printf '\n[%s][General]\nicon=%s\n' "$group" "$icon" >> "$cfg"
done < "$icon_groups"

while IFS= read -r group; do
  [ -n "$group" ] || continue
  printf '\n[%s]\nlocation=5\nformfactor=3\n' "$group" >> "$cfg"
done < "$panel_groups"

# Add each missing standard widget once per main panel. The dedicated search
# panel is intentionally excluded from the left-side system widgets.
while IFS= read -r group; do
  [ -n "$group" ] || continue
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    if has_applet "$group" "$plugin"; then continue; fi
    maxid=$((maxid + 1))
    append_widget "$group" "$plugin" "$maxid"
  done < "$widgets"
done < "$panels"

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
var removed = 0;
var customized = 0;
var blackcombWidgets = [
  {id:"org.kde.plasma.systemmonitor.memory", title:"RAM", face:"org.kde.ksysguard.horizontalbars", sensors:'["memory/physical/usedPercent"]', total:'["memory/physical/usedPercent"]', low:'["memory/physical/total"]', marker:""},
  {id:"org.kde.plasma.battery", title:"", face:"", sensors:"", total:"", low:"", marker:""},
  {id:"org.kde.plasma.systemmonitor", title:"GPU", face:"org.kde.ksysguard.horizontalbars", sensors:'["gpu/all/usage"]', total:'["gpu/all/usage"]', low:"", marker:"gpu"},
  {id:"org.kde.plasma.digitalclock", title:"", face:"", sensors:"", total:"", low:"", marker:""}
];
function hasType(widgets, type) {
  for (var i = 0; i < widgets.length; i++) {
    if (widgets[i].type === type) return true;
  }
  return false;
}
function hasAnyType(widgets, types) {
  if (!types) return false;
  for (var i = 0; i < types.length; i++) {
    if (hasType(widgets, types[i])) return true;
  }
  return false;
}
function removeStock(containment) {
  var widgets = containment.widgets();
  for (var i = 0; i < widgets.length; i++) {
    var type = widgets[i].type;
    if (type === "org.kde.plasma.mediacontroller" || type === "org.kde.plasma.notifications" || type === "com.blackcomb.dynamic-music") {
      widgets[i].remove();
      removed++;
    }
  }
}
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
    widget.reloadConfig();
    added++;
  } catch (error) {
    // A missing optional plugin must never break the layout helper.
  }
}
function ensureCustomPanel(type, location, alignment, height, siblingTypes) {
  var panel = null;
  var i;
  for (i = 0; i < allPanels.length; i++) {
    var existing = allPanels[i].widgets();
    if (hasType(existing, type) || hasAnyType(existing, siblingTypes)) {
      panel = allPanels[i];
      break;
    }
  }
  if (!panel) {
    panel = new Panel();
    customized++;
  }
  panel.location = location;
  panel.alignment = alignment;
  panel.lengthMode = "fit";
  panel.hiding = "none";
  panel.floating = false;
  panel.height = height;
  var widgets = panel.widgets();
  if (!hasType(widgets, type)) {
    // A missing or broken optional plugin must never abort the layout helper.
    try {
      var widget = panel.addWidget(type);
      if (widget) {
        try {
          if (type === "com.blackcomb.search-center") widget.globalShortcut = "Meta+N";
          if (type === "com.blackcomb.emoji-panel") widget.globalShortcut = "Meta+.";
          widget.reloadConfig();
        } catch (error) {
          print("Blackcomb: could not configure " + type + ": " + error);
        }
        added++;
      }
    } catch (error) {
      print("Blackcomb: could not add " + type + ": " + error);
    }
  } else {
    for (i = 0; i < widgets.length; i++) {
      try {
        if (widgets[i].type === type && type === "com.blackcomb.search-center") widgets[i].globalShortcut = "Meta+N";
        if (widgets[i].type === type && type === "com.blackcomb.emoji-panel") widgets[i].globalShortcut = "Meta+.";
      } catch (error) {
        print("Blackcomb: could not set shortcut for " + type + ": " + error);
      }
    }
  }
}
// Dynamic Music was scrapped. Remove panels left by the previous build; a
// mixed panel keeps Search Center but loses the obsolete music applet.
function removeScrappedMusic() {
  var kept = [];
  for (var p = 0; p < allPanels.length; p++) {
    var widgets = allPanels[p].widgets();
    if (hasType(widgets, "com.blackcomb.dynamic-music")) {
      if (hasType(widgets, "com.blackcomb.search-center") || hasType(widgets, "com.blackcomb.emoji-panel")) {
        for (var m = 0; m < widgets.length; m++) {
          if (widgets[m].type === "com.blackcomb.dynamic-music") {
            widgets[m].remove();
            removed++;
          }
        }
        kept.push(allPanels[p]);
      } else {
        allPanels[p].remove();
        removed++;
      }
    } else {
      kept.push(allPanels[p]);
    }
  }
  allPanels = kept;
}
removeScrappedMusic();
for (var i = 0; i < allPanels.length; i++) {
  var panel = allPanels[i];
  var widgets = panel.widgets();
  var special = false;
  for (var w = 0; w < widgets.length; w++) {
    if (widgets[w].type === "com.blackcomb.search-center" || widgets[w].type === "com.blackcomb.emoji-panel") {
      special = true;
    }
  }
  removeStock(panel);
  if (!special) {
    allPanels[i].location = "left";
    moved++;
  }
  var seen = {};
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
  if (!special) {
    for (var k = 0; k < blackcombWidgets.length; k++) {
      addWidgetTo(panel, blackcombWidgets[k], seen);
    }
  }
}
// Search Center opens upward from a centered bottom panel. The Meta+. emoji
// and clipboard applet shares that panel instead of creating a second strip.
ensureCustomPanel("com.blackcomb.search-center", "bottom", "center", 44);
ensureCustomPanel("com.blackcomb.emoji-panel", "bottom", "center", 44, ["com.blackcomb.search-center"]);

// Remove the earlier desktop Media Player copy and any scrapped music widget.
for (var d = 0; d < allDesktops.length; d++) {
  removeStock(allDesktops[d]);
}
print("BLACKCOMB_OK:" + moved + ":" + icons + ":" + added + ":" + removed + ":" + customized);
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

layout_ok=0
if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  i=0
  while [ "$i" -lt 30 ]; do
    result=$(apply_live_layout 2>/dev/null || :)
    # A successful script always prints BLACKCOMB_OK. On a second run the moved
    # and icon counters can both be zero, so never use them as the success test.
    case "$result" in
      *BLACKCOMB_OK:*)
        layout_ok=1
        break
        ;;
    esac
    i=$((i + 1))
    sleep 1
  done
fi

# Only persist the panels here when Plasma scripting did not create them.
if [ "$layout_ok" -eq 0 ] && [ "$want_config_panels" -eq 0 ]; then
  append_custom_panels
fi

exit 0
