#!/bin/bash

set -euo pipefail

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_NC='\033[0m'

DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"
PASS_THROUGH_ARGS=()

show_help() {
  cat <<EOF
Arch Linux Dotfiles Bootstrap Installer

This installer will:
  1. Ensure git and base-devel are installed
  2. Install an AUR helper (paru) if needed
  3. Clone/update your dotfiles to ~/.dotfiles
  4. Run the full setup script

Usage:
  curl -fsSL https://aileks.dev/linux | bash [OPTIONS]

  Or locally:
  ./setup.sh [OPTIONS]

Options:
  -h, --help          Show this help message
  -d, --dry-run       Pass dry-run mode to install script
  --debug             Enable debug output in install script
  1                   Perform full Arch setup (default)
  2                   Update and symlink dotfiles only

If no option is provided, an interactive menu will be displayed.
EOF
}

log_info() {
  echo -e "${LOG_BLUE}[BOOTSTRAP]${LOG_NC} $1"
}

log_success() {
  echo -e "${LOG_GREEN}[BOOTSTRAP]${LOG_NC} $1"
}

log_warning() {
  echo -e "${LOG_YELLOW}[BOOTSTRAP]${LOG_NC} $1"
}

log_error() {
  echo -e "${LOG_RED}[BOOTSTRAP]${LOG_NC} $1"
}

command_exists() {
  command -v "$1" &>/dev/null
  return $?
}

# ============================================================
# Package Installation
# ============================================================

install_base_packages() {
  log_info "Checking base packages..."

  local missing_pkgs=()

  if ! command_exists git; then
    missing_pkgs+=("git")
  fi

  if ! pacman -Qq base-devel &>/dev/null; then
    missing_pkgs+=("base-devel")
  fi

  if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
    log_success "Base packages already installed"
    return 0
  fi

  log_info "Installing base packages: ${missing_pkgs[*]}"

  if ! sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"; then
    log_error "Failed to install base packages"
    exit 1
  fi

  log_success "Base packages installed"
}

install_aur_helper() {
  log_info "Checking for AUR helper..."

  if command_exists paru; then
    log_success "paru already installed"
    return 0
  fi

  if command_exists yay; then
    log_success "yay already installed (will use yay)"
    return 0
  fi

  log_info "Installing paru (AUR helper)..."

  local paru_dir
  paru_dir=$(mktemp -d)

  if ! git clone https://aur.archlinux.org/paru.git "$paru_dir"; then
    log_error "Failed to clone paru"
    rm -rf "$paru_dir"
    exit 1
  fi

  pushd "$paru_dir" &>/dev/null || exit 1

  if ! makepkg -si --noconfirm; then
    log_error "Failed to build paru"
    popd &>/dev/null || true
    rm -rf "$paru_dir"
    exit 1
  fi

  popd &>/dev/null || true
  rm -rf "$paru_dir"

  log_success "paru installed successfully"
}

# ============================================================
# Repository Management
# ============================================================

verify_dotfiles_repo() {
  if [[ ! -d $DOTFILES_DIR ]]; then
    return 1
  fi

  if ! command_exists git; then
    return 1
  fi

  pushd "$DOTFILES_DIR" &>/dev/null || return 1

  if ! git rev-parse --git-dir &>/dev/null; then
    popd &>/dev/null || true
    return 1
  fi

  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  popd &>/dev/null || true

  if [[ $remote_url == *"$DOTFILES_REPO"* ]] || [[ $remote_url == *"aileks/dotfiles"* ]]; then
    return 0
  fi

  return 1
}

prompt_replace_repo() {
  local existing_url
  existing_url=$(cd "$DOTFILES_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null || echo "unknown")

  echo
  log_warning "Existing repository found at ~/.dotfiles"
  echo "  Expected: $DOTFILES_REPO"
  echo "  Found: $existing_url"
  echo
  echo "Choose an option:"
  echo "  1) Backup and replace existing repository"
  echo "  2) Cancel installation"
  echo

  while true; do
    read -rp "Enter your choice (1 or 2): " choice
    case "$choice" in
      1)
        log_info "Backing up existing repository..."
        mv "$DOTFILES_DIR" "${DOTFILES_DIR}${BACKUP_SUFFIX}"
        log_success "Backed up to: ${DOTFILES_DIR}${BACKUP_SUFFIX}"
        return 0
        ;;
      2)
        log_info "Installation cancelled"
        exit 0
        ;;
      *)
        log_error "Invalid choice: $choice"
        ;;
    esac
  done
}

update_existing_repo() {
  log_info "Updating existing dotfiles repository..."

  if ! cd "$DOTFILES_DIR"; then
    log_error "Failed to enter dotfiles directory"
    return 1
  fi

  if ! git fetch origin &>/dev/null; then
    log_warning "Failed to fetch updates, continuing with local version"
    cd - &>/dev/null || true
    return 0
  fi

  local local_ref
  local_ref=$(git rev-parse HEAD 2>/dev/null || echo "")

  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

  local remote_ref
  remote_ref=$(git rev-parse "origin/$default_branch" 2>/dev/null || echo "")

  if [[ $local_ref == "$remote_ref" ]]; then
    log_success "Already up to date"
  else
    git reset --hard "origin/$default_branch" &>/dev/null
    log_success "Repository updated to latest version"
  fi

  cd - &>/dev/null || true
  return 0
}

clone_repo() {
  log_info "Cloning dotfiles repository..."

  local retries=3
  local delay=5
  local i=1

  while [[ $i -le $retries ]]; do
    if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
      log_success "Repository cloned successfully"
      return 0
    fi
    log_warning "Clone failed (attempt $i/$retries)"
    if [[ $i -lt $retries ]]; then
      sleep $delay
    fi
    i=$((i + 1))
  done

  log_error "Failed to clone repository after $retries attempts"
  return 1
}

# ============================================================
# Argument Parsing
# ============================================================

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        show_help
        exit 0
        ;;
      *)
        PASS_THROUGH_ARGS+=("$1")
        ;;
    esac
    shift
  done
}

# ============================================================
# Main
# ============================================================

main() {
  # Check if running on Arch Linux
  if [[ ! -f /etc/arch-release ]]; then
    log_error "This script is designed for Arch Linux only."
    log_error "Detected OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 || uname -s)"
    exit 1
  fi

  parse_arguments "$@"

  log_info "Starting Arch Linux bootstrap installer..."

  # Ensure base packages are installed
  install_base_packages

  # Install AUR helper
  install_aur_helper

  # Handle dotfiles repository
  if verify_dotfiles_repo; then
    update_existing_repo || exit 1
  elif [[ -d $DOTFILES_DIR ]]; then
    prompt_replace_repo || exit 1
    clone_repo || exit 1
  else
    clone_repo || exit 1
  fi

  log_info "Launching install script..."
  echo

  # Execute the main install script
  if [[ -x "$DOTFILES_DIR/install.sh" ]]; then
    exec "$DOTFILES_DIR/install.sh" "${PASS_THROUGH_ARGS[@]}"
  elif [[ -f "$DOTFILES_DIR/install.sh" ]]; then
    exec bash "$DOTFILES_DIR/install.sh" "${PASS_THROUGH_ARGS[@]}"
  else
    log_error "Install script not found at $DOTFILES_DIR/install.sh"
    log_info "You may need to create it or run setup manually."
    exit 1
  fi
}

main "$@"
