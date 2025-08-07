#!/usr/bin/env bash

# Bare Necessities
yay -S --noconfirm --needed wget curl unzip inetutils impala fd eza fzf \
    ripgrep zoxide bat jq xmlstarlet wl-clipboard fastfetch btop man tldr \
    less whois plocate bash-completion alacritty mise imagemagick postgresql-libs \
    github-cli docker docker-compose docker-buildx lazydocker-bin

# Limit log size to avoid running out of disk
sudo mkdir -p /etc/docker
echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"5"}}' | sudo tee /etc/docker/daemon.json

sudo systemctl enable docker
sudo usermod -aG docker ${USER}

# Prevent Docker from preventing boot for network-online.target
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/no-block-boot.conf <<'EOF'
[Unit]
DefaultDependencies=no
EOF
sudo systemctl daemon-reload

# Hyprland Basics
yay -S --noconfirm --needed hyprland hyprshot hyprpicker hyprlock \
    hypridle polkit-gnome hyprland-qtutils walker-bin libqalculate \
    waybar mako swaybg swayosd xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Desktop Utilities
sudo pacman -S --noconfirm --needed \
    brightnessctl playerctl pamixer wireplumber wl-clip-persist nautilus \
    ffmpegthumbnailer gvfs-mtp slurp satty celluoid papers imv bluez blueman

# Neovim
sudo pacman -S --noconfirm --needed nvim luarocks tree-sitter-cli
