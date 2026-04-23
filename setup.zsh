#!/usr/bin/env zsh

setopt NO_UNSET PIPE_FAIL

readonly LOG_RED=$'\033[0;31m'
readonly LOG_GREEN=$'\033[0;32m'
readonly LOG_YELLOW=$'\033[1;33m'
readonly LOG_BLUE=$'\033[0;34m'
readonly LOG_NC=$'\033[0m'

SCRIPT_DIR="${0:A:h}"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"

DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

typeset -a SETUP_ERRORS=()
typeset -a SETUP_NOTES=()

# ====================
# 	Logging helpers
# ====================

log_info() { print -r -- "${LOG_BLUE}[INFO]${LOG_NC} $1"; }
log_success() { print -r -- "${LOG_GREEN}[OK]${LOG_NC} $1"; }
log_warning() { print -r -- "${LOG_YELLOW}[WARN]${LOG_NC} $1"; }
log_error() { print -r -- "${LOG_RED}[ERROR]${LOG_NC} $1"; }

record_error() {
  log_error "$1"
  SETUP_ERRORS+=("$1")
}

record_note() {
  log_warning "$1"
  SETUP_NOTES+=("$1")
}

command_exists() { command -v "$1" &> /dev/null; }

# ===================
# 	Utility helpers
# ===================

prompt_yes_no() {
  local prompt="$1" default="${2:-N}" reply=""
  if [[ ! -r /dev/tty ]]; then
    log_warning "No TTY available; using default: $default"
    [[ $default =~ ^[Yy]$ ]]
    return
  fi
  print -n -- "$prompt [$default/y]: " > /dev/tty
  if ! read -r reply < /dev/tty; then reply="$default"; fi
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy]$ ]]
}

# =======================================
# 	OS detection and dotfiles bootstrap
# =======================================

check_os() {
  if [[ "$(uname)" != "Darwin" ]]; then
    log_error "Unsupported OS ($(uname)). This script supports macOS only."
    exit 1
  fi
}

ensure_command_line_tools() {
  # Homebrew's install.sh uses this exact check: xcode-select -p can be truthy
  # before the tools are fully present (e.g. when only Xcode.app is installed).
  local clt_git=/Library/Developer/CommandLineTools/usr/bin/git

  if [[ -e $clt_git ]]; then
    log_success "Xcode Command Line Tools already installed"
    return 0
  fi

  log_info "Installing Xcode Command Line Tools..."
  log_warning "A system dialog will appear. Click 'Install' and accept the"
  log_warning "license. This script will resume automatically when done."

  xcode-select --install &> /dev/null || true

  local waited=0 heartbeat=30 timeout=1800
  while [[ ! -e $clt_git ]]; do
    if (( waited >= timeout )); then
      log_error "Timed out after $((timeout / 60)) min waiting for Command Line Tools."
      log_error "Finish the install manually, then re-run this script."
      exit 1
    fi
    sleep 5
    (( waited += 5 ))
    if (( waited % heartbeat == 0 )); then
      log_info "Still waiting for Command Line Tools install... (${waited}s elapsed)"
    fi
  done

  log_success "Xcode Command Line Tools installed"
}

persist_brew_shellenv() {
  local line='eval "$(/opt/homebrew/bin/brew shellenv)"'
  local zprofile="$HOME/.zprofile"
  if [[ -f $zprofile ]] && grep -qF "$line" "$zprofile"; then
    return 0
  fi
  printf '\n%s\n' "$line" >> "$zprofile"
  log_info "Added brew shellenv to ~/.zprofile"
}

ensure_homebrew() {
  if command_exists brew; then
    log_success "Homebrew already installed"
    persist_brew_shellenv
    return 0
  fi

  log_info "Installing Homebrew..."
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    record_error "Failed to install Homebrew"
    exit 1
  fi

  eval "$(/opt/homebrew/bin/brew shellenv)"
  persist_brew_shellenv
  log_success "Homebrew installed"
}

bootstrap() {
  if [[ -d $DOTFILES_DIR ]] && git -C "$DOTFILES_DIR" rev-parse --git-dir &> /dev/null; then
    log_info "Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" fetch origin &> /dev/null || log_warning "Fetch failed, using local copy"
    local branch local_ref remote_ref
    branch=$(git -C "$DOTFILES_DIR" symbolic-ref refs/remotes/origin/HEAD 2> /dev/null \
      | sed 's@^refs/remotes/origin/@@' || print -r -- "main")
    local_ref=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2> /dev/null || print -r -- "")
    remote_ref=$(git -C "$DOTFILES_DIR" rev-parse "origin/$branch" 2> /dev/null || print -r -- "")
    if [[ $local_ref == "$remote_ref" ]]; then
      log_success "Already up to date"
    else
      git -C "$DOTFILES_DIR" reset --hard "origin/$branch" &> /dev/null
      log_success "Updated to latest"
    fi
  else
    log_info "Cloning dotfiles..."
    local i=1
    while (( i <= 3 )); do
      if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
        log_success "Cloned"
        break
      fi
      log_warning "Clone failed (attempt $i/3)"
      (( i < 3 )) && sleep 5
      (( i++ ))
      if (( i > 3 )); then
        log_error "Failed to clone after 3 attempts"
        exit 1
      fi
    done
  fi

  if [[ $SCRIPT_DIR != "$DOTFILES_DIR" ]]; then
    log_info "Restarting from cloned dotfiles..."
    exec zsh "$DOTFILES_DIR/setup.zsh" < /dev/tty
  fi
}

# ========================
# 	Package installation
# ========================

install_from_brewfile() {
  local brewfile="$SCRIPT_DIR/Brewfile"
  if [[ ! -f $brewfile ]]; then
    record_error "Brewfile not found at $brewfile"
    return 1
  fi

  log_info "Updating Homebrew..."
  brew update || record_note "brew update reported issues; continuing"

  log_info "Ensuring Brewfile taps are installed..."
  local tap_name
  while IFS= read -r tap_name; do
    [[ -z $tap_name ]] && continue
    brew tap "$tap_name" || record_note "failed to tap $tap_name; continuing"
  done < <(awk '/^[[:space:]]*tap[[:space:]]+"/{gsub(/"/, "", $2); print $2}' "$brewfile")

  log_info "Installing from Brewfile..."
  if ! brew bundle install --file="$brewfile"; then
    record_error "brew bundle reported failures; review the output above"
  else
    log_success "Brewfile packages installed"
  fi
}

# ====================
# 	Dotfile symlinks
# ====================

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
    mv "$target" "$BACKUP_DIR/${target:t}"
  fi

  mkdir -p "${target:h}"
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
  create_symlink "$SCRIPT_DIR/kitty" "$HOME/.config/kitty"
  create_symlink "$SCRIPT_DIR/aerospace" "$HOME/.config/aerospace"
  create_symlink "$SCRIPT_DIR/borders" "$HOME/.config/borders"
  create_symlink "$SCRIPT_DIR/starship" "$HOME/.config/starship"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  create_symlink "$SCRIPT_DIR/zsh/zsh_plugins.txt" "$HOME/.zsh_plugins.txt"

  mkdir -p "$HOME/.vim/backup" "$HOME/.vim/swap" "$HOME/.vim/undo"
}

# =======================
# 	macOS defaults
# =======================

apply_macos_defaults() {
  log_info "Applying macOS defaults..."

  defaults write -g ApplePressAndHoldEnabled -bool false
  defaults write -g NSWindowShouldDragOnGesture -bool true
  defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
  defaults write -g InitialKeyRepeat -int 15
  defaults write -g KeyRepeat -int 2
  defaults write com.apple.dock expose-group-apps -bool true

  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock mru-spaces -bool false
  defaults write com.apple.spaces spans-displays -bool false

  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES

  log_success "macOS defaults applied"
}

# =======================
# 	antidote bootstrap
# =======================

prime_antidote_cache() {
  local antidote_path
  antidote_path="$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  if [[ ! -f $antidote_path ]]; then
    record_note "antidote not found at $antidote_path; plugin cache not primed"
    return 0
  fi

  log_info "Priming antidote plugin cache..."
  if ! zsh -c "source '$antidote_path'; antidote load" &> /dev/null; then
    record_note "antidote load exited non-zero on first run (plugins may clone on next shell start)"
  else
    log_success "antidote plugin cache primed"
  fi
}

# =======================
# 	sudo keep-alive
# =======================

SUDO_KEEPALIVE_PID=""

start_sudo_keepalive() {
  if [[ ! -r /dev/tty ]]; then
    record_note "No TTY available; skipping sudo credential caching"
    return 0
  fi

  log_info "Caching sudo credentials (enter your password once)..."
  if ! sudo -v < /dev/tty; then
    record_error "Failed to obtain sudo credentials"
    exit 1
  fi

  while true; do
    sudo -n true
    sleep 60
    kill -0 $$ 2> /dev/null || exit
  done &> /dev/null &
  SUDO_KEEPALIVE_PID=$!
  log_success "sudo credentials cached"
}

stop_sudo_keepalive() {
  if [[ -n $SUDO_KEEPALIVE_PID ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2> /dev/null; then
    kill "$SUDO_KEEPALIVE_PID" 2> /dev/null || true
    SUDO_KEEPALIVE_PID=""
  fi
  sudo -k &> /dev/null || true
}

# ===============
# 	Entry point
# ===============

main() {
  check_os
  trap stop_sudo_keepalive EXIT INT TERM
  ensure_command_line_tools

  if [[ $SCRIPT_DIR != "$DOTFILES_DIR" ]]; then
    bootstrap
  fi

  print -r -- "${LOG_RED}================================================================${LOG_NC}"
  print -r -- "${LOG_RED}           WARNING: SYSTEM CHANGES AHEAD${LOG_NC}"
  print -r -- "${LOG_RED}================================================================${LOG_NC}"
  print -r -- "${LOG_YELLOW}This will install Homebrew, CLI packages, GUI casks,"
  print -r -- "a Nerd Font, and overwrite dotfile symlinks in \$HOME.${LOG_NC}"
  print

  if ! prompt_yes_no "Proceed?" "N"; then
    log_info "Aborted by user."
    exit 0
  fi

  print
  log_info "Starting macOS installation pipeline..."

  start_sudo_keepalive
  ensure_homebrew
  install_from_brewfile
  symlink_configs
  apply_macos_defaults
  prime_antidote_cache

  print
  log_success "═══════════════════════════════════════"
  log_success " 	    macOS setup finished!"
  log_success "═══════════════════════════════════════"

  if [[ -d $BACKUP_DIR ]] && [[ -n "$(ls -A "$BACKUP_DIR" 2> /dev/null)" ]]; then
    log_info "Old configs backed up to: $BACKUP_DIR"
  fi

  if (( ${#SETUP_NOTES[@]} > 0 )); then
    print
    print -r -- "${LOG_YELLOW}Notes:${LOG_NC}"
    local note
    for note in "${SETUP_NOTES[@]}"; do
      print -r -- "  - $note"
    done
  fi

  if (( ${#SETUP_ERRORS[@]} > 0 )); then
    print
    print -r -- "${LOG_RED}Errors during installation:${LOG_NC}"
    local err
    for err in "${SETUP_ERRORS[@]}"; do
      print -r -- "  - $err"
    done
    print -r -- "${LOG_YELLOW}Review the errors; manual intervention may be needed.${LOG_NC}"
  fi

  print
  log_warning "Log out and log back in for all settings to take full effect."
}

main "$@"
