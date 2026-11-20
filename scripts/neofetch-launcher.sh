#!/bin/sh
# Run the bundled neofetch with the Blackcomb crescent logo. Use the real PNG
# through chafa when chafa and ImageMagick are available, otherwise use the
# bundled ASCII rendering of the same image so the command works on the live
# ISO too.
set -eu
lib=/usr/local/lib/blackcomb/neofetch

if command -v chafa >/dev/null 2>&1 && \
   command -v convert >/dev/null 2>&1 && \
   command -v identify >/dev/null 2>&1 && \
   [ -f /usr/share/blackcomb/branding/crescent-moon-start-icon.png ]; then
  config="$lib/chafa.conf"
else
  config="$lib/ascii.conf"
fi

exec "$lib/neofetch" --config "$config" "$@"
