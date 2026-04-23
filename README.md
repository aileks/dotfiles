# Dotfiles

macOS dotfiles with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Install

```bash
curl -fsSL https://aileks.dev/mac | bash
```

Or manually:

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
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
