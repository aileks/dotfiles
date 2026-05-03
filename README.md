# Arch Linux Dotfiles

Arch setup built on Niri with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Quick Start

```bash
curl -fsSL https://aileks.dev/dotfiles | bash
```

Or manually:

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```
## Systemd

This setup requires systemd to work with Niri nicely. If you are on a systemd-less distro, clone the repo manually and run the install script with `--no-systemd`.  
You will have to edit the Niri config to launch these services as background processes instead.
