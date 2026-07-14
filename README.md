# My Dotfiles

Opinionated setup for an existing Ubuntu 26.04 installation.

## What it does

- Installs desktop software and command-line tools using `apt`, [Pacstall](https://pacstall.dev/), and Flatpak.
- Installs `uv`, `nvm`, and common CLI utilities.
- Installs GNOME extensions and updates settings for better QoL.
- Installs Adwaita and JetBrains nerd fonts.
- Completely nukes Snaps and `snapd`.
- Configures DDC/CI monitor controls.
- Symlinks the included zsh, Neovim, Alacritty, and other dotfiles, backing up conflicts first.

## Usage

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or clone and run it directly:

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```
