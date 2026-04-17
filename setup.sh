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

show_help() {
  cat <<EOF
Dotfiles Bootstrap Installer (Arch Linux)

This installer will:
  1. Ensure base packages (git, base-devel) are installed
  2. Clone/update your dotfiles to ~/.dotfiles
  3. Run the full install script

Usage:
  curl -fsSL https://aileks.dev/arch | bash
  # or locally:
  ./setup.sh [-h|--help]
EOF
}

log_info()    { echo -e "${LOG_BLUE}[BOOTSTRAP]${LOG_NC} $1"; }
log_success() { echo -e "${LOG_GREEN}[BOOTSTRAP]${LOG_NC} $1"; }
log_warning() { echo -e "${LOG_YELLOW}[BOOTSTRAP]${LOG_NC} $1"; }
log_error()   { echo -e "${LOG_RED}[BOOTSTRAP]${LOG_NC} $1"; }

command_exists() { command -v "$1" &>/dev/null; }

check_os() {
  if ! [[ -r /etc/os-release ]] || ! grep -qiE '^ID=arch' /etc/os-release; then
    log_error "Unsupported system. This setup requires Arch Linux."
    exit 1
  fi
}

pacman_installed() { pacman -Q "$1" &>/dev/null; }

install_base_packages() {
  log_info "Checking base packages (git, base-devel)..."
  local missing=()
  command_exists git || missing+=("git")
  pacman_installed base-devel || missing+=("base-devel")

  if [[ ${#missing[@]} -eq 0 ]]; then
    log_success "Base packages already installed"
    return 0
  fi

  log_info "Installing: ${missing[*]}"
  if ! sudo pacman -S --needed --noconfirm "${missing[@]}"; then
    log_error "Failed to install base packages"
    exit 1
  fi
  log_success "Base packages installed"
}

verify_dotfiles_repo() {
  [[ -d $DOTFILES_DIR ]] || return 1
  command_exists git || return 1
  pushd "$DOTFILES_DIR" &>/dev/null || return 1
  if ! git rev-parse --git-dir &>/dev/null; then
    popd &>/dev/null || true
    return 1
  fi
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  popd &>/dev/null || true
  [[ $remote_url == *"$DOTFILES_REPO"* || $remote_url == *"aileks/dotfiles"* ]]
}

prompt_replace_repo() {
  local existing_url
  existing_url=$(cd "$DOTFILES_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null || echo "unknown")
  echo
  log_warning "Existing repository found at ~/.dotfiles"
  echo "  Expected: $DOTFILES_REPO"
  echo "  Found:    $existing_url"
  echo
  echo "  1) Backup and replace"
  echo "  2) Cancel"
  while true; do
    read -rp "Choice [1/2]: " choice
    case "$choice" in
    1)
      mv "$DOTFILES_DIR" "${DOTFILES_DIR}${BACKUP_SUFFIX}"
      log_success "Backed up to: ${DOTFILES_DIR}${BACKUP_SUFFIX}"
      return 0
      ;;
    2) log_info "Cancelled"; exit 0 ;;
    *) log_error "Invalid choice: $choice" ;;
    esac
  done
}

update_existing_repo() {
  log_info "Updating existing dotfiles repository..."
  cd "$DOTFILES_DIR" || return 1
  git fetch origin &>/dev/null || { log_warning "Fetch failed, using local"; cd - &>/dev/null; return 0; }
  local branch
  branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  local local_ref remote_ref
  local_ref=$(git rev-parse HEAD 2>/dev/null || echo "")
  remote_ref=$(git rev-parse "origin/$branch" 2>/dev/null || echo "")
  if [[ $local_ref == "$remote_ref" ]]; then
    log_success "Already up to date"
  else
    git reset --hard "origin/$branch" &>/dev/null
    log_success "Updated to latest"
  fi
  cd - &>/dev/null || true
}

clone_repo() {
  log_info "Cloning dotfiles..."
  local i=1
  while [[ $i -le 3 ]]; do
    if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
      log_success "Cloned"
      return 0
    fi
    log_warning "Clone failed (attempt $i/3)"
    [[ $i -lt 3 ]] && sleep 5
    i=$((i + 1))
  done
  log_error "Failed to clone after 3 attempts"
  return 1
}

main() {
  [[ $# -gt 0 && ( $1 == "-h" || $1 == "--help" ) ]] && { show_help; exit 0; }

  check_os
  log_info "Starting Arch bootstrap..."
  install_base_packages

  if verify_dotfiles_repo; then
    update_existing_repo || exit 1
  elif [[ -d $DOTFILES_DIR ]]; then
    prompt_replace_repo
    clone_repo || exit 1
  else
    clone_repo || exit 1
  fi

  log_info "Launching install script..."
  echo

  if [[ -x "$DOTFILES_DIR/install.sh" ]]; then
    exec "$DOTFILES_DIR/install.sh" < /dev/tty
  elif [[ -f "$DOTFILES_DIR/install.sh" ]]; then
    exec bash "$DOTFILES_DIR/install.sh" < /dev/tty
  else
    log_error "Install script not found"
    exit 1
  fi
}

main "$@"
