# Arch Linux Dotfiles

Desktop environment built on DWM-Flexipatch with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Features

- **WM**: DWM w/ Flexipatch
- **Status bar**: dwmblocks with colored status2d modules
- **Terminal**: WezTerm
- **Launcher**: Rofi
- **Compositor**: Picom
- **Notifications**: Dunst
- **Lockscreen**: Betterlockscreen
- **Shell**: Zsh
- **Editor**: Emacs
- **File manager**: Yazi
- **PDF viewer**: Zathura

List of keybinds here [here](https://github.com/aileks/dotfiles/wiki)

## Quick Start

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or manually:

```bash
git clone --recursive https://github.com/aileks/dotfiles.git ~/.dotfiles
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

- [DWM-Flexipatch](https://github.com/bakkeby/dwm-flexipatch)
- [dwmblocks](https://github.com/torrinfail/dwmblocks)
- [Arch Wiki - DWM](https://wiki.archlinux.org/title/dwm)
- [keyd](https://github.com/rvaiya/keyd)
