#!/bin/bash

set -euo pipefail

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_CYAN='\033[0;36m'
readonly LOG_NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
EMACS_REPO="https://codeberg.org/aileks/emacs.d.git"
EMACS_DIR="$HOME/.emacs.d"

DRY_RUN=false
DEBUG=false
SYMLINK_ONLY=false

# ============================================================
# Logging
# ============================================================

log_info() {
  echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"
}

log_success() {
  echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"
}

log_warning() {
  echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"
}

log_error() {
  echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"
}

log_debug() {
  if [[ $DEBUG == true ]]; then
    echo -e "${LOG_CYAN}[DEBUG]${LOG_NC} $1"
  fi
}

log_dry() {
  if [[ $DRY_RUN == true ]]; then
    echo -e "${LOG_YELLOW}[DRY-RUN]${LOG_NC} Would: $1"
    return 0
  fi
  return 1
}

run_cmd() {
  if [[ $DRY_RUN == true ]]; then
    echo -e "${LOG_YELLOW}[DRY-RUN]${LOG_NC} $*"
    return 0
  fi
  log_debug "Running: $*"
  "$@"
}

command_exists() {
  command -v "$1" &>/dev/null
}

check_os() {
  if ! [[ -r /etc/os-release ]] || ! grep -qiE 'ubuntu|debian|pop_os' /etc/os-release; then
    log_error "Unsupported OS."
    exit 1
  fi
}

# ============================================================
# Package Lists
# ============================================================

APT_PACKAGES=(
  curl
  rsync
  libnotify-bin
  build-essential
  zsh
  gh
  tmux
  gdb
  zoxide
  eza
  jq
  fd-find
  ripgrep
  calcurse
  qalculate-gtk
  mpv
  solaar
  cider
  zathura
  trash-cli
  fonts-noto
  fonts-noto-cjk
  fonts-noto-color-emoji
)

PACSTALL_PACKAGES=(
  fzf-bin
  btop-bin
  bat-deb
  onlyoffice-desktopeditors-deb
  keyd-deb
  fastfetch-git
  emacs-git # pop_os repos don't have emacs 30
)

# ============================================================
# Package Installation
# ============================================================

install_apt_packages() {
  log_info "Installing apt packages..."

  local to_install=()
  for pkg in "${APT_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    log_success "All apt packages already installed"
    return 0
  fi

  log_info "Installing ${#to_install[@]} packages: ${to_install[*]:0:5}..."
  if [[ $DRY_RUN == true ]]; then
    log_dry "sudo apt update"
    log_dry "sudo apt install -y ${to_install[*]}"
    return 0
  fi

  sudo apt update

  if ! sudo apt install -y "${to_install[@]}"; then
    log_error "Failed to install some apt packages"
    exit 1
  fi

  log_success "Apt packages installed"
}

setup_solaar_repo() {
  local repo_pattern="/etc/apt/sources.list.d/solaar-unifying-ubuntu-stable"

  if ls "${repo_pattern}"*.list &>/dev/null; then
    log_success "Solaar repository already present"
    return 0
  fi

  log_info "Adding Solaar repository..."

  if [[ $DRY_RUN == true ]]; then
    log_dry "sudo apt install -y software-properties-common"
    log_dry "sudo add-apt-repository -y ppa:solaar-unifying/stable"
    return 0
  fi

  if ! command_exists add-apt-repository; then
    sudo apt update
    sudo apt install -y software-properties-common
  fi

  sudo add-apt-repository -y ppa:solaar-unifying/stable
}

setup_cider_repo() {
  local keyring_path="/usr/share/keyrings/cider-archive-keyring.gpg"
  local repo_file="/etc/apt/sources.list.d/cider.list"
  local repo_entry="deb [signed-by=${keyring_path}] https://repo.cider.sh/apt stable main"

  if [[ -f $repo_file && -f $keyring_path ]]; then
    log_success "Cider repository already present"
    return 0
  fi

  if ! command_exists gpg; then
    log_error "gpg is required to install the Cider repo (install gnupg)"
    return 1
  fi

  log_info "Adding Cider repository..."

  if [[ $DRY_RUN == true ]]; then
    log_dry "curl -fsSL https://repo.cider.sh/APT-GPG-KEY | sudo gpg --dearmor -o ${keyring_path}"
    log_dry "echo '${repo_entry}' | sudo tee ${repo_file}"
    return 0
  fi

  if ! curl -fsSL https://repo.cider.sh/APT-GPG-KEY | sudo gpg --dearmor -o "$keyring_path"; then
    log_error "Failed to install Cider repo key"
    return 1
  fi

  if ! echo "$repo_entry" | sudo tee "$repo_file" >/dev/null; then
    log_error "Failed to configure Cider repo"
    return 1
  fi

  sudo chmod 644 "$keyring_path"
}
install_pacstall_packages() {
  log_info "Installing pacstall packages..."

  if [[ $DRY_RUN == true ]]; then
    log_dry "pacstall -I ${PACSTALL_PACKAGES[*]}"
    return 0
  fi

  if ! command_exists pacstall; then
    log_error "Pacstall not found. Run setup.sh first."
    exit 1
  fi

  local installed
  installed=$(pacstall -L 2>/dev/null || true)

  local to_install=()
  for pkg in "${PACSTALL_PACKAGES[@]}"; do
    if ! grep -qx "$pkg" <<<"$installed"; then
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    log_success "All pacstall packages already installed"
    return 0
  fi

  log_info "Installing ${#to_install[@]} pacstall packages"
  for pkg in "${to_install[@]}"; do
    if log_dry "pacstall -I $pkg"; then
      continue
    fi
    if ! pacstall -I "$pkg"; then
      log_warning "Failed to install pacstall package: $pkg"
    fi
  done

  log_success "Pacstall packages installed"
}

install_1password() {
  log_info "Installing 1Password..."

  if dpkg -s 1password &>/dev/null; then
    log_success "1Password already installed"
    return 0
  fi

  if [[ $DRY_RUN == true ]]; then
    log_dry "Download 1Password .deb and install"
    log_dry "sudo apt install -y 1password 1password-cli"
    return 0
  fi

  local arch
  case "$(uname -m)" in
  x86_64 | amd64) arch="amd64" ;;
  aarch64 | arm64) arch="arm64" ;;
  *)
    log_error "Unsupported architecture for 1Password"
    return 1
    ;;
  esac

  local tmp_deb
  tmp_deb=$(mktemp)

  if ! curl -fsSL "https://downloads.1password.com/linux/debian/${arch}/stable/1password-latest.deb" -o "$tmp_deb"; then
    log_error "Failed to download 1Password .deb"
    rm -f "$tmp_deb"
    return 1
  fi

  if ! sudo dpkg -i "$tmp_deb"; then
    log_warning "dpkg failed; attempting to fix dependencies"
    sudo apt -f install -y
  fi

  rm -f "$tmp_deb"

  sudo apt update
  if ! sudo apt install -y 1password 1password-cli; then
    log_error "Failed to install 1Password packages"
    return 1
  fi

  log_success "1Password installed"
}

install_wezterm() {
  log_info "Installing WezTerm..."

  if dpkg -s wezterm &>/dev/null; then
    log_success "WezTerm already installed"
    return 0
  fi

  if ! command_exists gpg; then
    log_error "gpg is required to install WezTerm (install gnupg)"
    return 1
  fi

  if [[ $DRY_RUN == true ]]; then
    log_dry "curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg"
    log_dry "echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list"
    log_dry "sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg"
    log_dry "sudo apt update"
    log_dry "sudo apt install -y wezterm"
    return 0
  fi

  if ! curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg; then
    log_error "Failed to install WezTerm apt repo key"
    return 1
  fi

  if ! echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null; then
    log_error "Failed to configure WezTerm apt repo"
    return 1
  fi

  sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
  sudo apt update

  if ! sudo apt install -y wezterm; then
    log_error "Failed to install WezTerm"
    return 1
  fi

  log_success "WezTerm installed"
}

install_helium() {
  log_info "Installing Helium AppImage..."

  if [[ $DRY_RUN == true ]]; then
    log_dry "Download Helium AppImage and install desktop entry"
    log_dry "Set Helium as default browser"
    return 0
  fi

  local appimage_url
  appimage_url="https://github.com/imputnet/helium-linux/releases/download/0.8.4.1/helium-0.8.4.1-x86_64.AppImage"

  local install_dir="$HOME/.local/opt/helium"
  local appimage_path="$install_dir/helium.AppImage"

  if log_dry "Download Helium AppImage"; then
    return 0
  fi

  mkdir -p "$install_dir"
  if ! curl -fsSL "$appimage_url" -o "$appimage_path"; then
    log_error "Failed to download Helium AppImage"
    return 1
  fi

  chmod +x "$appimage_path"

  local desktop_dir="$HOME/.local/share/applications"
  mkdir -p "$desktop_dir"

  cat >"$desktop_dir/helium.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Helium
Exec=${appimage_path}
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF

  if command_exists xdg-mime; then
    xdg-mime default helium.desktop x-scheme-handler/http
    xdg-mime default helium.desktop x-scheme-handler/https
  fi

  if command_exists xdg-settings; then
    xdg-settings set default-web-browser helium.desktop
  fi

  log_success "Helium installed and set as default browser"
}

install_packages() {
  setup_solaar_repo
  setup_cider_repo
  install_apt_packages
  install_wezterm
  install_pacstall_packages
  install_1password
  install_helium
}

# ============================================================
# Oh-My-Zsh Installation
# ============================================================

install_oh_my_zsh() {
  log_info "Setting up Oh-My-Zsh..."

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_success "Oh-My-Zsh already installed"
    return 0
  fi

  if log_dry "Install Oh-My-Zsh (unattended, keep zshrc)"; then
    return 0
  fi

  local omz_installer
  omz_installer=$(mktemp)

  if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$omz_installer"; then
    log_error "Failed to download Oh-My-Zsh installer"
    rm -f "$omz_installer"
    exit 1
  fi

  if ! RUNZSH=no KEEP_ZSHRC=yes sh "$omz_installer" --unattended; then
    log_error "Failed to install Oh-My-Zsh"
    rm -f "$omz_installer"
    exit 1
  fi

  rm -f "$omz_installer"
  log_success "Oh-My-Zsh installed"
}

install_zsh_plugins() {
  log_info "Installing zsh plugins..."

  local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
  mkdir -p "$plugins_dir"

  if [[ -d "$plugins_dir/zsh-autosuggestions" ]]; then
    log_success "zsh-autosuggestions already installed"
  else
    if log_dry "Clone zsh-autosuggestions"; then
      :
    elif ! git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"; then
      log_warning "Failed to clone zsh-autosuggestions"
    else
      log_success "zsh-autosuggestions installed"
    fi
  fi

  if [[ -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
    log_success "zsh-syntax-highlighting already installed"
  else
    if log_dry "Clone zsh-syntax-highlighting"; then
      :
    elif ! git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"; then
      log_warning "Failed to clone zsh-syntax-highlighting"
    else
      log_success "zsh-syntax-highlighting installed"
    fi
  fi

  if [[ -f "$plugins_dir/ashen_zsh_syntax_highlighting.zsh" ]]; then
    log_success "ashen_zsh_syntax_highlighting already installed"
  else
    if log_dry "Download ashen_zsh_syntax_highlighting"; then
      :
    elif ! curl -fsSL "https://codeberg.org/ficd/ashen/raw/branch/main/ports/zsh-syntax-highlighting/ashen_zsh_syntax_highlighting.zsh" -o "$plugins_dir/ashen_zsh_syntax_highlighting.zsh"; then
      log_warning "Failed to download ashen_zsh_syntax_highlighting"
    else
      log_success "ashen_zsh_syntax_highlighting installed"
    fi
  fi

  log_success "Zsh plugins installed"
}

setup_emacs_config() {
  log_info "Setting up Emacs config..."

  if [[ -d "$EMACS_DIR/.git" ]]; then
    log_success "Emacs config already cloned"
    return 0
  fi

  if [[ -e "$EMACS_DIR" ]]; then
    log_warning "Emacs config path exists, skipping clone: $EMACS_DIR"
    return 0
  fi

  if log_dry "git clone $EMACS_REPO $EMACS_DIR"; then
    return 0
  fi

  if ! git clone "$EMACS_REPO" "$EMACS_DIR"; then
    log_warning "Failed to clone Emacs config"
    return 0
  fi

  log_success "Emacs config cloned"
}

# ============================================================
# Symlink Management
# ============================================================

backup_existing() {
  local target="$1"

  if [[ ! -e $target && ! -L $target ]]; then
    return 0
  fi

  if [[ -L $target ]]; then
    log_debug "Removing existing symlink: $target"
    if ! log_dry "rm $target"; then
      rm "$target"
    fi
    return 0
  fi

  mkdir -p "$BACKUP_DIR"
  local backup_path="$BACKUP_DIR/$(basename "$target")"

  log_warning "Backing up: $target -> $backup_path"

  if ! log_dry "mv $target $backup_path"; then
    mv "$target" "$backup_path"
  fi
}

create_symlink() {
  local source="$1"
  local target="$2"

  if [[ ! -e $source ]]; then
    log_warning "Source does not exist: $source"
    exit 1
  fi

  backup_existing "$target"

  local target_dir
  target_dir=$(dirname "$target")

  if [[ ! -d $target_dir ]]; then
    if ! log_dry "mkdir -p $target_dir"; then
      mkdir -p "$target_dir"
    fi
  fi

  log_info "Linking: $target -> $source"

  if ! log_dry "ln -sf $source $target"; then
    ln -sf "$source" "$target"
  fi
}

symlink_configs() {
  log_info "Creating config symlinks..."

  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/bin"

  # Direct directory symlinks
  create_symlink "$SCRIPT_DIR/btop" "$HOME/.config/btop"
  create_symlink "$SCRIPT_DIR/wezterm" "$HOME/.config/wezterm"
  create_symlink "$SCRIPT_DIR/cosmic" "$HOME/.config/cosmic"
  create_symlink "$SCRIPT_DIR/zathura" "$HOME/.config/zathura"
  create_symlink "$SCRIPT_DIR/mpv" "$HOME/.config/mpv"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"

  # Single file symlinks
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  create_symlink "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  create_symlink "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"

  # Status bar scripts
  if [[ -d "$SCRIPT_DIR/scripts/statusbar" ]]; then
    for script in "$SCRIPT_DIR/scripts/statusbar/"*; do
      [[ -f $script ]] || continue
      create_symlink "$script" "$HOME/.local/bin/$(basename "$script")"
    done
  fi

  # Utility scripts
  if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    for script in "$SCRIPT_DIR/scripts/"*; do
      [[ -f $script ]] || continue
      create_symlink "$script" "$HOME/.local/bin/$(basename "$script")"
    done
  fi

  log_success "Config symlinks created"
}

setup_keyd() {
  log_info "Setting up keyd..."

  if [[ ! -f "$SCRIPT_DIR/keyd/default.conf" ]]; then
    log_warning "keyd config not found: $SCRIPT_DIR/keyd/default.conf"
    exit 1
  fi

  if log_dry "sudo mkdir -p /etc/keyd && sudo cp $SCRIPT_DIR/keyd/default.conf /etc/keyd/default.conf"; then
    return 0
  fi

  sudo mkdir -p /etc/keyd
  sudo cp "$SCRIPT_DIR/keyd/default.conf" /etc/keyd/default.conf
  log_success "keyd config installed"
}

# ============================================================
# Post-Install Tasks
# ============================================================

install_tpm() {
  log_info "Installing Tmux Plugin Manager..."

  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [[ -d $tpm_dir ]]; then
    log_success "tpm already installed"
    return 0
  fi

  if log_dry "git clone https://github.com/tmux-plugins/tpm $tpm_dir"; then
    return 0
  fi

  mkdir -p "$HOME/.tmux/plugins"

  if ! git clone https://github.com/tmux-plugins/tpm "$tpm_dir"; then
    log_warning "Failed to clone tpm"
    return 1
  fi

  log_success "tpm installed successfully"
  log_info "Run 'prefix + I' in tmux to install plugins"
}

install_orchis_theme() {
  log_info "Installing Orchis theme (orange)..."
  log_info "Skipping Orchis theme in this setup"
  return 0
}

setup_shell() {
  log_info "Setting up shell..."

  if [[ $SHELL == *"zsh"* ]]; then
    log_success "Zsh already default shell"
    return 0
  fi

  if log_dry "chsh -s $(which zsh)"; then
    return 0
  fi

  if ! chsh -s "$(which zsh)"; then
    log_warning "Failed to change shell to zsh"
    log_info 'Run manually: chsh -s $(which zsh)'
  else
    log_success "Default shell set to zsh"
  fi
}

enable_services() {
  log_info "Enabling system services..."

  if log_dry "sudo systemctl enable NetworkManager bluetooth cups keyd"; then
    return 0
  fi

  if ! systemctl is-enabled NetworkManager &>/dev/null; then
    sudo systemctl enable --now NetworkManager
    log_success "NetworkManager enabled"
  else
    log_success "NetworkManager already enabled"
  fi

  if ! systemctl is-enabled bluetooth &>/dev/null; then
    sudo systemctl enable --now bluetooth
    log_success "Bluetooth enabled"
  else
    log_success "Bluetooth already enabled"
  fi

  if ! systemctl is-enabled cups &>/dev/null; then
    sudo systemctl enable --now cups
    log_success "CUPS enabled"
  else
    log_success "CUPS already enabled"
  fi

  if ! systemctl is-enabled keyd &>/dev/null; then
    sudo systemctl enable --now keyd
    log_success "keyd enabled"
  else
    log_success "keyd already enabled"
  fi
}

setup_xdg_dirs() {
  log_info "Setting up XDG user directories..."

  if ! command_exists xdg-user-dirs-update; then
    log_warning "xdg-user-dirs-update not found, skipping"
    return 0
  fi

  if log_dry "xdg-user-dirs-update"; then
    return 0
  fi

  xdg-user-dirs-update
  log_success "XDG user directories created"
}

# ============================================================
# Interactive Menu
# ============================================================

show_menu() {
  echo
  echo -e "${LOG_BLUE}╔════════════════════════════════════════╗${LOG_NC}"
  echo -e "${LOG_BLUE}║${LOG_NC}         Dotfiles Installer            ${LOG_BLUE}║${LOG_NC}"
  echo -e "${LOG_BLUE}╚════════════════════════════════════════╝${LOG_NC}"
  echo
  echo "  1) Full setup (packages + symlinks)"
  echo "  2) Symlink configs only"
  echo "  3) Install packages only"
  echo
  echo "  q) Quit"
  echo

  read -rp "Choose an option [1]: " choice </dev/tty
  choice=${choice:-1}

  case "$choice" in
  1) SYMLINK_ONLY=false ;;
  2) SYMLINK_ONLY=true ;;
  3)
    install_packages
    exit 0
    ;;
  q | Q)
    log_info "Cancelled"
    exit 0
    ;;
  *)
    log_error "Invalid option: $choice"
    exit 1
    ;;
  esac
}

# ============================================================
# Argument Parsing
# ============================================================

show_help() {
  cat <<EOF
Dotfiles Install Script

Usage:
  ./install.sh [OPTIONS] [MODE]

Options:
  -h, --help      Show this help message
  -d, --dry-run   Show what would be done without making changes
  --debug         Enable debug output

Modes:
  1               Full setup (default)
  2               Symlink configs only

Examples:
  ./install.sh              # Interactive menu
  ./install.sh 1            # Full setup
  ./install.sh 2            # Symlink only
  ./install.sh --dry-run 1  # Preview full setup
EOF
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -d | --dry-run)
      DRY_RUN=true
      log_warning "Dry-run mode enabled"
      ;;
    --debug)
      DEBUG=true
      log_debug "Debug mode enabled"
      ;;
    1)
      SYMLINK_ONLY=false
      ;;
    2)
      SYMLINK_ONLY=true
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
    shift
  done
}

# ============================================================
# Main
# ============================================================

main() {
  check_os
  parse_arguments "$@"

  # Show menu if no mode specified via args
  if [[ $# -eq 0 ]] || { [[ $DRY_RUN == true || $DEBUG == true ]] && [[ $# -le 2 ]]; }; then
    local has_mode=false
    for arg in "$@"; do
      [[ $arg == "1" || $arg == "2" ]] && has_mode=true
    done
    [[ $has_mode == false ]] && show_menu
  fi

  echo
  log_info "Starting installation..."
  log_info "Dotfiles directory: $SCRIPT_DIR"
  echo

  if [[ $SYMLINK_ONLY == true ]]; then
    install_oh_my_zsh
    install_zsh_plugins
    setup_emacs_config
    symlink_configs
    install_tpm
  else
    install_packages
    setup_xdg_dirs
    install_oh_my_zsh
    install_zsh_plugins
    setup_emacs_config
    symlink_configs
    install_tpm
    setup_keyd
    install_orchis_theme
    setup_shell
    enable_services
  fi

  echo
  log_success "═══════════════════════════════════════"
  log_success "  Installation complete!"
  log_success "═══════════════════════════════════════"
  echo

  if [[ -d $BACKUP_DIR ]]; then
    log_info "Backups saved to: $BACKUP_DIR"
  fi

  if [[ $DRY_RUN == false && $SYMLINK_ONLY == false ]]; then
    echo
    read -rp "Reboot now? [Y/n]: " reboot_choice </dev/tty
    reboot_choice=${reboot_choice:-Y}

    if [[ $reboot_choice =~ ^[Yy]$ ]]; then
      log_info "Rebooting..."
      sudo reboot
    fi
  fi
}

main "$@"
