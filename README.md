# Arch Linux Dotfiles

## Quick Start

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or manually:

```bash
git clone https://github.com/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

## What's Included

| Component     | Tool             |
| ------------- | ---------------- |
| WM            | dwm-flexipatch   |
| Status bar    | dwmblocks        |
| Terminal      | WezTerm          |
| Launcher      | Rofi             |
| Compositor    | Picom            |
| Notifications | Dunst            |
| Locker        | Betterlockscreen |
| Shell         | Zsh              |
| File manager  | Yazi, pcmanfm    |

## Usage

```bash
./install.sh              # Interactive menu
./install.sh 1            # Full setup
./install.sh 2            # Symlink only
./install.sh --dry-run 1  # Preview changes
```

After install: log out, then `startx`.

## Key Bindings

| Key            | Action             |
| -------------- | ------------------ |
| `Mod+Return`   | Terminal           |
| `Mod+d`        | Rofi (apps)        |
| `Mod+hjkl`     | Focus by direction |
| `Mod+Shift+jk` | Move in stack      |
| `Mod+Tab`      | Rotate stack       |
| `Mod+Shift+q`  | Close window       |
| `Mod+x`        | Lock screen        |
| `Mod+1-9`      | Switch tag         |
| `Print`        | Screenshot         |

## Ashen Palette

No green. Orange substitutes.

| Color        | Hex       | Use            |
| ------------ | --------- | -------------- |
| Background   | `#121212` | Base           |
| Foreground   | `#d5d5d5` | Text           |
| Orange Blaze | `#C4693D` | Borders, focus |
| Red Ember    | `#B14242` | Errors, urgent |
| Blue         | `#4A8B8B` | Info, links    |

## Structure

```
├── dwm/           # dwm-flexipatch
├── dwmblocks/     # status bar
├── scripts/       # autostart, statusbar scripts
├── wezterm/       # terminal config
├── rofi/          # launcher + theme
├── picom/         # compositor
├── dunst/         # notifications
├── setup.sh       # bootstrap
└── install.sh     # main installer
```

## License

MIT
