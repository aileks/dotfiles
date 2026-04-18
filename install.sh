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

command_exists() { command -v "$1" &>/dev/null; }

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
  vim
  openssh ufw man-db man-pages
  reflector pacman-contrib
  xdg-user-dirs
  trash-cli shfmt jq
  fastfetch btop eza bat fd ripgrep fzf zoxide
  starship

  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  pavucontrol pamixer playerctl
  network-manager-applet blueman

  wezterm
  wl-clipboard
  xdg-desktop-portal xdg-desktop-portal-gtk
  gnome-keyring
  libnotify

  thunar thunar-volman thunar-archive-plugin
  tumbler ffmpegthumbnailer
  file-roller
  gvfs gvfs-mtp gvfs-gphoto2 udiskie
  yazi

  ttf-jetbrains-mono-nerd
  noto-fonts noto-fonts-emoji noto-fonts-cjk
  papirus-icon-theme

  celluloid
  signal-desktop
  bitwarden bitwarden-cli
  code
  calcurse
  solaar
)

AUR_PACKAGES=(
  zen-browser-bin
  onlyoffice-bin
  fastmail
  notesnook-bin
  bemoji
  wiremix
  ble-git
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

  create_symlink "$SCRIPT_DIR/btop"          "$HOME/.config/btop"
  create_symlink "$SCRIPT_DIR/wezterm"       "$HOME/.config/wezterm"
  create_symlink "$SCRIPT_DIR/fastfetch"     "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/bat"           "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/bash/bashrc"   "$HOME/.bashrc"
  create_symlink "$SCRIPT_DIR/git/gitconfig" "$HOME/.gitconfig"
  create_symlink "$SCRIPT_DIR/vim/vimrc"     "$HOME/.vimrc"
}

# ============================================================
# Misc finalization
# ============================================================

setup_shell() {
  log_info "Checking default shell..."
  if [[ $SHELL == *"bash"* ]]; then
    log_success "Default shell is already bash"
    return 0
  fi
  if ! chsh -s "$(command -v bash)"; then
    record_error "Failed to change shell to bash"
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
  echo -e "${LOG_RED} WARNING: DESTRUCTION AHEAD!${LOG_NC}"
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
  install_data_tools
  setup_xdg_dirs
  symlink_configs
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
  fi
}

main "$@"
