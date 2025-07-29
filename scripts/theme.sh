#!/usr/bin/env bash

echo "Installing Gruvbox GTK Theme..."
git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/gruvbox
/tmp/gruvbox/themes/install.sh -s compact -c dark -d ~/.local/share/themes -l -t teal --tweaks float

echo "Installing Gruvbox Papirus Folders..."
git clone https://github.com/xelser/gruvbox-papirus-folders.git /tmp/icons
sudo cp -r /tmp/icons/src/* /usr/share/icons/Papirus/
/tmp/icons/papirus-folders -C gruvbox-original-purple --theme Papirus-Dark

echo "Cleaning up..."
rm -rf /tmp/gruvbox
rm -rf /tmp/icons

echo "Theme installation complete!"
