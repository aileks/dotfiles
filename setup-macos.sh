#!/usr/bin/env bash

set -uo pipefail

readonly LOG_RED=$'\033[0;31m'
readonly LOG_GREEN=$'\033[0;32m'
readonly LOG_YELLOW=$'\033[1;33m'
readonly LOG_BLUE=$'\033[0;34m'
readonly LOG_NC=$'\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"

DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

declare -a SETUP_ERRORS=()
declare -a SETUP_NOTES=()

# =====================
# 	Package manifests
# =====================

BREW_FORMULAE=(
  git vim jq shfmt btop eza bat fd ripgrep
  fzf zoxide tree pipx ffmpeg
  mise uv starship fastfetch trash
  antidote
)

BREW_CASKS=(
  wezterm
  visual-studio-code
  bitwarden
  signal
  zen
  notesnook
  fastmail
  docker
  font-commit-mono-nerd-font
)

# ====================
# 	Logging helpers
# ====================

log_info() { echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"; }
log_success() { echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"; }
log_warning() { echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"; }
log_error() { echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"; }

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
  local prompt="$1" default="${2:-N}" reply
  if [[ ! -r /dev/tty ]]; then
    log_warning "No TTY available; using default: $default"
    [[ $default =~ ^[Yy]$ ]]
    return
  fi
  if ! read -r -p "$prompt [$default/y]: " reply < /dev/tty; then reply="$default"; fi
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
  if xcode-select -p &> /dev/null; then
    log_success "Xcode Command Line Tools already installed"
    return 0
  fi
  log_info "Installing Xcode Command Line Tools..."
  xcode-select --install 2> /dev/null || true
  log_warning "Complete the GUI prompt for Command Line Tools, then re-run this script."
  while ! xcode-select -p &> /dev/null; do
    sleep 10
  done
  log_success "Xcode Command Line Tools installed"
}

ensure_homebrew() {
  if command_exists brew; then
    log_success "Homebrew already installed"
    return 0
  fi

  log_info "Installing Homebrew..."
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    record_error "Failed to install Homebrew"
    exit 1
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  log_success "Homebrew installed"
}

bootstrap() {
  if [[ -d $DOTFILES_DIR ]] && git -C "$DOTFILES_DIR" rev-parse --git-dir &> /dev/null; then
    log_info "Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" fetch origin &> /dev/null || log_warning "Fetch failed, using local copy"
    local branch local_ref remote_ref
    branch=$(git -C "$DOTFILES_DIR" symbolic-ref refs/remotes/origin/HEAD 2> /dev/null \
      | sed 's@^refs/remotes/origin/@@' || echo "main")
    local_ref=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2> /dev/null || echo "")
    remote_ref=$(git -C "$DOTFILES_DIR" rev-parse "origin/$branch" 2> /dev/null || echo "")
    if [[ $local_ref == "$remote_ref" ]]; then
      log_success "Already up to date"
    else
      git -C "$DOTFILES_DIR" reset --hard "origin/$branch" &> /dev/null
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
    exec bash "$DOTFILES_DIR/setup-macos.sh" < /dev/tty
  fi
}

# ========================
# 	Package installation
# ========================

install_brew_formulae() {
  log_info "Updating Homebrew..."
  brew update || record_note "brew update reported issues; continuing"

  log_info "Installing Homebrew formulae..."
  if ! brew install "${BREW_FORMULAE[@]}"; then
    record_error "One or more brew formulae failed to install"
  else
    log_success "Brew formulae installed"
  fi
}

install_brew_casks() {
  log_info "Installing Homebrew casks (GUI apps + fonts)..."
  # Casks can fail individually (e.g., already installed via drag-and-drop);
  # install one at a time so a single failure doesn't abort the whole batch.
  local cask
  for cask in "${BREW_CASKS[@]}"; do
    if brew list --cask "$cask" &> /dev/null; then
      log_success "Cask already installed: $cask"
      continue
    fi
    if ! brew install --cask "$cask"; then
      record_error "Failed to install cask: $cask"
    else
      log_success "Cask installed: $cask"
    fi
  done
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
  create_symlink "$SCRIPT_DIR/starship" "$HOME/.config/starship"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  create_symlink "$SCRIPT_DIR/zsh/zsh_plugins.txt" "$HOME/.zsh_plugins.txt"

  # fastfetch: link the directory, then point config.jsonc at the macOS variant
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  if [[ -f "$SCRIPT_DIR/fastfetch/config-macos.jsonc" ]]; then
    ln -sf "$SCRIPT_DIR/fastfetch/config-macos.jsonc" "$HOME/.config/fastfetch/config.jsonc" \
      && log_success "fastfetch: pointing config.jsonc at config-macos.jsonc" \
      || record_error "Failed to symlink fastfetch macOS config"
  fi

  mkdir -p "$HOME/.vim/backup" "$HOME/.vim/swap" "$HOME/.vim/undo"
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

# ===============
# 	Entry point
# ===============

main() {
  check_os

  if [[ $SCRIPT_DIR != "$DOTFILES_DIR" ]]; then
    bootstrap
  fi

  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_RED}           WARNING: SYSTEM CHANGES AHEAD${LOG_NC}"
  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_YELLOW}This will install Homebrew, CLI packages, GUI casks,"
  echo -e "a Nerd Font, and overwrite dotfile symlinks in \$HOME.${LOG_NC}"
  echo

  if ! prompt_yes_no "Proceed?" "N"; then
    log_info "Aborted by user."
    exit 0
  fi

  echo
  log_info "Starting macOS installation pipeline..."

  ensure_command_line_tools
  ensure_homebrew
  install_brew_formulae
  install_brew_casks
  symlink_configs
  prime_antidote_cache

  echo
  log_success "═══════════════════════════════════════"
  log_success " 	    macOS setup finished!"
  log_success "═══════════════════════════════════════"

  cat << 'EOF'

Next steps:
  1. Sign into Bitwarden desktop and enable the SSH agent
     (Settings → SSH agent → enable) so $SSH_AUTH_SOCK has a live socket.
  2. Change your login shell to brew-zsh if you want the newer zsh:
       sudo chsh -s "$(brew --prefix)/bin/zsh" "$USER"
     (Apple's system zsh at /bin/zsh is fine too — no action needed.)
  3. Open a new terminal so ~/.zshrc loads antidote + starship.
  4. mise use -g node@lts   # if you want Node managed by mise instead of nvm.

EOF

  if [[ -d $BACKUP_DIR ]] && [[ "$(ls -A "$BACKUP_DIR" 2> /dev/null)" ]]; then
    log_info "Old configs backed up to: $BACKUP_DIR"
  fi

  if [[ ${#SETUP_NOTES[@]} -gt 0 ]]; then
    echo
    echo -e "${LOG_YELLOW}Notes:${LOG_NC}"
    local note
    for note in "${SETUP_NOTES[@]}"; do
      echo -e "  - $note"
    done
  fi

  if [[ ${#SETUP_ERRORS[@]} -gt 0 ]]; then
    echo
    echo -e "${LOG_RED}Errors during installation:${LOG_NC}"
    local err
    for err in "${SETUP_ERRORS[@]}"; do
      echo -e "  - $err"
    done
    echo -e "${LOG_YELLOW}Review the errors; manual intervention may be needed.${LOG_NC}"
  fi
}

main "$@"
