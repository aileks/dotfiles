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

DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

declare -a SETUP_ERRORS=()

# ============================================================
# Logging
# ============================================================

log_info() { echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"; }
log_success() { echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"; }
log_warning() { echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"; }
log_error() { echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"; }

record_error() {
  log_error "$1"
  SETUP_ERRORS+=("$1")
}

command_exists() { command -v "$1" &>/dev/null; }

prompt_yes_no() {
  local prompt="$1" default="${2:-N}" reply
  if [[ ! -r /dev/tty ]]; then
    log_warning "No TTY available; using default: $default"
    [[ $default =~ ^[Yy]$ ]]
    return
  fi
  if ! read -r -p "$prompt [$default/y]: " reply </dev/tty; then reply="$default"; fi
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
# Bootstrap
# ============================================================

bootstrap() {
  log_info "Ensuring git is installed..."
  if ! command_exists git; then
    sudo pacman -S --needed --noconfirm git || {
      log_error "Failed to install git"
      exit 1
    }
    log_success "git installed"
  else
    log_success "git already installed"
  fi

  if [[ -d $DOTFILES_DIR ]] && git -C "$DOTFILES_DIR" rev-parse --git-dir &>/dev/null; then
    log_info "Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" fetch origin &>/dev/null || log_warning "Fetch failed, using local copy"
    local branch
    branch=$(git -C "$DOTFILES_DIR" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null |
      sed 's@^refs/remotes/origin/@@' || echo "main")
    local local_ref remote_ref
    local_ref=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null || echo "")
    remote_ref=$(git -C "$DOTFILES_DIR" rev-parse "origin/$branch" 2>/dev/null || echo "")
    if [[ $local_ref == "$remote_ref" ]]; then
      log_success "Already up to date"
    else
      git -C "$DOTFILES_DIR" reset --hard "origin/$branch" &>/dev/null
      log_success "Updated to latest"
    fi
  else
    log_info "Cloning dotfiles..."
    local i=1
    while [[ $i -le 3 ]]; do
      if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
        log_success "Cloned"
        break
      fi
      log_warning "Clone failed (attempt $i/3)"
      [[ $i -lt 3 ]] && sleep 5
      i=$((i + 1))
      [[ $i -gt 3 ]] && {
        log_error "Failed to clone after 3 attempts"
        exit 1
      }
    done
  fi

  if [[ $SCRIPT_DIR != "$DOTFILES_DIR" ]]; then
    log_info "Restarting from cloned dotfiles..."
    exec bash "$DOTFILES_DIR/install.sh" </dev/tty
  fi
}

# ============================================================
# Package Lists
# ============================================================

PACMAN_PACKAGES=(
  curl wget vim
  openssh ufw man-db man-pages
  reflector pacman-contrib
  xdg-user-dirs power-profiles-daemon
  trash-cli shfmt jq
  fastfetch btop eza bat fd ripgrep fzf zoxide
  starship
  pipewire pipewire-pulse pipewire-alsa wireplumber
  pavucontrol pamixer playerctl
  networkmanager bluez bluez-utils
  wezterm
  wl-clipboard
  xdg-desktop-portal xdg-desktop-portal-gtk
  libnotify upower
  gvfs gvfs-mtp ffmpeg
  noto-fonts noto-fonts-emoji noto-fonts-cjk
  papirus-icon-theme
  cosmic cosmic-icon-theme
  signal-desktop
  bitwarden bitwarden-cli
  gnome-calendar
  solaar
)

AUR_PACKAGES=(
  zen-browser-bin
  onlyoffice-bin
  fastmail
  notesnook-bin
  blesh-git
  visual-studio-code-bin
)

# ============================================================
# AUR helper
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
    "$MINIFORGE_PREFIX/bin/conda" config --set auto_activate_base false ||
      record_error "Failed to configure conda auto-activate"
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

  create_symlink "$SCRIPT_DIR/btop" "$HOME/.config/btop"
  create_symlink "$SCRIPT_DIR/wezterm" "$HOME/.config/wezterm"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/bash/bashrc" "$HOME/.bashrc"
  create_symlink "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"

  for dir in "$SCRIPT_DIR"/cosmic/*/; do
    [[ -d $dir ]] || continue
    local target="$HOME/.config/cosmic/$(basename "$dir")"
    [[ -d $target && ! -L $target ]] && rm -rf "$target"
    create_symlink "$dir" "$target"
  done
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

setup_services() {
  log_info "Enabling NetworkManager..."
  if systemctl is-enabled --quiet NetworkManager.service 2>/dev/null; then
    log_success "NetworkManager already enabled"
  else
    sudo systemctl enable NetworkManager.service || record_error "Failed to enable NetworkManager"
  fi

  log_info "Enabling bluetooth..."
  if systemctl is-enabled --quiet bluetooth.service 2>/dev/null; then
    log_success "Bluetooth already enabled"
  else
    sudo systemctl enable bluetooth.service || record_error "Failed to enable bluetooth"
  fi

  log_info "Configuring display manager..."
  local other_dm
  other_dm=$(systemctl list-unit-files --state=enabled --type=service 2>/dev/null |
    awk '{print $1}' |
    grep -E '^(sddm|gdm|lightdm|lxdm)\.service$' |
    head -1)
  if [[ -n $other_dm ]]; then
    log_warning "Another display manager is enabled ($other_dm); skipping cosmic-greeter enable"
  elif systemctl is-enabled --quiet cosmic-greeter.service 2>/dev/null; then
    log_success "cosmic-greeter already enabled"
  else
    sudo systemctl enable cosmic-greeter.service || record_error "Failed to enable cosmic-greeter"
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

  # If not running from inside the dotfiles directory, bootstrap first
  # (i.e. invoked via curl or from outside the repo)
  if [[ $SCRIPT_DIR != "$DOTFILES_DIR" ]]; then
    bootstrap
  fi

  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_RED}      WARNING: DESTRUCTION AHEAD!${LOG_NC}"
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
  setup_services

  echo
  log_success "═══════════════════════════════════════"
  log_success "    Installation script finished!"
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
