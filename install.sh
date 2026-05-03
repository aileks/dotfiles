#!/bin/bash

set -uo pipefail

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
MINIFORGE_PREFIX="$HOME/miniforge3"

declare -a SETUP_ERRORS=()

# ============================================================
# Logging
# ============================================================

log_info()    { echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"; }
log_success() { echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"; }
log_warning() { echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"; }
log_error()   { echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"; }

record_error() {
  log_error "$1"
  SETUP_ERRORS+=("$1")
}

command_exists()   { command -v "$1" &>/dev/null; }

prompt_yes_no() {
  local prompt="$1" default="${2:-N}" reply
  if ! read -r -p "$prompt [$default/y]: " reply; then reply="$default"; fi
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy]$ ]]
}

check_os() {
  if ! [[ -r /etc/os-release ]] || ! grep -qiE '^ID=arch' /etc/os-release; then
    log_error "Unsupported OS. This script requires Arch Linux."
    exit 1
  fi
}

# ============================================================
# Package Lists
# ============================================================

PACMAN_PACKAGES=(
  base-devel git curl wget
  zsh tmux vim neovim satty starship
  openssh ufw man-db man-pages
  reflector pacman-contrib
  xdg-user-dirs
  trash-cli shfmt jq
  fastfetch btop eza bat fd ripgrep fzf zoxide

  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  pavucontrol pamixer playerctl
  network-manager-applet blueman

  niri xorg-xwayland xwayland-satellite
  kitty nwg-look
  fuzzel mako swaybg swaylock swayidle
  waybar
  grim slurp wl-clipboard
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
  polkit-gnome
  gnome-keyring
  libnotify gammastep
  brightnessctl
  ly

  nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
  egl-wayland linux-headers dkms

  flatpak

  thunar thunar-volman thunar-archive-plugin
  tumbler ffmpegthumbnailer
  file-roller
  gvfs gvfs-mtp gvfs-gphoto2 udiskie
  yazi
  imv qalculate-gtk zathura zathura-pdf-mupdf
  wf-recorder
  solaar

  ttf-jetbrains-mono-nerd
  noto-fonts noto-fonts-emoji noto-fonts-cjk
  papirus-icon-theme
  qt5ct qt6ct kvantum

  celluloid
  signal-desktop
  bitwarden bitwarden-cli
  code zed
  calcurse
)

AUR_PACKAGES=(
  zen-browser-bin
  onlyoffice-bin
  wlogout
  fastmail
  notesnook-bin
  bemoji
  wiremix
  zsh-antidote
  ttf-commit-mono-nerd
  adw-gtk-theme
  nwg-look-bin
)

# ============================================================
# Yay (AUR helper)
# ============================================================

install_yay() {
  if command_exists yay; then
    log_success "yay already installed"
    return 0
  fi

  log_info "Installing yay from AUR..."
  local tmpdir
  tmpdir=$(mktemp -d)
  if ! git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"; then
    record_error "Failed to clone yay-bin"
    rm -rf "$tmpdir"
    return 1
  fi

  pushd "$tmpdir/yay-bin" &>/dev/null || return 1
  if ! makepkg -si --noconfirm; then
    record_error "Failed to build/install yay"
    popd &>/dev/null || true
    rm -rf "$tmpdir"
    return 1
  fi
  popd &>/dev/null || true
  rm -rf "$tmpdir"
  log_success "yay installed"
}

# ============================================================
# Package Installation
# ============================================================

install_pacman_packages() {
  log_info "Refreshing pacman databases..."
  sudo pacman -Sy --noconfirm || record_error "Failed to sync pacman databases"

  log_info "Installing pacman packages..."
  if ! sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"; then
    record_error "Failed to install some pacman packages"
    return 1
  fi
  log_success "pacman packages installed"
}

install_aur_packages() {
  if ! command_exists yay; then
    record_error "yay unavailable; skipping AUR packages"
    return 1
  fi

  log_info "Installing AUR packages..."
  if ! yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
    record_error "Failed to install some AUR packages"
    return 1
  fi
  log_success "AUR packages installed"
}

setup_ly() {
  log_info "Enabling system services..."
  sudo systemctl disable getty@tty2.service
  sudo systemctl enable ly@tty2.service
}


# ============================================================
# Data Tools
# ============================================================

install_data_tools() {
  log_info "Setting up data science tools..."

  if command_exists uv; then
    log_success "uv already installed"
  else
    log_info "Installing uv..."
    if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
      record_error "Failed to install uv"
    fi
  fi

  if [[ -x "$MINIFORGE_PREFIX/bin/conda" ]]; then
    log_success "Miniforge already installed"
    return 0
  fi

  log_info "Installing Miniforge..."
  local tmpdir installer url
  tmpdir=$(mktemp -d)
  installer="$tmpdir/Miniforge3-$(uname)-$(uname -m).sh"
  url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"

  if ! curl -L -o "$installer" "$url"; then
    record_error "Failed to download Miniforge installer"
    rm -rf "$tmpdir"
    return 1
  fi

  if bash "$installer" -b -p "$MINIFORGE_PREFIX"; then
    "$MINIFORGE_PREFIX/bin/conda" config --set auto_activate_base false \
      || record_error "Failed to configure conda auto-activate"
    log_success "Miniforge installed"
  else
    record_error "Failed to install Miniforge"
  fi
  rm -rf "$tmpdir"
}

# ============================================================
# NVIDIA post-install reminder
# ============================================================

setup_nvidia() {
  local profile_dir=/etc/nvidia/nvidia-application-profiles-rc.d
  local profile_file="$profile_dir/50-limit-free-buffer-pool-in-wayland-compositors.json"

  if [[ -f $profile_file ]]; then
    log_success "NVIDIA niri VRAM profile already present"
  else
    log_info "Installing NVIDIA niri VRAM-mitigation profile..."
    if sudo install -d -m 0755 "$profile_dir" && sudo tee "$profile_file" >/dev/null <<'EOF'
{
    "rules": [
        {
            "pattern": {
                "feature": "procname",
                "matches": "niri"
            },
            "profile": "Limit Free Buffer Pool On Wayland Compositors"
        }
    ],
    "profiles": [
        {
            "name": "Limit Free Buffer Pool On Wayland Compositors",
            "settings": [
                {
                    "key": "GLVidHeapReuseRatio",
                    "value": 0
                }
            ]
        }
    ]
}
EOF
    then
      log_success "NVIDIA niri VRAM profile installed"
    else
      record_error "Failed to install NVIDIA niri VRAM profile"
    fi
  fi

  echo
  log_warning "NVIDIA driver installed (nvidia-open-dkms)."
  log_warning "Manual steps required before reboot:"
  echo -e "  ${LOG_YELLOW}1.${LOG_NC} Add ${LOG_GREEN}nvidia-drm.modeset=1${LOG_NC} to your kernel cmdline."
  echo -e "     (GRUB: /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT, then grub-mkconfig.)"
  echo -e "     (systemd-boot: /boot/loader/entries/*.conf options line.)"
  echo -e "  ${LOG_YELLOW}2.${LOG_NC} In /etc/mkinitcpio.conf set:"
  echo -e "     ${LOG_GREEN}MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)${LOG_NC}"
  echo -e "     then run: ${LOG_GREEN}sudo mkinitcpio -P${LOG_NC}"
  echo -e "  ${LOG_YELLOW}3.${LOG_NC} Reboot."
  echo
}

# ============================================================
# Zsh legacy cleanup
# ============================================================

migrate_zsh_legacy() {
  local zplug_dir="$HOME/.zplug"
  local ashen_plugin="$HOME/.zsh/plugins/ashen_zsh_syntax_highlighting.zsh"

  if [[ -d $zplug_dir ]]; then
    log_info "Removing legacy ~/.zplug (replaced by antidote)..."
    rm -rf "$zplug_dir" || record_error "Failed to remove $zplug_dir"
  fi
  if [[ -f $ashen_plugin ]]; then
    log_info "Removing legacy ashen syntax highlighting plugin..."
    rm -f "$ashen_plugin" || record_error "Failed to remove $ashen_plugin"
  fi
}

# ============================================================
# Symlinks
# ============================================================

create_symlink() {
  local source="$1" target="$2"

  if [[ ! -e $source ]]; then
    record_error "Source missing: $source"
    return 1
  fi

  if [[ -L $target && "$(readlink "$target")" == "$source" ]]; then
    log_success "Already linked: $target"
    return 0
  fi

  if [[ -L $target ]]; then
    rm "$target"
  elif [[ -e $target ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/$(basename "$target")"
  fi

  mkdir -p "$(dirname "$target")"
  if ! ln -sf "$source" "$target"; then
    record_error "Failed to link $target -> $source"
  else
    log_success "Linked: $target"
  fi
}

symlink_configs() {
  log_info "Creating config symlinks..."
  mkdir -p "$HOME/.config"

  create_symlink "$SCRIPT_DIR/niri"      "$HOME/.config/niri"
  create_symlink "$SCRIPT_DIR/waybar"    "$HOME/.config/waybar"
  create_symlink "$SCRIPT_DIR/mako"      "$HOME/.config/mako"
  create_symlink "$SCRIPT_DIR/fuzzel"    "$HOME/.config/fuzzel"
  create_symlink "$SCRIPT_DIR/swaylock"  "$HOME/.config/swaylock"
  create_symlink "$SCRIPT_DIR/btop"      "$HOME/.config/btop"
  create_symlink "$SCRIPT_DIR/kitty"     "$HOME/.config/kitty"
  create_symlink "$SCRIPT_DIR/nvim"      "$HOME/.config/nvim"
  create_symlink "$SCRIPT_DIR/zed"       "$HOME/.config/zed"
  create_symlink "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/bat"       "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  create_symlink "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
}

# ============================================================
# Systemd user units
# ============================================================

install_systemd_units() {
  local src_dir="$SCRIPT_DIR/systemd"
  local dest_dir="$HOME/.config/systemd/user"

  if [[ ! -d $src_dir ]]; then
    log_warning "No systemd/ directory found; skipping user units"
    return 0
  fi

  log_info "Linking systemd user units..."
  mkdir -p "$dest_dir"

  shopt -s nullglob
  local unit_files=("$src_dir"/*.service "$src_dir"/*.target "$src_dir"/*.timer "$src_dir"/*.socket)
  shopt -u nullglob

  if [[ ${#unit_files[@]} -eq 0 ]]; then
    log_warning "systemd/ is empty; skipping"
    return 0
  fi

  local enabled_any=0
  for unit in "${unit_files[@]}"; do
    local name; name=$(basename "$unit")
    create_symlink "$unit" "$dest_dir/$name"
    enabled_any=1
  done

  if [[ $enabled_any -eq 1 ]]; then
    systemctl --user daemon-reload || record_error "systemctl --user daemon-reload failed"
    for unit in "${unit_files[@]}"; do
      local name; name=$(basename "$unit")
      [[ $name == *.service ]] || continue
      if systemctl --user is-enabled --quiet "$name" 2>/dev/null; then
        log_success "$name already enabled"
      else
        if ! systemctl --user enable "$name"; then
          record_error "Failed to enable user unit: $name"
        else
          log_success "Enabled $name (will start with graphical-session.target)"
        fi
      fi
    done
  fi
}

# ============================================================
# xdg-desktop-portal configuration
# ============================================================

install_portal_config() {
  local src_dir="$SCRIPT_DIR/portals"
  local dest_dir="$HOME/.config/xdg-desktop-portal"

  if [[ ! -d $src_dir ]]; then
    log_warning "No portals/ directory found; skipping portal config"
    return 0
  fi

  log_info "Linking xdg-desktop-portal config..."
  mkdir -p "$dest_dir"

  shopt -s nullglob
  local confs=("$src_dir"/*.conf)
  shopt -u nullglob

  if [[ ${#confs[@]} -eq 0 ]]; then
    log_warning "portals/ is empty; skipping"
    return 0
  fi

  for conf in "${confs[@]}"; do
    create_symlink "$conf" "$dest_dir/$(basename "$conf")"
  done
}

# ============================================================
# Misc finalization
# ============================================================

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d $tpm_dir ]]; then
    log_success "tpm already installed"
    return 0
  fi
  log_info "Installing Tmux Plugin Manager..."
  mkdir -p "$HOME/.tmux/plugins"
  if ! git clone https://github.com/tmux-plugins/tpm "$tpm_dir"; then
    record_error "Failed to clone tpm"
  fi
}

setup_shell() {
  log_info "Checking default shell..."
  if [[ $SHELL == *"zsh"* ]]; then
    log_success "Default shell is already zsh"
    return 0
  fi
  if ! chsh -s "$(command -v zsh)"; then
    record_error "Failed to change shell to zsh"
  fi
}

setup_xdg_dirs() {
  if command_exists xdg-user-dirs-update; then
    xdg-user-dirs-update || record_error "Failed to update XDG user dirs"
  fi
}

# ============================================================
# Main
# ============================================================

main() {
  check_os

  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_RED} WARNING: ONE-SHOT DEPLOYMENT INITIATED${LOG_NC}"
  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_YELLOW}This will install packages, enable system services,"
  echo -e "and overwrite your dotfile symlinks.${LOG_NC}"
  echo

  if ! prompt_yes_no "Proceed?" "N"; then
    log_info "Aborted by user."
    exit 0
  fi

  echo
  log_info "Starting full installation pipeline..."

  install_pacman_packages
  install_yay
  install_aur_packages
  setup_nvidia
  setup_ly
  install_data_tools
  setup_xdg_dirs
  migrate_zsh_legacy
  symlink_configs
  install_portal_config
  install_systemd_units
  install_tpm
  setup_shell

  echo
  log_success "═══════════════════════════════════════"
  log_success "  Installation script finished!"
  log_success "═══════════════════════════════════════"

  if [[ -d $BACKUP_DIR ]] && [[ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    log_info "Old configs backed up to: $BACKUP_DIR"
  fi

  if [[ ${#SETUP_ERRORS[@]} -gt 0 ]]; then
    echo
    echo -e "${LOG_RED}Errors during installation:${LOG_NC}"
    for err in "${SETUP_ERRORS[@]}"; do
      echo -e "  - $err"
    done
    echo -e "${LOG_YELLOW}Review the errors; manual intervention may be needed.${LOG_NC}"
  else
    echo
    log_success "Zero errors encountered. Reboot to pick up Ly + niri session."
  fi
}

main "$@"
