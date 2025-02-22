#!/usr/bin/env bash

set -e

# get dotdir (this directory)
DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# symlinks
ln -sf $DOTDIR/tmux/tmux.conf $HOME/.tmux.conf
ln -sf $DOTDIR/zsh/zshrc $HOME/.zshrc
rm -rf $HOME/.config/picom
ln -s $DOTDIR/picom $HOME/.config/picom
rm -rf $HOME/.config/wezterm
ln -s $DOTDIR/wezterm $HOME/.config/wezterm
rm -rf $HOME/.config/dunst
ln -s $DOTDIR/dunst $HOME/.config/dunst
rm -rf $HOME/.config/dwm
ln -s $DOTDIR/dwm $HOME/.config/dwm
rm -rf $HOME/.config/fastfetch
ln -s $DOTDIR/fastfetch $HOME/.config/fastfetch
rm -rf $HOME/.config/helix
ln -s $DOTDIR/helix $HOME/.config/helix
rm -rf $HOME/GNUstep/Library/WindowMaker/autostart
ln -s $DOTDIR/GNUstep $HOME/GNUstep/Library/WindowMaker/autostart
rm -rf $HOME/GNUstep/Library/WindowMaker/Backgrounds
ln -s $DOTDIR/GNUstep $HOME/GNUstep/Library/WindowMaker/Backgrounds

# install omz
echo "Installing Oh My Zsh"
echo ""
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# install tmp
echo "Installing tmux package manager"
echo ""
if [ ! -d "$HOME/.tmux" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Files Successfully Copied"
echo ""
