# Cinder Grove for Omarchy

This local Omarchy port uses the palette and integrations from:

- https://github.com/aileks/cinder-grove.nvim at `1070650448b9c63fd7cca9ca8656ec9432dd16e1`
- https://github.com/aileks/cinder-grove-gtk at `a1a74295d6dcc235623a72fc024bdeff3134c5a9`

Omarchy generates its terminal, shell, Hyprland, btop, browser, and editor
support from `colors.toml`. Neovim is themed separately by the
`cinder-grove.nvim` plugin loaded in `nvim/lua/plugins/colors.lua`.

## Palette

Fifteen colors, mirroring `palette.lua` in cinder-grove.nvim:

| Role | Hex |
|------|-----|
| background | `#131210` |
| container (`dark_background`) | `#1B1916` |
| surface (`lighter_background`) | `#23201C` |
| overlay / muted / selection | `#58534C` |
| text | `#BBB3A9` |
| text_secondary (`light_foreground`) | `#ACA49B` |
| text_subtle | `#9A938A` |
| text_bright | `#DDD5CA` |
| primary (`accent`, orange) | `#E17A3F` |
| secondary / success (green) | `#879B5C` |
| error (red) | `#B34A45` |
| warning (yellow) | `#D9A441` |
| info (blue) | `#6785A1` |
| purple (magenta) | `#9A788F` |
| cyan | `#58918C` |

The orange `#E17A3F` is the primary accent and the only active border color:
`colors.toml` leaves `hyprland_active_border` unset so every border surface
(Hyprland window/group borders, popups, notifications, launcher, menu, polkit,
lock) resolves to `accent` from one place. Inactive borders use the palette
overlay `#58534C` at reduced alpha.
