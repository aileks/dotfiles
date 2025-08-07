#!/usr/bin/env bash

# GTK Theme
git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/gruvbox
/tmp/gruvbox/themes/install.sh -s compact -c dark -d ~/.local/share/themes -l -t teal --tweaks float

# Icon Theme
sudo pacman -S --noconfirm --needed papirus-icon-theme
git clone https://github.com/xelser/gruvbox-papirus-folders.git /tmp/icons
sudo cp -r /tmp/icons/src/* /usr/share/icons/Papirus
/tmp/icons/papirus-folders -C gruvbox-original-purple --theme Papirus-Dark

# Plymouth Theme
yay -S --no-confirm --needed plymouth-theme-black-hud-git
