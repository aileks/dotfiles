# Arch Linux Dotfiles

Arch setup built on Niri with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Features

- **WM**: Niri
- **Status bar**: Waybar
- **Terminal**: WezTerm
- **Launcher**: Fuzzel
- **Notifications**: Mako
- **Lockscreen**: Swaylock
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
./setup.sh
```

## Install Script Flags

```bash
./install.sh              # Interactive menu
./install.sh 1            # Full setup (symlinks + build)
./install.sh 2            # Symlink only
./install.sh --dry-run 1  # Preview changes
```

## Systemd

This setup requires systemd to work with Niri nicely. If you are on a systemd-less distro, clone the repo manually and run the install script with `--no-systemd`.  
You will have to edit the Niri config to launch these services as background processes instead.

## Resources

- [Niri](https://github.com/YaLTeR/niri)
- [Waybar](https://github.com/Alexays/Waybar)
- [Niri Docs](https://yalter.github.io/niri/)
- [keyd](https://github.com/rvaiya/keyd)
