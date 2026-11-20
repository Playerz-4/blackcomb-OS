# OpenCode Plasma color schemes

Blackcomb ships KDE Plasma color schemes converted from OpenCode's official
built-in TUI theme palettes, including Catppuccin, Catppuccin Frappe,
Catppuccin Macchiato, Dracula, Nord, TokyoNight and the rest of the bundled
set. Light variants are included where the upstream theme defines a distinct
light palette.

The files in `source/` are copied from
`packages/tui/src/theme/assets/*.json` at
<https://github.com/anomalyco/opencode/tree/85951cb08614dfe6443905552cae49d59d2d6615/packages/tui/src/theme/assets>.

The generated `OpenCode-*.colors` files are installed to
`/usr/share/color-schemes/`, where Plasma and System Settings discover them
automatically. Regenerate them with:

```sh
python3 scripts/generate-opencode-themes.py
```

Use `python3 scripts/generate-opencode-themes.py --check` to verify that the
committed files match the bundled sources. The default live and post-install
scheme is `OpenCode-Catppuccin`.

These are color schemes only. They do not change wallpapers, icons or any SVG
artwork.
