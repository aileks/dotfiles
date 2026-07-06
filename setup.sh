#!/bin/bash

set -uo pipefail

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_NC='\033[0m'

DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

SCRIPT_DIR=""

declare -a EXTRA_FLATPAK_APPS=()
declare -a SETUP_ERRORS=()

# ============================================================
# Logging
# ============================================================

log_info() { echo -e "${LOG_BLUE}[I]${LOG_NC} $1"; }
log_success() { echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"; }
log_warning() { echo -e "${LOG_YELLOW}[W]${LOG_NC} $1"; }
log_error() { echo -e "${LOG_RED}[E]${LOG_NC} $1"; }

record_error() {
  log_error "$1"
  SETUP_ERRORS+=("$1")
}

# ============================================================
# Helpers
# ============================================================

command_exists() { command -v "$1" &>/dev/null; }

apt_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

apt_has_candidate() {
  local candidate
  candidate=$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')
  [[ -n ${candidate:-} && $candidate != "(none)" ]]
}

flatpak_installed() {
  command_exists flatpak && flatpak info "$1" &>/dev/null
}

pacstall_installed() {
  command_exists pacstall && pacstall -L 2>/dev/null | grep -Fxq -- "$1"
}

prompt_yes_no() {
  local prompt="$1" default="${2:-N}" reply
  if ! read -r -p "$prompt [$default/y]: " reply; then reply="$default"; fi
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy]$ ]]
}

check_os() {
  if ! [[ -r /etc/os-release ]]; then
    log_error "Unsupported OS. This script targets Pop!_OS."
    exit 1
  fi

  source /etc/os-release

  if [[ ${ID:-} != "pop" ]]; then
    log_error "Unsupported OS. This script targets Pop!_OS; detected: ${PRETTY_NAME:-unknown}."
    exit 1
  fi

  log_success "Detected Pop!_OS: ${PRETTY_NAME:-unknown}"
}

# ============================================================
# Bootstrap
# ============================================================

ensure_base_packages() {
  log_info "Checking base packages..."
  local packages=(
    ca-certificates
    curl
    git
    gpg
    software-properties-common
    wget
    build-essential
  )
  local missing=()

  for pkg in "${packages[@]}"; do
    apt_installed "$pkg" || missing+=("$pkg")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    log_success "Base packages already installed"
    return 0
  fi

  log_info "Installing base packages: ${missing[*]}"
  if ! sudo apt update; then
    log_error "Failed to refresh APT metadata"
    exit 1
  fi
  if ! sudo apt install -y "${missing[@]}"; then
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
      2)
        log_info "Cancelled"
        exit 0
        ;;
      *) log_error "Invalid choice: $choice" ;;
    esac
  done
}

update_existing_repo() {
  log_info "Updating existing dotfiles repository..."
  pushd "$DOTFILES_DIR" &>/dev/null || return 1
  git fetch origin &>/dev/null || {
    log_warning "Fetch failed, using local"
    popd &>/dev/null || true
    return 0
  }
  local branch
  branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  local local_ref remote_ref
  local_ref=$(git rev-parse HEAD 2>/dev/null || echo "")
  remote_ref=$(git rev-parse "origin/$branch" 2>/dev/null || echo "")

  if [[ -z $remote_ref ]]; then
    log_warning "Remote branch origin/$branch not found; using local"
  elif [[ $local_ref == "$remote_ref" ]]; then
    log_success "Already up to date"
  elif git merge-base --is-ancestor HEAD "origin/$branch"; then
    if git merge --ff-only "origin/$branch" &>/dev/null; then
      log_success "Fast-forwarded to latest"
    else
      log_warning "Fast-forward failed; using local"
    fi
  else
    log_warning "Local repo is ahead or diverged; using local"
  fi
  popd &>/dev/null || true
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

resolve_script_dir() {
  local self_path="${BASH_SOURCE[0]:-}"
  local self_dir=""
  if [[ -n $self_path && -f $self_path ]]; then
    self_dir="$(cd "$(dirname "$self_path")" 2>/dev/null && pwd)" || self_dir=""
  fi

  if [[ -n $self_dir && -d "$self_dir/zsh" ]]; then
    SCRIPT_DIR="$self_dir"
    return 0
  fi

  log_info "Starting Pop!_OS dotfiles bootstrap..."
  ensure_base_packages

  if verify_dotfiles_repo; then
    update_existing_repo || exit 1
  elif [[ -d $DOTFILES_DIR ]]; then
    prompt_replace_repo
    clone_repo || exit 1
  else
    clone_repo || exit 1
  fi

  if [[ ! -d "$DOTFILES_DIR/zsh" ]]; then
    log_error "Dotfiles checkout is missing expected zsh directory: $DOTFILES_DIR/zsh"
    exit 1
  fi

  SCRIPT_DIR="$DOTFILES_DIR"
  log_success "Using dotfiles from: $SCRIPT_DIR"
}

# ============================================================
# Package Lists
# ============================================================

APT_PACKAGES=(
  usbutils zsh trash-cli jq signal-desktop
  eza fd-find ripgrep wl-clipboard ddcutil
  ffmpegthumbnailer papirus-icon-theme
  ffmpeg flatpak shfmt
)

PPA_PACKAGES=(
  fastfetch
)

declare -A PPA_PACKAGE_SOURCE=(
  [fastfetch]="ppa:zhangsongcui3371/fastfetch"
)

PACSTALL_PACKAGES=(
  alacritty bat-deb btop-bin fzf-bin
  neovim onlyoffice-desktopeditors-deb
  papirus-folders starship-bin
  vscode-deb zen-browser-bin zoxide-deb
)

declare -A PACSTALL_FLATPAK_FALLBACKS=(
  ["zen-browser-bin"]="app.zen_browser.zen"
  ["vscode-deb"]="com.visualstudio.code"
  ["onlyoffice-desktopeditors-deb"]="org.onlyoffice.desktopeditors"
)

FLATPAK_APPS=(
  com.bitwarden.desktop
  com.fastmail.Fastmail
)

# ============================================================
# Package Installation
# ============================================================

setup_signal_repo() {
  local keyring="/usr/share/keyrings/signal-desktop-keyring.gpg"
  local source_file="/etc/apt/sources.list.d/signal-desktop.sources"
  local key_url="https://updates.signal.org/desktop/apt/keys.asc"
  local source_url="https://updates.signal.org/static/desktop/apt/signal-desktop.sources"
  local key_tmp source_tmp

  log_info "Configuring Signal Desktop APT repository..."

  key_tmp=$(mktemp) || {
    record_error "Failed to create temporary file for Signal signing key"
    return 1
  }
  source_tmp=$(mktemp) || {
    rm -f "$key_tmp"
    record_error "Failed to create temporary file for Signal source list"
    return 1
  }

  if ! curl -fsSL "$key_url" | gpg --dearmor >"$key_tmp"; then
    rm -f "$key_tmp" "$source_tmp"
    record_error "Failed to download Signal signing key"
    return 1
  fi

  if [[ -s $keyring ]] && cmp -s "$key_tmp" "$keyring"; then
    log_success "Signal signing key already current"
  elif sudo install -m 0644 "$key_tmp" "$keyring"; then
    log_success "Installed Signal signing key"
  else
    rm -f "$key_tmp" "$source_tmp"
    record_error "Failed to install Signal signing key"
    return 1
  fi

  if ! curl -fsSL "$source_url" -o "$source_tmp"; then
    rm -f "$key_tmp" "$source_tmp"
    record_error "Failed to download Signal APT source"
    return 1
  fi

  if [[ -s $source_file ]] && cmp -s "$source_tmp" "$source_file"; then
    log_success "Signal APT source already current"
  elif sudo install -m 0644 "$source_tmp" "$source_file"; then
    log_success "Installed Signal APT source"
  else
    rm -f "$key_tmp" "$source_tmp"
    record_error "Failed to install Signal APT source"
    return 1
  fi

  rm -f "$key_tmp" "$source_tmp"
}

add_ppa_once() {
  local ppa="$1"
  local marker="${ppa#ppa:}"

  if grep -Rqs "$marker" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    log_success "PPA already present: $ppa"
    return 0
  fi

  log_info "Adding PPA: $ppa"
  if sudo add-apt-repository -y "$ppa"; then
    log_success "Added PPA: $ppa"
    return 0
  fi

  record_error "Failed to add PPA: $ppa"
  return 1
}

add_ppas_for_missing_packages() {
  local update_needed=0
  local pkg ppa

  for pkg in "${PPA_PACKAGES[@]}"; do
    if apt_has_candidate "$pkg"; then
      log_success "APT candidate already available: $pkg"
      continue
    fi

    ppa="${PPA_PACKAGE_SOURCE[$pkg]:-}"
    if [[ -z $ppa ]]; then
      record_error "No PPA mapping for package: $pkg"
      continue
    fi

    if add_ppa_once "$ppa"; then
      update_needed=1
    fi
  done

  if [[ $update_needed -eq 1 ]]; then
    log_info "Refreshing APT metadata after adding PPAs..."
    sudo apt update || record_error "Failed to refresh APT metadata after adding PPAs"
  fi
}

install_apt_packages() {
  setup_signal_repo || log_warning "Signal Desktop may be unavailable from APT"

  log_info "Refreshing APT metadata..."
  if ! sudo apt update; then
    record_error "APT update failed"
    return 1
  fi

  add_ppas_for_missing_packages

  log_info "Upgrading system packages..."
  sudo apt full-upgrade -y || record_error "APT full-upgrade failed"

  local requested=("${APT_PACKAGES[@]}" "${PPA_PACKAGES[@]}")
  local available=()
  local missing=()
  local pkg

  for pkg in "${requested[@]}"; do
    if apt_installed "$pkg"; then
      log_success "APT package already installed: $pkg"
    elif apt_has_candidate "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#available[@]} -gt 0 ]]; then
    log_info "Installing APT packages: ${available[*]}"
    if ! sudo apt install -y "${available[@]}"; then
      record_error "Failed to install some APT/PPA packages"
    else
      log_success "APT/PPA packages installed"
    fi
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    record_error "No APT candidate found for: ${missing[*]}"
  fi
}

install_pacstall() {
  if command_exists pacstall; then
    log_success "Pacstall already installed"
    return 0
  fi

  log_info "Installing Pacstall from the official installer..."
  if sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install || wget -q https://pacstall.dev/q/install -O -)"; then
    log_success "Pacstall installed"
    return 0
  fi

  record_error "Failed to install Pacstall"
  return 1
}

queue_flatpak_fallback() {
  local app_id="$1"
  [[ -n $app_id ]] || return 0
  log_warning "Queuing Flatpak fallback: $app_id"
  EXTRA_FLATPAK_APPS+=("$app_id")
}

install_pacstall_packages() {
  if [[ ${#PACSTALL_PACKAGES[@]} -eq 0 ]]; then
    return 0
  fi

  install_pacstall || {
    record_error "Pacstall unavailable; skipping Pacstall packages"
    return 1
  }

  local pkg fallback
  for pkg in "${PACSTALL_PACKAGES[@]}"; do
    if pacstall_installed "$pkg"; then
      log_success "Pacstall package already installed: $pkg"
      continue
    fi

    log_info "Installing Pacstall package: $pkg"
    if pacstall -PI "$pkg"; then
      log_success "Installed via Pacstall: $pkg"
    else
      fallback="${PACSTALL_FLATPAK_FALLBACKS[$pkg]:-}"
      if [[ -n $fallback ]]; then
        record_error "Pacstall install failed for $pkg; will try Flatpak fallback: $fallback"
        queue_flatpak_fallback "$fallback"
      else
        record_error "Pacstall install failed for $pkg and no Flatpak fallback is configured"
      fi
    fi
  done
}

install_flatpak_apps() {
  if ! command_exists flatpak; then
    record_error "flatpak command not found; skipping Flatpak apps"
    return 1
  fi

  log_info "Configuring Flathub remote..."
  if ! sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    record_error "Failed to configure Flathub remote"
    return 1
  fi

  local apps=("${FLATPAK_APPS[@]}" "${EXTRA_FLATPAK_APPS[@]}")
  local app_id seen_key
  declare -A seen_flatpaks=()

  for app_id in "${apps[@]}"; do
    [[ -n $app_id ]] || continue
    seen_key="$app_id"
    if [[ -n ${seen_flatpaks[$seen_key]:-} ]]; then
      continue
    fi
    seen_flatpaks[$seen_key]=1

    if flatpak_installed "$app_id"; then
      log_success "Flatpak already installed: $app_id"
      continue
    fi

    log_info "Installing Flatpak: $app_id"
    if flatpak install -y flathub "$app_id"; then
      log_success "Installed Flatpak: $app_id"
    else
      record_error "Failed to install Flatpak: $app_id"
    fi
  done
}

setup_debian_cli_names() {
  mkdir -p "$HOME/.local/bin"

  if ! command_exists bat && command_exists batcat && [[ ! -e "$HOME/.local/bin/bat" ]]; then
    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat" \
      && log_success "Created ~/.local/bin/bat -> batcat" \
      || record_error "Failed to create bat alias symlink"
  fi

  if ! command_exists fd && command_exists fdfind && [[ ! -e "$HOME/.local/bin/fd" ]]; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd" \
      && log_success "Created ~/.local/bin/fd -> fdfind" \
      || record_error "Failed to create fd alias symlink"
  fi
}

setup_ddc() {
  if ! apt_installed ddcutil; then
    log_warning "ddcutil not installed; skipping DDC/CI setup"
    return 0
  fi

  local conf=/etc/modules-load.d/i2c-dev.conf
  if [[ -f $conf ]] && grep -q '^i2c-dev$' "$conf"; then
    log_success "i2c-dev module already configured"
  else
    log_info "Configuring i2c-dev module to load at boot..."
    if printf 'i2c-dev\n' | sudo tee "$conf" >/dev/null; then
      log_success "Wrote $conf"
      sudo modprobe i2c-dev 2>/dev/null || true
    else
      record_error "Failed to write $conf"
    fi
  fi

  if ! getent group i2c >/dev/null; then
    log_info "Creating i2c group..."
    sudo groupadd -r i2c || record_error "Failed to create i2c group"
  fi

  if id -nG "$USER" | grep -qw i2c; then
    log_success "$USER already in i2c group"
  else
    log_info "Adding $USER to i2c group..."
    if sudo usermod -aG i2c "$USER"; then
      log_success "Added $USER to i2c group"
    else
      record_error "Failed to add $USER to i2c group"
    fi
  fi
}

install_uv() {
  log_info "Setting up uv..."

  if command_exists uv; then
    log_success "uv already installed"
  else
    log_info "Installing uv..."
    if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
      record_error "Failed to install uv"
    fi
  fi
}

# ============================================================
# Antidote
# ============================================================

install_antidote() {
  local antidote_dir="$HOME/.antidote"
  if [[ -d "$antidote_dir/.git" ]]; then
    log_info "Updating antidote..."
    if git -C "$antidote_dir" pull --ff-only --quiet; then
      log_success "antidote up to date"
    else
      record_error "Failed to update antidote"
    fi
    return 0
  fi
  if [[ -e $antidote_dir ]]; then
    record_error "$antidote_dir exists but is not a git checkout; remove it manually"
    return 1
  fi
  log_info "Cloning antidote..."
  if git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"; then
    log_success "antidote installed at $antidote_dir"
  else
    record_error "Failed to clone antidote"
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

  create_symlink "$SCRIPT_DIR/btop" "$HOME/.config/btop"
  create_symlink "$SCRIPT_DIR/alacritty" "$HOME/.config/alacritty"
  create_symlink "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
  create_symlink "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
}

# ============================================================
# Misc finalization
# ============================================================

setup_shell() {
  log_info "Checking default shell..."
  if [[ $SHELL == *"zsh"* ]]; then
    log_success "Default shell is already zsh"
    return 0
  fi
  if ! command_exists zsh; then
    record_error "zsh is not installed; cannot change default shell"
    return 1
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
  resolve_script_dir "$@"

  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_RED}       WARNING: ONE-SHOT POP!_OS DEPLOYMENT INITIATED${LOG_NC}"
  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_YELLOW}This will install packages, add selected community sources,"
  echo -e "and overwrite your dotfile symlinks.${LOG_NC}"
  echo -e "Source tree: ${LOG_GREEN}$SCRIPT_DIR${LOG_NC}"
  echo

  if ! prompt_yes_no "Proceed?" "N"; then
    log_info "Aborted by user."
    exit 0
  fi

  echo
  log_info "Starting full installation pipeline..."

  ensure_base_packages
  install_apt_packages
  setup_debian_cli_names
  install_pacstall_packages
  install_flatpak_apps
  setup_ddc
  install_uv
  setup_xdg_dirs
  install_antidote
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
  else
    echo
    log_success "Zero errors encountered. Reboot to apply all changes."
  fi
}

main "$@"
