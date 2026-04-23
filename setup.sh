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
    exec zsh "$DOTFILES_DIR/setup.sh" < /dev/tty
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
  create_symlink "$SCRIPT_DIR/starship" "$HOME/.config/starship"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  create_symlink "$SCRIPT_DIR/zsh/zsh_plugins.txt" "$HOME/.zsh_plugins.txt"

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

  ensure_command_line_tools
  ensure_homebrew
  install_from_brewfile
  symlink_configs
  prime_antidote_cache

  print
  log_success "═══════════════════════════════════════"
  log_success " 	    macOS setup finished!"
  log_success "═══════════════════════════════════════"

  cat << 'EOF'

Next steps:
  1. First-launch each cask GUI app (Kitty, Bitwarden, Docker Desktop, ...).
     macOS Tahoe will block them on first open — approve each under
     System Settings → Privacy & Security → "Open anyway".
  2. Sign into Bitwarden desktop and enable the SSH agent
     (Settings → SSH agent → enable) so $SSH_AUTH_SOCK has a live socket.
  3. Change your login shell to brew-zsh if you want the newer zsh:
       sudo chsh -s "$(brew --prefix)/bin/zsh" "$USER"
     (Apple's system zsh at /bin/zsh is fine too — no action needed.)
  4. Open a new Kitty window so ~/.zshrc loads antidote + starship.
  5. mise use -g node@lts   # if you want Node managed by mise instead of nvm.

EOF

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
}

main "$@"
