#!/usr/bin/env bash

set -e

source "$(dirname "$0")/common.sh"

print_info "Installing Gruvbox GTK Theme..."
sudo apt install -y gtk2-engines-murrine
git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/gruvbox
/tmp/gruvbox/themes/install.sh -s compact -c dark -d ~/.local/share/themes -l -t teal --tweaks float

print_info "Installing Papirus Icon Theme..."
sudo apt install -y papirus-icon-theme
git clone https://github.com/xelser/gruvbox-papirus-folders.git /tmp/icons
sudo /tmp/icons/install.sh

print_info "Applying theme and icon settings..."
gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Teal-Dark-Compact"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

papirus-folders -C gruvbox-original-purple --theme Papirus-Dark

print_info "Cleaning up temporary files..."
rm -rf /tmp/gruvbox
rm -rf /tmp/icons

print_success "Theme installation and setup complete!"
