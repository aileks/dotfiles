# Arch Linux Dotfiles

Arch setup built on Niri with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Features

- **WM**: Niri (Wayland)
- **Status bar**: Waybar
- **Terminal**: WezTerm
- **Launcher**: Fuzzel
- **Notifications**: Mako
- **Lockscreen**: Waylock
- **Wallpaper**: Swaybg
- **Shell**: Zsh
- **Editor**: [Emacs](https://codeberg.org/aileks/emacs.d)
- **File manager**: Yazi
- **PDF viewer**: Zathura
- **Media player**: mpv

List of keybinds here [here](https://codeberg.org/aileks/dotfiles/wiki)

## Quick Start

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or manually:

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Flags

```bash
./install.sh              # Interactive menu
./install.sh 1            # Full setup (symlinks + build)
./install.sh 2            # Symlink only
./install.sh --dry-run 1  # Preview changes
```

## MPV

Config lives in `~/.config/mpv` (symlinked from `~/.dotfiles/mpv`). OSC theme uses mpv-osc-modern.

### Lock on Suspend

```bash
sudo systemctl enable betterlockscreen@$USER
```

## Resources

- [Niri](https://github.com/YaLTeR/niri)
- [Waybar](https://github.com/Alexays/Waybar)
- [Niri Docs](https://yalter.github.io/niri/)
- [keyd](https://github.com/rvaiya/keyd)
