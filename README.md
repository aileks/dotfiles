# Dotfiles

macOS dotfiles with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

Installs Xcode Command Line Tools, Homebrew, every package from [`Brewfile`](./Brewfile),
and symlinks configs into `~/.config` and `$HOME`. Uses `zsh` with antidote, and the
Ashen theme across kitty, bat, btop, starship, and fzf.

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
