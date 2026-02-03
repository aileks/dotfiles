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
OS_ID=""
OS_LIKE=""

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

detect_os() {
	if [[ -r /etc/os-release ]]; then
		# shellcheck disable=SC1091
		. /etc/os-release
		OS_ID=${ID:-""}
		OS_LIKE=${ID_LIKE:-""}
	fi
}

is_popos() {
	[[ $OS_ID == "pop" ]] || [[ $OS_LIKE == *"pop"* ]]
}

# ============================================================
# Package Lists
# ============================================================

# Most packages are installed via archinstall
PACMAN_PACKAGES=(
	base-devel
	pacman-contrib
	libgccjit
	gdb
	gvim
	emacs-wayland
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
	jq
	tree
	unzip
	unrar
	7zip
	geoclue
	yazi
	ifuse
	fzf
	zoxide
	eza
	bat
	fd
	ripgrep
	trash-cli
	zathura
	zathura-pdf-mupdf
	fastfetch
	btop
	calcurse
	qalculate-gtk
	mpv
	gst-plugins-good
	gst-plugins-bad
	gst-plugins-ugly
	gst-libav
	ffmpeg
	usbutils
	cups
	system-config-printer
	webp-pixbuf-loader
	noto-fonts
	noto-fonts-cjk
	noto-fonts-emoji
)

APT_PACKAGES=(
	curl
	gnupg
	xdg-utils
	build-essential
	libgccjit-13-dev
	gdb
	vim-gtk3
	emacs
	zsh
	gh
	tmux
	git
	man-db
	manpages
	wamerican
	hunspell
	hunspell-en-us
	jq
	tree
	unzip
	unrar
	p7zip-full
	geoclue-2.0
	ifuse
	fzf
	zoxide
	eza
	bat
	fd-find
	ripgrep
	trash-cli
	zathura
	zathura-pdf-mupdf
	btop
	calcurse
	qalculate-gtk
	mpv
	gstreamer1.0-plugins-good
	gstreamer1.0-plugins-bad
	gstreamer1.0-plugins-ugly
	gstreamer1.0-libav
	ffmpeg
	usbutils
	cups
	system-config-printer
	webp-pixbuf-loader
	fonts-noto
	fonts-noto-cjk
	fonts-noto-color-emoji
)

AUR_PACKAGES=(
	helium-browser-bin
	ttf-adwaita-mono-nerd
	ttf-mac-fonts
	1password
	1password-cli
	onlyoffice-bin
	keyd
)

PACSTALL_PACKAGES=(
	wezterm-bin
	onlyoffice-desktopeditors-deb
	keyd-deb
	fastfetch-git
)

# ============================================================
# Package Installation
# ============================================================

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

install_helium_appimage() {
	log_info "Installing Helium AppImage..."

	if [[ $DRY_RUN == true ]]; then
		log_dry "Download Helium AppImage and install desktop entry"
		log_dry "Set Helium as default browser"
		return 0
	fi

	if ! command_exists jq; then
		log_error "jq is required to install Helium"
		return 1
	fi

	local arch
	case "$(uname -m)" in
	x86_64 | amd64) arch="x86_64" ;;
	aarch64 | arm64) arch="arm64" ;;
	*)
		log_error "Unsupported architecture for Helium"
		return 1
		;;
	esac

	local release_json
	release_json=$(curl -fsSL "https://api.github.com/repos/imputnet/helium-linux/releases/latest")
	local tag
	tag=$(jq -r ".tag_name" <<<"$release_json")
	local appimage_url
	appimage_url=$(jq -r ".assets[] | select(.name | test(\"${arch}\\.AppImage$\")) | .browser_download_url" <<<"$release_json")

	if [[ -z $appimage_url || $appimage_url == "null" ]]; then
		log_error "Failed to find Helium AppImage for ${arch}"
		return 1
	fi

	if command_exists gpg; then
		local helium_key="BE677C1989D35EAB2C5F26C9351601AD01D6378E"
		local tmp_dir
		tmp_dir=$(mktemp -d)
		local tar_url="https://github.com/imputnet/helium-linux/releases/download/${tag}/helium-${tag}-${arch}_linux.tar.xz"
		local asc_url="${tar_url}.asc"

		if ! gpg --list-keys "$helium_key" &>/dev/null; then
			log_info "Importing Helium signing key..."
			gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$helium_key" || true
		fi

		if ! curl -fsSL "$tar_url" -o "$tmp_dir/helium.tar.xz"; then
			log_warning "Failed to download Helium tarball for signature verification"
		elif ! curl -fsSL "$asc_url" -o "$tmp_dir/helium.tar.xz.asc"; then
			log_warning "Failed to download Helium signature file"
		elif ! gpg --verify "$tmp_dir/helium.tar.xz.asc" "$tmp_dir/helium.tar.xz"; then
			log_error "Helium signature verification failed"
			rm -rf "$tmp_dir"
			return 1
		else
			log_success "Helium signature verified"
		fi

		rm -rf "$tmp_dir"
	else
		log_warning "gpg not available; skipping Helium signature verification"
	fi

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
	if is_popos; then
		install_apt_packages
		install_pacstall_packages
		install_1password
		install_helium_appimage
	else
		install_pacman_packages
		install_aur_packages
	fi
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
	create_symlink "$SCRIPT_DIR/yazi" "$HOME/.config/yazi"
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

	if is_popos; then
		log_info "Skipping Orchis theme on Pop!_OS COSMIC"
		return 0
	fi

	if command_exists gsettings; then
		local current_theme
		current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)
		if [[ $current_theme == *"Orchis"* ]]; then
			log_success "Orchis theme already configured"
			return 0
		fi
	fi

	if log_dry "Clone and install Orchis theme (orange)"; then
		return 0
	fi

	local tmp_dir
	tmp_dir=$(mktemp -d)
	if ! git clone --depth 1 https://github.com/vinceliuice/Orchis-theme "$tmp_dir/orchis-theme"; then
		log_warning "Failed to clone Orchis theme"
		rm -rf "$tmp_dir"
		return 1
	fi

	pushd "$tmp_dir/orchis-theme" &>/dev/null
	if ! ./install.sh -t orange; then
		log_warning "Failed to install Orchis theme"
		popd &>/dev/null
		rm -rf "$tmp_dir"
		return 1
	fi
	popd &>/dev/null

	rm -rf "$tmp_dir"
	log_success "Orchis theme installed"
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

setup_display_manager() {
	if is_popos; then
		log_info "Skipping display manager setup on Pop!_OS"
		return 0
	fi
	echo
	echo -e "${LOG_BLUE}╔════════════════════════════════════════╗${LOG_NC}"
	echo -e "${LOG_BLUE}║${LOG_NC}       Display Manager Selection        ${LOG_BLUE}║${LOG_NC}"
	echo -e "${LOG_BLUE}╚════════════════════════════════════════╝${LOG_NC}"
	echo
	echo "  1) ly             - ncurses-like display manager written in Zig"
	echo "  2) sddm           - Simple Desktop Display Manager"
	echo "  3) gdm            - GNOME Display Manager"
	echo "  4) lightdm        - Lightweight display manager"
	echo "  5) lemurs         - TUI display manager written in Rust"
	echo "  6) cosmic-greeter - COSMIC greetd-based display manager"
	echo "  7) none           - Skip display manager setup"
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
		dm_pkg="cosmic-greeter"
		dm_service="cosmic-greeter"
		;;
	7)
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

	if [[ $dm_pkg == "ly" ]]; then
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
Arch / Pop!_OS Dotfiles Install Script

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
	detect_os
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
		setup_display_manager
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
