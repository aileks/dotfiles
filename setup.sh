#!/usr/bin/env bash

set -e

# get dotdir (this directory)
DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# symlinks
ln -sf $DOTDIR/tmux/tmux.conf $HOME/.tmux.conf
ln -sf $DOTDIR/zsh/zshrc $HOME/.zshrc
rm -rf $HOME/.config/wezterm
ln -s $DOTDIR/wezterm $HOME/.config/wezterm
rm -rf $HOME/.config/fastfetch
ln -s $DOTDIR/fastfetch $HOME/.config/fastfetch
rm -rf $HOME/.config/helix
ln -s $DOTDIR/helix $HOME/.config/helix

# copy utils
echo "Copying utils..."
if [ -d "$HOME/.local/bin" ]; then
    cp -r ./utils/* $HOME/.local/bin
    echo "Files copied successfully to $HOME/.local/bin"
else
    echo "$HOME/.local/bin directory does not exist. Creating it..."
    mkdir -p "$HOME/.local/bin"
    cp -r ./utils/* "$HOME/.local/bin"
    echo "Files copied successfully to newly created $HOME/.local/bin"
fi
echo ""

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

echo "Dotfiles setup successfully!"
