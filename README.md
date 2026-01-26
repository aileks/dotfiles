# Arch Linux Dotfiles

Arch setup built on River with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Features

- **WM**: River (Wayland)
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

### Lock on Suspend

```bash
sudo systemctl enable betterlockscreen@$USER
```

## Resources

- [River](https://github.com/riverwm/river)
- [Waybar](https://github.com/Alexays/Waybar)
- [Arch Wiki - River](https://wiki.archlinux.org/title/River)
- [keyd](https://github.com/rvaiya/keyd)
