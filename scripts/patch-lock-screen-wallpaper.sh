#!/bin/sh
# Make Kim Stargazer the default wallpaper for Plasma's session lock screen,
# Plasma Login Manager and SDDM's existing Breeze themes. Only configuration is
# changed: the standard Breeze theme is kept and no SVG/QML asset is created.
#
# Usage:
#   patch-lock-screen-wallpaper.sh [target-root] [--live-autologin]
#   patch-lock-screen-wallpaper.sh --file CONFIG
set -eu

image=file:///usr/share/backgrounds/blackcomb/kim-stargazer.png
background=/usr/share/backgrounds/blackcomb/kim-stargazer.png

# Rewrite only the keys that select the wallpaper, preserving other settings in
# the file. Works with the nested KConfig syntax used by Plasma 6.
patch_kconfig() {
  cfg=$1
  [ -n "$cfg" ] || return 0
  parent=${cfg%/*}
  [ "$parent" = "$cfg" ] && parent=.
  mkdir -p "$parent" 2>/dev/null || return 0
  [ -f "$cfg" ] || : > "$cfg" 2>/dev/null || return 0
  tmp="$cfg.blackcomb.tmp"

  awk -v image="$image" '
    function flush() {
      if (in_greeter) {
        if (!plugin_written) {
          print "WallpaperPlugin=org.kde.image"
          plugin_written = 1
        }
        if (!plugin_id_written) {
          print "WallpaperPluginId=org.kde.image"
          plugin_id_written = 1
        }
      }
      if (in_image) {
        if (!image_written) {
          print "Image=" image
          image_written = 1
        }
        if (!preview_written) {
          print "PreviewImage=" image
          preview_written = 1
        }
      }
    }
    /^\[/ {
      flush()
      header = $0
      sub(/[[:space:]]+$/, "", header)
      in_greeter = (header == "[Greeter]")
      in_image = (header == "[Greeter][Wallpaper][org.kde.image][General]")
      if (in_greeter) greeter_seen = 1
      if (in_image) image_seen = 1
      plugin_written = 0
      plugin_id_written = 0
      image_written = 0
      preview_written = 0
      print
      next
    }
    in_greeter && /^[[:space:]]*WallpaperPlugin[[:space:]]*=/ {
      print "WallpaperPlugin=org.kde.image"
      plugin_written = 1
      next
    }
    in_greeter && /^[[:space:]]*WallpaperPluginId[[:space:]]*=/ {
      print "WallpaperPluginId=org.kde.image"
      plugin_id_written = 1
      next
    }
    in_image && /^[[:space:]]*Image[[:space:]]*=/ {
      print "Image=" image
      image_written = 1
      next
    }
    in_image && /^[[:space:]]*PreviewImage[[:space:]]*=/ {
      print "PreviewImage=" image
      preview_written = 1
      next
    }
    { print }
    END {
      flush()
      if (!greeter_seen) {
        print ""
        print "[Greeter]"
        print "WallpaperPlugin=org.kde.image"
        print "WallpaperPluginId=org.kde.image"
      }
      if (!image_seen) {
        print ""
        print "[Greeter][Wallpaper][org.kde.image][General]"
        print "Image=" image
        print "PreviewImage=" image
      }
    }
  ' "$cfg" > "$tmp" 2>/dev/null || {
    rm -f "$tmp" 2>/dev/null || :
    return 0
  }

  cat "$tmp" > "$cfg" 2>/dev/null || :
  rm -f "$tmp" 2>/dev/null || :
}

# SDDM themes keep their background in theme.conf.user. Existing packaged
# themes are reused; no theme source or icon is replaced.
patch_theme_user() {
  cfg=$1
  [ -d "${cfg%/*}" ] || return 0
  [ -f "$cfg" ] || : > "$cfg" 2>/dev/null || return 0
  tmp="$cfg.blackcomb.tmp"

  awk -v background="$background" '
    function flush() {
      if (in_general) {
        if (!type_written) {
          print "type=image"
          type_written = 1
        }
        if (!background_written) {
          print "background=" background
          background_written = 1
        }
      }
    }
    /^\[/ {
      flush()
      header = $0
      sub(/[[:space:]]+$/, "", header)
      in_general = (header == "[General]")
      if (in_general) general_seen = 1
      type_written = 0
      background_written = 0
      print
      next
    }
    in_general && /^[[:space:]]*type[[:space:]]*=/ {
      print "type=image"
      type_written = 1
      next
    }
    in_general && /^[[:space:]]*background[[:space:]]*=/ {
      print "background=" background
      background_written = 1
      next
    }
    { print }
    END {
      flush()
      if (!general_seen) {
        print "[General]"
        print "type=image"
        print "background=" background
      }
    }
  ' "$cfg" > "$tmp" 2>/dev/null || {
    rm -f "$tmp" 2>/dev/null || :
    return 0
  }

  cat "$tmp" > "$cfg" 2>/dev/null || :
  rm -f "$tmp" 2>/dev/null || :
}

# Enforce live autologin in the authoritative main config after livesys-late has
# written its own settings. The --live-autologin flag keeps this off for any
# installed-system caller of this helper.
patch_autologin_group() {
  cfg=$1
  group=$2
  [ -n "$cfg" ] || return 0
  parent=${cfg%/*}
  [ "$parent" = "$cfg" ] && parent=.
  mkdir -p "$parent" 2>/dev/null || return 0
  [ -f "$cfg" ] || : > "$cfg" 2>/dev/null || return 0
  tmp="$cfg.blackcomb.tmp"

  awk -v group="$group" '
    function flush() {
      if (in_group) {
        if (!user_written) {
          print "User=liveuser"
          user_written = 1
        }
        if (!session_written) {
          print "Session=plasma.desktop"
          session_written = 1
        }
        if (!relogin_written) {
          print "Relogin=true"
          relogin_written = 1
        }
      }
    }
    /^\[/ {
      flush()
      header = $0
      sub(/[[:space:]]+$/, "", header)
      in_group = (header == group)
      if (in_group) group_seen = 1
      user_written = 0
      session_written = 0
      relogin_written = 0
      print
      next
    }
    in_group && /^[[:space:]]*User[[:space:]]*=/ {
      print "User=liveuser"
      user_written = 1
      next
    }
    in_group && /^[[:space:]]*Session[[:space:]]*=/ {
      print "Session=plasma.desktop"
      session_written = 1
      next
    }
    in_group && /^[[:space:]]*Relogin[[:space:]]*=/ {
      print "Relogin=true"
      relogin_written = 1
      next
    }
    { print }
    END {
      flush()
      if (!group_seen) {
        print ""
        print group
        print "User=liveuser"
        print "Session=plasma.desktop"
        print "Relogin=true"
      }
    }
  ' "$cfg" > "$tmp" 2>/dev/null || {
    rm -f "$tmp" 2>/dev/null || :
    return 0
  }

  cat "$tmp" > "$cfg" 2>/dev/null || :
  rm -f "$tmp" 2>/dev/null || :
}

if [ "${1:-}" = "--file" ]; then
  shift
  [ $# -ge 1 ] || exit 0
  patch_kconfig "$1"
  exit 0
fi

root=/
live_autologin=0
for arg in "$@"; do
  case "$arg" in
    --live-autologin) live_autologin=1 ;;
    --*) : ;;
    *) root=$arg ;;
  esac
done

# PLM's main config is authoritative: some releases ignore plasmalogin.conf.d.
patch_kconfig "$root/etc/plasmalogin.conf"
# System-wide and new-user lock screen defaults.
patch_kconfig "$root/etc/xdg/kscreenlockerrc"
if [ -d "$root/etc/skel" ]; then
  patch_kconfig "$root/etc/skel/.config/kscreenlockerrc"
fi
# Fedora's profile default and an existing live user are patched only when they
# exist, so this script never invents home directories on an installed system.
if [ -f "$root/usr/share/kde-settings/kde-profile/default/xdg/kscreenlockerrc" ]; then
  patch_kconfig "$root/usr/share/kde-settings/kde-profile/default/xdg/kscreenlockerrc"
fi
if [ -d "$root/home/liveuser" ]; then
  patch_kconfig "$root/home/liveuser/.config/kscreenlockerrc"
fi

# livesys-late writes display-manager settings before the greeter starts. Fix
# the main files as well as the drop-ins so autologin cannot be overwritten by
# that ordering on either PLM or SDDM.
if [ "$live_autologin" -eq 1 ]; then
  patch_autologin_group "$root/etc/plasmalogin.conf" '[Autologin]'
  patch_autologin_group "$root/etc/plasmalogin.conf" '[Autologin][seat0]'
  patch_autologin_group "$root/etc/sddm.conf" '[Autologin]'
fi

# Keep the SDDM fallback consistent on media that still ships it.
for theme_dir in "$root/usr/share/sddm/themes"/*; do
  [ -d "$theme_dir" ] || continue
  patch_theme_user "$theme_dir/theme.conf.user"
done

exit 0
