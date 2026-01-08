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
- **Editor**: Neovim
- **File manager**: Yazi
- **PDF viewer**: Zathura

## Requirements

- Arch Linux (or Arch-based distro)
- Display manager: [ly](https://github.com/fairyglade/ly)
- 4K monitor recommended (tweak DPI otherwise)

### Dependencies

```bash
sudo pacman -S base-devel git xorg xorg-xinit picom dunst rofi feh \
    pamixer playerctl maim xclip xdotool networkmanager wezterm \
    zathura zathura-pdf-mupdf ly

paru -S betterlockscreen ttf-adwaita-mono-nerd
```

## Quick Start

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or manually:

```bash
git clone --recursive https://github.com/aileks/arch-config.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Usage

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
