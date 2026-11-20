# Vendored neofetch

Fedora 45 does not ship `neofetch` in its base repositories, so Blackcomb
bundles upstream neofetch 7.1.0 (MIT licensed) to guarantee the command is
available after setup and in the live session.

- Source: https://github.com/dylanaraps/neofetch
- Pinned upstream commit: `ccd5d9f52609bbdcd5d8fa78c4fdb0f12954125f` (master, 2021-12-10)
- License: see `LICENSE.md`

Blackcomb installs the script to `/usr/local/lib/blackcomb/neofetch/neofetch`
and provides `/usr/local/bin/neofetch` as a wrapper that selects the crescent
PNG (via chafa) or the bundled ASCII rendering of that PNG.
