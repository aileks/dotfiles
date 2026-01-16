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
	if [[ "$DEBUG" == true ]]; then
		echo -e "${LOG_CYAN}[DEBUG]${LOG_NC} $1"
	fi
}

log_dry() {
	if [[ "$DRY_RUN" == true ]]; then
		echo -e "${LOG_YELLOW}[DRY-RUN]${LOG_NC} Would: $1"
		return 0
	fi
	return 1
}

run_cmd() {
	if [[ "$DRY_RUN" == true ]]; then
		echo -e "${LOG_YELLOW}[DRY-RUN]${LOG_NC} $*"
		return 0
	fi
	log_debug "Running: $*"
	"$@"
}

command_exists() {
	command -v "$1" &>/dev/null
}

# ============================================================
# Package Lists
# ============================================================

PACMAN_PACKAGES=(
	base-devel
	pacman-contrib
	xorg-server
	xorg-xinit
	xorg-xsetroot
	xorg-xrandr
	xorg-xset
	xarchiver
	libx11
	libxft
	libxinerama
	libxrender
	libgccjit
	freetype2
	fontconfig
	imlib2
	neovim
	emacs
	zsh
	github-cli
	wezterm
	tmux
	git
	man-db
	man-pages
	words
	hunspell
	hunspell-en_us
	wget
	jq
	tree
	bc
	zip
	unzip
	unrar
	7zip
	xdg-user-dirs
	xdg-utils
	perl-file-mimeinfo
	polkit-gnome
	yazi
	pcmanfm
	gvfs
	gvfs-afc
	udisks2
	ntfs-3g
	dosfstools
	exfat-utils
	libimobiledevice
	ifuse
	picom
	dunst
	libnotify
	rofi
	rofimoji
	feh
	maim
	slop
	ffmpeg
	xclip
	xdotool
	pamixer
	playerctl
	networkmanager
	network-manager-applet
	nm-connection-editor
	fzf
	zoxide
	eza
	bat
	fd
	ripgrep
	trash-cli
	imagemagick
	zathura
	zathura-pdf-mupdf
	nsxiv
	fastfetch
	btop
	calcurse
	qalculate-gtk
	mypaint
	mpv
	gst-plugins-good
	gst-plugins-bad
	gst-plugins-ugly
	gst-libav
	usbutils
	bluez
	bluez-utils
	blueman
	cups
	system-config-printer
	ffmpegthumbnailer
	webp-pixbuf-loader
	noto-fonts
	noto-fonts-cjk
	noto-fonts-emoji
	ttf-libertinus
	papirus-icon-theme
	wiremix
)

AUR_PACKAGES=(
	helium-browser-bin
	betterlockscreen
	ttf-adwaita-mono-nerd
	ttf-mac-fonts
	1password
	1password-cli
	onlyoffice-bin
	keyd
)

# ============================================================
# Package Installation
# ============================================================

setup_chaotic_aur() {
	if pacman -Qq chaotic-keyring &>/dev/null; then
		log_success "Chaotic AUR already configured"
		return 0
	fi

	log_info "Setting up Chaotic AUR..."

	if log_dry "Setup Chaotic AUR keyring and mirrorlist"; then
		return 0
	fi

	sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	sudo pacman-key --lsign-key 3056513887B78AEB
	sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
	sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

	if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
		echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf >/dev/null
	fi

	if ! sudo pacman -Syu --noconfirm; then
		log_warning "Chaotic AUR sync failed (mirrors may be updating). Continuing anyway..."
	fi

	log_success "Chaotic AUR configured"
}

install_pacman_packages() {
	log_info "Installing pacman packages..."

	local to_install=()

	for pkg in "${PACMAN_PACKAGES[@]}"; do
		if ! pacman -Qq "$pkg" &>/dev/null; then
			to_install+=("$pkg")
		fi
	done

	if [[ ${#to_install[@]} -eq 0 ]]; then
		log_success "All pacman packages already installed"
		return 0
	fi

	log_info "Installing ${#to_install[@]} packages: ${to_install[*]:0:5}..."

	if log_dry "sudo pacman -S --needed --noconfirm ${to_install[*]}"; then
		return 0
	fi

	if ! sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
		log_error "Failed to install some pacman packages"
		exit 1
	fi

	log_success "Pacman packages installed"
}

install_aur_packages() {
	log_info "Installing AUR packages..."

	local helium_key="BE677C1989D35EAB2C5F26C9351601AD01D6378E"
	if ! gpg --list-keys "$helium_key" &>/dev/null; then
		log_info "Importing Helium browser GPG key..."
		gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$helium_key"
	fi

	local aur_helper=""
	if command_exists paru; then
		aur_helper="paru"
	elif command_exists yay; then
		aur_helper="yay"
	else
		log_error "No AUR helper found. Run setup.sh first."
		exit 1
	fi

	local to_install=()

	for pkg in "${AUR_PACKAGES[@]}"; do
		if ! pacman -Qq "$pkg" &>/dev/null; then
			to_install+=("$pkg")
		fi
	done

	if [[ ${#to_install[@]} -eq 0 ]]; then
		log_success "All AUR packages already installed"
		return 0
	fi

	log_info "Installing ${#to_install[@]} AUR packages with $aur_helper"

	if log_dry "$aur_helper -S --needed --noconfirm ${to_install[*]}"; then
		return 0
	fi

	if ! $aur_helper -S --needed --noconfirm "${to_install[@]}"; then
		log_warning "Some AUR packages failed to install"
		exit 1
	fi

	log_success "AUR packages installed"
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

# ============================================================
# Symlink Management
# ============================================================

backup_existing() {
	local target="$1"

	if [[ ! -e "$target" && ! -L "$target" ]]; then
		return 0
	fi

	if [[ -L "$target" ]]; then
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

	if [[ ! -e "$source" ]]; then
		log_warning "Source does not exist: $source"
		exit 1
	fi

	backup_existing "$target"

	local target_dir
	target_dir=$(dirname "$target")

	if [[ ! -d "$target_dir" ]]; then
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
	mkdir -p "$HOME/.local/share/dwm"

	# Direct directory symlinks
	create_symlink "$SCRIPT_DIR/btop" "$HOME/.config/btop"
	create_symlink "$SCRIPT_DIR/wezterm" "$HOME/.config/wezterm"
	create_symlink "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
	create_symlink "$SCRIPT_DIR/emacs" "$HOME/.config/emacs"
	create_symlink "$SCRIPT_DIR/picom" "$HOME/.config/picom"
	create_symlink "$SCRIPT_DIR/dunst" "$HOME/.config/dunst"
	create_symlink "$SCRIPT_DIR/zathura" "$HOME/.config/zathura"
	create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
	create_symlink "$SCRIPT_DIR/rofi" "$HOME/.config/rofi"
	create_symlink "$SCRIPT_DIR/rofimoji/rofimoji.rc" "$HOME/.config/rofimoji.rc"
	create_symlink "$SCRIPT_DIR/yazi" "$HOME/.config/yazi"
	create_symlink "$SCRIPT_DIR/betterlockscreen" "$HOME/.config/betterlockscreen"
	create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"

	# Single file symlinks
	create_symlink "$SCRIPT_DIR/X11/Xresources" "$HOME/.Xresources"
	create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
	create_symlink "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

	# Autostart script
	create_symlink "$SCRIPT_DIR/X11/xinitrc" "$HOME/.xinitrc"

	# Emacs: create ~/.emacs.d with symlinked config files
	log_info "Setting up Emacs configuration..."
	mkdir -p "$HOME/.emacs.d"
	ln -sf "$SCRIPT_DIR/emacs/early-init.el" "$HOME/.emacs.d/early-init.el"
	ln -sf "$SCRIPT_DIR/emacs/init.el" "$HOME/.emacs.d/init.el"
	ln -sf "$SCRIPT_DIR/emacs/modules" "$HOME/.emacs.d/modules"
	log_success "Emacs configuration linked"

	# Status bar scripts
	if [[ -d "$SCRIPT_DIR/scripts/statusbar" ]]; then
		for script in "$SCRIPT_DIR/scripts/statusbar/"*; do
			[[ -f "$script" ]] || continue
			create_symlink "$script" "$HOME/.local/bin/$(basename "$script")"
		done
	fi

	# Utility scripts
	create_symlink "$SCRIPT_DIR/scripts/screenshot" "$HOME/.local/bin/screenshot"
	create_symlink "$SCRIPT_DIR/scripts/screenrecord" "$HOME/.local/bin/screenrecord"
	create_symlink "$SCRIPT_DIR/scripts/rofi-power" "$HOME/.local/bin/rofi-power"

	log_success "Config symlinks created"
}

# ============================================================
# Build Suckless Tools
# ============================================================

build_dwm() {
	log_info "Building DWM..."

	if [[ ! -d "$SCRIPT_DIR/dwm" ]]; then
		log_error "DWM directory not found: $SCRIPT_DIR/dwm"
		exit 1
	fi

	if log_dry "cd $SCRIPT_DIR/dwm && sudo make clean install"; then
		return 0
	fi

	pushd "$SCRIPT_DIR/dwm" &>/dev/null

	if ! sudo make clean install; then
		log_error "Failed to build DWM"
		popd &>/dev/null
		exit 1
	fi

	popd &>/dev/null
	log_success "DWM installed"
}

build_dwmblocks() {
	log_info "Building dwmblocks..."

	if [[ ! -d "$SCRIPT_DIR/dwmblocks" ]]; then
		log_error "dwmblocks directory not found: $SCRIPT_DIR/dwmblocks"
		exit 1
	fi

	if log_dry "cd $SCRIPT_DIR/dwmblocks && sudo make clean install"; then
		return 0
	fi

	pushd "$SCRIPT_DIR/dwmblocks" &>/dev/null

	if ! sudo make clean install; then
		log_error "Failed to build dwmblocks"
		popd &>/dev/null
		exit 1
	fi

	popd &>/dev/null
	log_success "dwmblocks installed"
}

install_desktop_entry() {
	log_info "Installing dwm desktop entry..."

	if log_dry "sudo mkdir -p /usr/share/xsessions && sudo cp $SCRIPT_DIR/X11/dwm.desktop /usr/share/xsessions/dwm.desktop"; then
		return 0
	fi

	sudo mkdir -p /usr/share/xsessions
	sudo cp "$SCRIPT_DIR/X11/dwm.desktop" /usr/share/xsessions/dwm.desktop
	log_success "Desktop entry installed"
}

setup_keyd() {
	log_info "Setting up keyd (hyperkey)..."

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
	log_info "Installing tpm (Tmux Plugin Manager)..."

	local tpm_dir="$HOME/.tmux/plugins/tpm"

	if [[ -d "$tpm_dir" ]]; then
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

setup_shell() {
	log_info "Setting up shell..."

	if [[ "$SHELL" == *"zsh"* ]]; then
		log_success "Zsh already default shell"
		return 0
	fi

	if log_dry "chsh -s $(which zsh)"; then
		return 0
	fi

	if ! chsh -s "$(which zsh)"; then
		log_warning "Failed to change shell to zsh"
		log_info "Run manually: chsh -s \$(which zsh)"
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

setup_display_manager() {
	echo
	echo -e "${LOG_BLUE}╔════════════════════════════════════════╗${LOG_NC}"
	echo -e "${LOG_BLUE}║${LOG_NC}       Display Manager Selection        ${LOG_BLUE}║${LOG_NC}"
	echo -e "${LOG_BLUE}╚════════════════════════════════════════╝${LOG_NC}"
	echo
	echo "  1) ly       - ncurses-like display manager written in Zig"
	echo "  2) sddm     - Simple Desktop Display Manager"
	echo "  3) gdm      - GNOME Display Manager"
	echo "  4) lightdm  - Lightweight display manager"
	echo "  5) lemurs   - TUI display manager written in Rust"
	echo "  6) none     - Skip display manager setup"
	echo

	read -rp "Choose a display manager [1]: " dm_choice </dev/tty
	dm_choice=${dm_choice:-1}

	local dm_pkg=""
	local dm_service=""

	case "$dm_choice" in
	1)
		dm_pkg="ly"
		dm_service="ly"
		;;
	2)
		dm_pkg="sddm"
		dm_service="sddm"
		;;
	3)
		dm_pkg="gdm"
		dm_service="gdm"
		;;
	4)
		dm_pkg="lightdm"
		dm_service="lightdm"
		;;
	5)
		dm_pkg="lemurs"
		dm_service="lemurs"
		;;
	6)
		log_info "Skipping display manager setup"
		return 0
		;;
	*)
		log_warning "Invalid choice, skipping display manager setup"
		return 0
		;;
	esac

	log_info "Installing $dm_pkg..."

	if log_dry "sudo pacman -S --needed --noconfirm $dm_pkg"; then
		return 0
	fi

	if ! sudo pacman -S --needed --noconfirm "$dm_pkg"; then
		log_error "Failed to install $dm_pkg"
		exit 1
	fi

	log_success "$dm_pkg installed"

	log_info "Enabling $dm_service service..."

	if [[ "$dm_pkg" == "ly" ]]; then
		if ! systemctl is-enabled ly@tty1 &>/dev/null; then
			sudo systemctl disable getty@tty1.service 2>/dev/null || true
			sudo systemctl enable ly@tty1.service
			log_success "ly@tty1 enabled, getty@tty1 disabled"
		else
			log_success "ly@tty1 already enabled"
		fi

		log_info "Configuring console font for HiDPI..."
		if ! pacman -Qq terminus-font &>/dev/null; then
			sudo pacman -S --needed --noconfirm terminus-font
		fi
		echo "FONT=ter-132b" | sudo tee /etc/vconsole.conf >/dev/null
		log_success "Console font set to ter-132b"
	else
		if ! systemctl is-enabled "$dm_service" &>/dev/null; then
			sudo systemctl enable "$dm_service"
			log_success "$dm_service enabled"
		else
			log_success "$dm_service already enabled"
		fi
	fi
}

# ============================================================
# Interactive Menu
# ============================================================

show_menu() {
	echo
	echo -e "${LOG_BLUE}╔════════════════════════════════════════╗${LOG_NC}"
	echo -e "${LOG_BLUE}║${LOG_NC}    Arch Linux Dotfiles Installer       ${LOG_BLUE}║${LOG_NC}"
	echo -e "${LOG_BLUE}╚════════════════════════════════════════╝${LOG_NC}"
	echo
	echo "  1) Full setup (packages + symlinks + build)"
	echo "  2) Symlink configs only"
	echo "  3) Build suckless tools only (dwm + dwmblocks)"
	echo "  4) Install packages only"
	echo
	echo "  q) Quit"
	echo

	read -rp "Choose an option [1]: " choice </dev/tty
	choice=${choice:-1}

	case "$choice" in
	1) SYMLINK_ONLY=false ;;
	2) SYMLINK_ONLY=true ;;
	3)
		build_dwm
		build_dwmblocks
		exit 0
		;;
	4)
		setup_chaotic_aur
		install_pacman_packages
		install_aur_packages
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
Arch Linux Dotfiles Install Script

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
	parse_arguments "$@"

	# Show menu if no mode specified via args
	if [[ $# -eq 0 ]] || { [[ "$DRY_RUN" == true || "$DEBUG" == true ]] && [[ $# -le 2 ]]; }; then
		local has_mode=false
		for arg in "$@"; do
			[[ "$arg" == "1" || "$arg" == "2" ]] && has_mode=true
		done
		[[ "$has_mode" == false ]] && show_menu
	fi

	echo
	log_info "Starting installation..."
	log_info "Dotfiles directory: $SCRIPT_DIR"
	echo

	if [[ "$SYMLINK_ONLY" == true ]]; then
		install_oh_my_zsh
		install_zsh_plugins
		symlink_configs
		install_tpm
	else
		# setup_chaotic_aur
		install_pacman_packages
		install_aur_packages
		setup_xdg_dirs
		install_oh_my_zsh
		install_zsh_plugins
		symlink_configs
		install_tpm
		setup_keyd
		build_dwm
		build_dwmblocks
		install_desktop_entry
		setup_shell
		enable_services
		setup_display_manager
	fi

	echo
	log_success "═══════════════════════════════════════"
	log_success "  Installation complete!"
	log_success "═══════════════════════════════════════"
	echo

	if [[ -d "$BACKUP_DIR" ]]; then
		log_info "Backups saved to: $BACKUP_DIR"
	fi

	if [[ "$DRY_RUN" == false ]]; then
		echo
		read -rp "Reboot now? [Y/n]: " reboot_choice </dev/tty
		reboot_choice=${reboot_choice:-Y}

		if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
			log_info "Rebooting..."
			sudo reboot
		else
			log_info "Reboot skipped. Please reboot manually to apply all changes."
		fi
	fi
}

main "$@"
