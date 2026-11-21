#!/bin/sh
# Install Blackcomb's recommended application bundle on Fedora 45.
set -eu
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo "$0" "$@"
  fi
  echo 'Run as root (or install sudo).' >&2
  exit 1
fi
command -v dnf >/dev/null 2>&1 || { echo 'DNF is required.' >&2; exit 1; }
exec dnf install -y firefox vlc libreoffice-writer kcalc chafa imagemagick
