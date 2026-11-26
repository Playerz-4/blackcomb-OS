#!/bin/sh
# Keep a Kim/Blackcomb wallpaper selected in the Plasma desktop.
#
# Fedora's Breeze global theme normally advertises the Fedora wallpaper as its
# default, so applying Global Theme or Defaults can put that image back over a
# user's choice. patch-breeze-wallpaper.sh changes that theme default to the Kim
# Stargazer package. This helper handles the remaining case: it remembers the
# last non-default image the user selects and restores it only when the desktop
# falls back to the Fedora/Next default. Deliberate wallpaper choices are never
# overwritten.
set -eu

default_image=file:///usr/share/backgrounds/blackcomb/kim-stargazer.png
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/blackcomb"
marker="$state_dir/wallpaper-initialized"
selection="$state_dir/wallpaper-selection"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

mkdir -p "$state_dir" 2>/dev/null || :

dbus_eval() {
  script=$1
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.plasmashell /PlasmaShell \
      org.kde.PlasmaShell.evaluateScript "$script"
  elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.plasmashell /PlasmaShell \
      org.kde.PlasmaShell.evaluateScript "$script"
  elif command -v dbus-send >/dev/null 2>&1; then
    dbus-send --session --print-reply --dest=org.kde.plasmashell \
      /PlasmaShell org.kde.PlasmaShell.evaluateScript string:"$script"
  else
    return 1
  fi
}

set_image() {
  image=$1
  script="for (var key in desktops()) { var d = desktops()[key]; d.wallpaperPlugin = 'org.kde.image'; d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General']; d.writeConfig('Image', '$image'); } print('BLACKCOMB_WALLPAPER_OK');"
  result=$(dbus_eval "$script" 2>/dev/null || :)
  case "$result" in
    *BLACKCOMB_WALLPAPER_OK*) return 0 ;;
    *) return 1 ;;
  esac
}

# At autostart the Plasma scripting bridge can be unavailable longer than the
# original retry window. Write the saved layout directly as a fallback so the
# desktop still has the Kim image on the next Plasma start. This also seeds a
# missing config at build time; without it Plasma can start with no wallpaper.
patch_config_file() {
  target=$1
  [ -n "$target" ] || return 0
  target_dir=${target%/*}
  [ "$target_dir" = "$target" ] && target_dir=.
  mkdir -p "$target_dir" 2>/dev/null || return 0
  if [ ! -f "$target" ]; then
    cat > "$target" <<EOF 2>/dev/null || return 0
[Containments][1]
activityId=
formfactor=0
lastScreen=0
location=0
plugin=org.kde.plasma.desktop
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=$default_image
EOF
    return 0
  fi
  tmp="$target.blackcomb.tmp"
  awk -v image="$default_image" '
    function flush() {
      if (in_wallpaper && !image_written) {
        print "Image=" image
        image_written = 1
      }
    }
    /^\[Containments\]\[[^]]+\]\[Wallpaper\]\[org\.kde\.image\]\[General\]$/ {
      flush()
      in_wallpaper = 1
      group_seen = 1
      image_written = 0
      print
      next
    }
    /^\[/ {
      flush()
      in_wallpaper = 0
      image_written = 0
      print
      next
    }
    in_wallpaper && /^[[:space:]]*Image[[:space:]]*=/ {
      print "Image=" image
      image_written = 1
      next
    }
    { print }
    END {
      flush()
      if (!group_seen) {
        print ""
        print "[Containments][1][Wallpaper][org.kde.image][General]"
        print "Image=" image
      }
    }
  ' "$target" > "$tmp" 2>/dev/null || {
    rm -f "$tmp" 2>/dev/null || :
    return 0
  }
  cat "$tmp" > "$target" 2>/dev/null || :
  rm -f "$tmp" 2>/dev/null || :
}

set_image_config() {
  patch_config_file "$cfg"
}

wallpaper_values() {
  awk -F= '
    /^\[Containments\]\[[^]]+\]$/ {
      group=$0
      sub(/^\[/, "", group)
      sub(/\]$/, "", group)
      containment=group
      plugin=""
      wallpaper=0
      next
    }
    /^\[Containments\]\[[^]]+\]\[Wallpaper\]\[org\.kde\.image\]\[General\]$/ {
      if (plugin == "org.kde.plasma.desktop") wallpaper=1
      next
    }
    /^\[/ { wallpaper=0; next }
    containment != "" && $1 == "plugin" { plugin=$2; next }
    wallpaper && $1 == "Image" { print substr($0, index($0, "=") + 1) }
  ' "$cfg" 2>/dev/null || :
}

is_default_wallpaper() {
  case "$1" in
    ''|*[Ff]edora*|*/Next|*/Next/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Build-time mode: seed a saved Plasma layout with the Kim image without
# waiting for a D-Bus session or starting the long-running guard.
if [ "${1:-}" = "--file" ]; then
  shift
  [ $# -ge 1 ] || exit 0
  patch_config_file "$1"
  exit 0
fi

# Plasma's desktop service may not be available immediately at autostart. Use
# both the live D-Bus path and the saved-config fallback for up to two minutes.
i=0
while [ "$i" -lt 24 ]; do
  if set_image "$default_image" || set_image_config "$default_image"; then
    printf '%s\n' "$default_image" > "$selection" 2>/dev/null || :
    touch "$marker" 2>/dev/null || :
    break
  fi
  i=$((i + 1))
  sleep 5
done
[ -e "$marker" ] || exit 1

# Keep the wallpaper from being silently replaced by the global theme's old
# Fedora default. Remember every non-default choice, and only rewrite the known
# fallback values.
while :; do
  sleep 10
  [ -f "$cfg" ] || continue

  values=$(wallpaper_values)
  saved=$(cat "$selection" 2>/dev/null || :)
  [ -n "$saved" ] || saved=$default_image

  user_value=
  while IFS= read -r value; do
    [ -n "$value" ] || continue
    if ! is_default_wallpaper "$value"; then
      user_value=$value
      break
    fi
  done <<EOF
$values
EOF

  if [ -n "$user_value" ]; then
    if [ "$user_value" != "$saved" ]; then
      printf '%s\n' "$user_value" > "$selection" 2>/dev/null || :
    fi
    continue
  fi

  # No user choice is present: the theme has fallen back to its default.
  set_image "$saved" >/dev/null 2>&1 || :
done
