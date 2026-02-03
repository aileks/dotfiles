# Arch Linux Dotfiles

Arch setup built on COSMIC with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Features

- **Desktop**: COSMIC
- **Terminal**: WezTerm
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

This setup assumes systemd for user services. If you are on a systemd-less distro, clone the repo manually and run the install script with `--no-systemd`.

## Resources

- [COSMIC](https://github.com/pop-os/cosmic-epoch)
- [keyd](https://github.com/rvaiya/keyd)
