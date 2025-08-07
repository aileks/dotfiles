#!/usr/bin/env bash

# Bare Necessities
yay -S --noconfirm --needed base-devel wget curl unzip inetutils fd eza fzf \
    ripgrep zoxide bat jq xmlstarlet wl-clipboard fastfetch btop man tldr \
    less whois plocate alacritty mise imagemagick postgresql-libs github-cli \
    docker docker-compose docker-buildx lazydocker-bin plymouth

# Limit log size to avoid running out of disk
sudo mkdir -p /etc/docker
echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"5"}}' | sudo tee /etc/docker/daemon.json

sudo usermod -aG docker ${USER}

# Prevent Docker from preventing boot for network-online.target
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/no-block-boot.conf <<'EOF'
[Unit]
DefaultDependencies=no
EOF
sudo systemctl daemon-reload

# Hyprland Basics
yay -S --noconfirm --needed hyprland hyprshot hyprpicker hyprlock hypridle \
    polkit-gnome hyprland-qtutils walker-bin libqalculate waybar \
    mako swaybg swayosd xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Desktop Utilities
sudo pacman -S --noconfirm --needed \
    brightnessctl playerctl pamixer wireplumber wl-clip-persist nautilus \
    ffmpegthumbnailer gvfs-mtp slurp satty celluoid papers imv bluez blueman

# Editors
sudo pacman -S --noconfirm --needed nvim luarocks tree-sitter-cli
curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh

# Browser
curl -fsS https://dl.brave.com/install.sh | sh

# Applications
yay -S --noconfirm --needed qalculate-gtk gnome-keyring signal-desktop \
    notesnook-bin localsend-bin
