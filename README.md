# dotfiles

Opinionated setup for an existing Ubuntu 26.04+ installation.

## What it does

- Installs desktop software and command-line tools using `apt`, [pacstall](https://pacstall.dev/), and flatpak.
- Installs GNOME extensions and QoL settings.
- Installs nerd fonts.
- Removes Snap packages, Snap data, and `snapd`.
- Configures DDC/CI monitor controls.
- Symlinks the included zsh, neovim, alacritty, and other dotfiles, backing up conflicts first.

## Usage

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```
