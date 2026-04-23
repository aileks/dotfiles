# Dotfiles

macOS dotfiles with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Install

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup-macos.sh
```

Installs Xcode Command Line Tools, Homebrew, every package from `Brewfile`
(CLI tools + GUI casks + Nerd Font), and symlinks configs into `~/.config`
and `$HOME`. Uses `zsh` (antidote) with the Ashen theme across kitty, bat,
btop, starship, and fzf.

## Manual package sync

```bash
brew bundle install --file=~/.dotfiles/Brewfile   # install anything missing
brew bundle cleanup --file=~/.dotfiles/Brewfile   # show what's extra
```

## Tahoe notes

- First launch of each cask app: approve in System Settings → Privacy & Security.
- If Homebrew breaks after a macOS upgrade, check `/Users/Shared/Relocated Items/`
  and run `brew update-reset`.
