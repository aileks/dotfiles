#!/usr/bin/env bash

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
DISTRO=""
DISTRO_NAME=""
APT_UPDATED=0
TUI_BACKEND="bash"
DRY_RUN=0
NO_TUI=0
LIST_ONLY=0
AUR_HELPER=""

declare -a SETUP_ERRORS=()
declare -a SELECTED_ITEMS=()
declare -a QUEUED_FLATPAKS=()
declare -a QUEUED_APPIMAGES=()

declare -A ITEM_NAME=()
declare -A ITEM_CATEGORY=()
declare -A ITEM_DESC=()
declare -A ITEM_ARCH=()
declare -A ITEM_FEDORA=()
declare -A ITEM_UBUNTU=()
declare -A ITEM_AUR=()
declare -A ITEM_FLATPAK=()
declare -A ITEM_APPIMAGE_REPO=()
declare -A ITEM_APPIMAGE_PATTERN=()
declare -A ITEM_VENDOR=()

declare -A SEEN_FLATPAKS=()
declare -A SEEN_APPIMAGES=()

CATEGORIES=(
  editors
  terminals
  desktop
  browsers
  mail
  messengers
  passwords
  office
  devtools
)

declare -A CATEGORY_NAME=(
  [editors]="Code editor"
  [terminals]="Terminal"
  [desktop]="Desktop"
  [browsers]="Browser"
  [mail]="Mail client"
  [messengers]="Messengers"
  [passwords]="Password manager"
  [office]="Office suite"
  [devtools]="Dev tools"
)

declare -A CATEGORY_ITEMS=(
  [editors]="vscode neovim zed jetbrains_toolbox"
  [terminals]="kitty ghostty alacritty wezterm"
  [desktop]="desktop_gnome desktop_kde desktop_cosmic desktop_none"
  [browsers]="zen firefox brave chromium helium"
  [mail]="thunderbird fastmail proton_mail tuta"
  [messengers]="discord signal telegram element"
  [passwords]="bitwarden onepassword keepassxc"
  [office]="onlyoffice libreoffice"
  [devtools]="dev_tools"
)

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

dry_run() {
  [[ $DRY_RUN -eq 1 ]] && log_info "Dry run: $*"
}

command_exists() { command -v "$1" &> /dev/null; }

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]] && (: < /dev/tty) &> /dev/null
}

run_cmd() {
  if [[ $DRY_RUN -eq 1 ]]; then
    dry_run "$*"
    return 0
  fi
  "$@"
}

sudo_cmd() {
  if [[ $DRY_RUN -eq 1 ]]; then
    dry_run "sudo $*"
    return 0
  fi
  sudo "$@"
}

prompt_yes_no() {
  local prompt="$1" default="${2:-N}" reply suffix
  if [[ $default =~ ^[Yy]$ ]]; then
    suffix="[Y/n]"
  else
    suffix="[y/N]"
  fi

  if has_tty; then
    printf "%s %s " "$prompt" "$suffix" > /dev/tty
    if ! IFS= read -r reply < /dev/tty; then
      reply="$default"
    fi
  else
    reply="$default"
  fi

  reply=${reply:-$default}
  [[ $reply =~ ^[Yy]$ ]]
}

join_by() {
  local IFS="$1"
  shift
  echo "$*"
}

array_contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ $item == "$needle" ]] && return 0
  done
  return 1
}

# ============================================================
# Arguments and OS detection
# ============================================================

usage() {
  cat << 'EOF'
Usage: ./setup.sh [--dry-run] [--list] [--no-tui] [--help]

Options:
  --dry-run  Resolve prompts and print planned actions without installing.
  --list     Print available software selections and exit.
  --no-tui   Use numbered Bash prompts instead of whiptail.
  --help     Show this help text.
EOF
}

parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      --list) LIST_ONLY=1 ;;
      --no-tui) NO_TUI=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $arg"
        usage
        exit 1
        ;;
    esac
  done
}

detect_distro() {
  if [[ ! -r /etc/os-release ]]; then
    log_error "Unsupported OS: /etc/os-release is missing."
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  DISTRO_NAME="${PRETTY_NAME:-unknown Linux}"

  local os_tokens=" ${ID:-} ${ID_LIKE:-} "
  case "$os_tokens" in
    *" arch "* | *" manjaro "* | *" endeavouros "* | *" cachyos "* | *" garuda "*) DISTRO="arch" ;;
    *" fedora "* | *" rhel "* | *" nobara "*) DISTRO="fedora" ;;
    *" ubuntu "* | *" pop "* | *" linuxmint "* | *" elementary "* | *" neon "* | *" zorin "* | *" tuxedo "*) DISTRO="ubuntu" ;;
    *)
      log_error "Unsupported OS: $DISTRO_NAME"
      log_error "This installer supports Arch-based, Fedora-based, and Ubuntu-based systems."
      exit 1
      ;;
  esac

  log_success "Detected $DISTRO_NAME ($DISTRO)"
}

package_manager() {
  case "$DISTRO" in
    arch) echo "pacman" ;;
    fedora) echo "dnf" ;;
    ubuntu) echo "apt" ;;
  esac
}

# ============================================================
# Native package helpers
# ============================================================

refresh_native_metadata() {
  case "$DISTRO" in
    ubuntu)
      if [[ $APT_UPDATED -eq 0 ]]; then
        log_info "Refreshing APT metadata..."
        sudo_cmd apt update || return 1
        APT_UPDATED=1
      fi
      ;;
    arch)
      log_info "Refreshing pacman metadata..."
      sudo_cmd pacman -Sy --noconfirm || return 1
      ;;
    fedora)
      log_info "Refreshing DNF metadata..."
      sudo_cmd dnf makecache -y || return 1
      ;;
  esac
}

native_installed() {
  local pkg="$1"
  case "$DISTRO" in
    arch) pacman -Q "$pkg" &> /dev/null ;;
    fedora) rpm -q "$pkg" &> /dev/null ;;
    ubuntu) dpkg-query -W -f='${Status}' "$pkg" 2> /dev/null | grep -q "install ok installed" ;;
  esac
}

native_available() {
  local pkg="$1" candidate
  case "$DISTRO" in
    arch)
      pacman -Si "$pkg" &> /dev/null || pacman -Sg "$pkg" &> /dev/null
      ;;
    fedora)
      dnf -q list --available "$pkg" &> /dev/null || rpm -q "$pkg" &> /dev/null
      ;;
    ubuntu)
      candidate=$(apt-cache policy "$pkg" 2> /dev/null | awk '/Candidate:/ {print $2; exit}')
      [[ -n ${candidate:-} && $candidate != "(none)" ]]
      ;;
  esac
}

native_all_available_or_installed() {
  local pkg
  for pkg in "$@"; do
    native_installed "$pkg" || native_available "$pkg" || return 1
  done
  return 0
}

install_native_packages() {
  local packages=("$@")
  local missing=()
  local pkg

  [[ ${#packages[@]} -gt 0 ]] || return 0

  for pkg in "${packages[@]}"; do
    if native_installed "$pkg"; then
      log_success "Already installed: $pkg"
    else
      missing+=("$pkg")
    fi
  done

  [[ ${#missing[@]} -gt 0 ]] || return 0

  log_info "Installing native packages: ${missing[*]}"
  case "$DISTRO" in
    arch) sudo_cmd pacman -S --needed --noconfirm "${missing[@]}" ;;
    fedora) sudo_cmd dnf install -y "${missing[@]}" ;;
    ubuntu) sudo_cmd apt install -y "${missing[@]}" ;;
  esac
}

install_available_native_subset() {
  local packages=("$@")
  local available=()
  local missing=()
  local pkg

  for pkg in "${packages[@]}"; do
    if native_installed "$pkg" || native_available "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#available[@]} -gt 0 ]]; then
    install_native_packages "${available[@]}" || return 1
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_warning "No native package candidate for: ${missing[*]}"
  fi
}

ensure_git() {
  if command_exists git; then
    log_success "git already installed"
    return 0
  fi

  log_info "git is required before cloning dotfiles; installing it now..."
  refresh_native_metadata || {
    log_error "Failed to refresh package metadata before installing git"
    exit 1
  }
  install_native_packages git || {
    log_error "Failed to install git"
    exit 1
  }
}

ensure_tui() {
  if [[ $NO_TUI -eq 1 ]] || ! has_tty; then
    TUI_BACKEND="bash"
    return 0
  fi

  if command_exists whiptail; then
    TUI_BACKEND="whiptail"
    return 0
  fi

  local pkg
  case "$DISTRO" in
    arch) pkg="libnewt" ;;
    fedora) pkg="newt" ;;
    ubuntu) pkg="whiptail" ;;
  esac

  log_info "Installing whiptail TUI support..."
  refresh_native_metadata || true
  if install_native_packages "$pkg" && command_exists whiptail; then
    TUI_BACKEND="whiptail"
  else
    log_warning "whiptail is unavailable; using numbered Bash prompts"
    TUI_BACKEND="bash"
  fi
}

# ============================================================
# Dotfiles checkout bootstrap
# ============================================================

verify_dotfiles_repo() {
  [[ -d $DOTFILES_DIR ]] || return 1
  command_exists git || return 1
  pushd "$DOTFILES_DIR" &> /dev/null || return 1
  if ! git rev-parse --git-dir &> /dev/null; then
    popd &> /dev/null || true
    return 1
  fi
  local remote_url
  remote_url=$(git remote get-url origin 2> /dev/null || echo "")
  popd &> /dev/null || true
  [[ $remote_url == *"$DOTFILES_REPO"* || $remote_url == *"aileks/dotfiles"* ]]
}

prompt_replace_repo() {
  local existing_url choice
  existing_url=$(cd "$DOTFILES_DIR" 2> /dev/null && git remote get-url origin 2> /dev/null || echo "unknown")
  echo
  log_warning "Existing repository found at ~/.dotfiles"
  echo "  Expected: $DOTFILES_REPO"
  echo "  Found:    $existing_url"
  echo
  echo "  1) Backup and replace"
  echo "  2) Cancel"
  while true; do
    if has_tty; then
      printf "Choice [1/2]: " > /dev/tty
      IFS= read -r choice < /dev/tty || choice=2
    else
      choice=2
    fi
    case "$choice" in
      1)
        run_cmd mv "$DOTFILES_DIR" "${DOTFILES_DIR}${BACKUP_SUFFIX}"
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
  pushd "$DOTFILES_DIR" &> /dev/null || return 1
  git fetch origin &> /dev/null || {
    log_warning "Fetch failed, using local checkout"
    popd &> /dev/null || true
    return 0
  }
  local branch local_ref remote_ref
  branch=$(git symbolic-ref refs/remotes/origin/HEAD 2> /dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  local_ref=$(git rev-parse HEAD 2> /dev/null || echo "")
  remote_ref=$(git rev-parse "origin/$branch" 2> /dev/null || echo "")

  if [[ -z $remote_ref ]]; then
    log_warning "Remote branch origin/$branch not found; using local checkout"
  elif [[ $local_ref == "$remote_ref" ]]; then
    log_success "Already up to date"
  elif git merge-base --is-ancestor HEAD "origin/$branch"; then
    if git merge --ff-only "origin/$branch" &> /dev/null; then
      log_success "Fast-forwarded to latest"
    else
      log_warning "Fast-forward failed; using local checkout"
    fi
  else
    log_warning "Local repo is ahead or diverged; using local checkout"
  fi
  popd &> /dev/null || true
}

clone_repo() {
  log_info "Cloning dotfiles..."
  local i=1
  while [[ $i -le 3 ]]; do
    if run_cmd git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
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
    self_dir="$(cd "$(dirname "$self_path")" 2> /dev/null && pwd)" || self_dir=""
  fi

  ensure_git

  if [[ -n $self_dir && -d "$self_dir/zsh" ]]; then
    SCRIPT_DIR="$self_dir"
    return 0
  fi

  log_info "Starting dotfiles bootstrap..."

  if verify_dotfiles_repo; then
    update_existing_repo || exit 1
  elif [[ -d $DOTFILES_DIR ]]; then
    prompt_replace_repo
    clone_repo || exit 1
  else
    clone_repo || exit 1
  fi

  if [[ $DRY_RUN -eq 0 && ! -d "$DOTFILES_DIR/zsh" ]]; then
    log_error "Dotfiles checkout is missing expected zsh directory: $DOTFILES_DIR/zsh"
    exit 1
  fi

  SCRIPT_DIR="$DOTFILES_DIR"
  log_success "Using dotfiles from: $SCRIPT_DIR"
}

# ============================================================
# Catalog
# ============================================================

catalog_item() {
  local id="$1" category="$2" name="$3" desc="$4" arch="$5" fedora="$6" ubuntu="$7" flatpak="${8:-}" app_repo="${9:-}" app_pattern="${10:-}" vendor="${11:-}"
  ITEM_NAME[$id]="$name"
  ITEM_CATEGORY[$id]="$category"
  ITEM_DESC[$id]="$desc"
  ITEM_ARCH[$id]="$arch"
  ITEM_FEDORA[$id]="$fedora"
  ITEM_UBUNTU[$id]="$ubuntu"
  ITEM_FLATPAK[$id]="$flatpak"
  ITEM_APPIMAGE_REPO[$id]="$app_repo"
  ITEM_APPIMAGE_PATTERN[$id]="$app_pattern"
  ITEM_VENDOR[$id]="$vendor"
}

init_catalog() {
  catalog_item vscode editors "VS Code" "Microsoft code editor" "code" "" "" "com.visualstudio.code" "" "" "vscode"
  catalog_item neovim editors "Neovim" "Terminal-native editor" "neovim" "neovim" "neovim"
  catalog_item zed editors "Zed" "High-performance editor" "zed" "" "" "dev.zed.Zed"
  catalog_item jetbrains_toolbox editors "JetBrains Toolbox" "JetBrains IDE manager" "" "" "" "com.jetbrains.Toolbox"

  catalog_item kitty terminals "Kitty" "GPU terminal emulator" "kitty" "kitty" "kitty"
  catalog_item ghostty terminals "Ghostty" "Fast native terminal" "ghostty" "ghostty" "" "com.mitchellh.ghostty"
  catalog_item alacritty terminals "Alacritty" "GPU terminal emulator" "alacritty" "alacritty" "alacritty"
  catalog_item wezterm terminals "WezTerm" "Terminal emulator and multiplexer" "wezterm" "wezterm" "" "org.wezfurlong.wezterm"

  catalog_item desktop_gnome desktop "GNOME" "GNOME desktop with GDM" "gnome gdm" "gnome-shell gdm gnome-control-center gnome-terminal nautilus" "ubuntu-desktop gdm3"
  catalog_item desktop_kde desktop "KDE Plasma" "KDE Plasma with display manager" "plasma sddm" "plasma-desktop sddm dolphin konsole systemsettings" "kde-plasma-desktop sddm"
  catalog_item desktop_cosmic desktop "COSMIC" "COSMIC desktop with bundled greeter" "cosmic" "cosmic-desktop" "cosmic-session cosmic-greeter" "" "" "" "cosmic"
  catalog_item desktop_none desktop "None" "Do not install a desktop environment" "" "" ""

  catalog_item zen browsers "Zen Browser" "Firefox-based browser" "" "" "" "app.zen_browser.zen"
  catalog_item firefox browsers "Firefox" "Mozilla Firefox browser" "firefox" "firefox" "firefox"
  catalog_item brave browsers "Brave Browser" "Privacy-focused Chromium browser" "" "" "" "com.brave.Browser" "" "" "brave"
  catalog_item chromium browsers "Chromium" "Open-source Chromium browser" "chromium" "chromium" "" "org.chromium.Chromium"
  catalog_item helium browsers "Helium" "Privacy-focused Chromium browser" "" "" "" "" "imputnet/helium-linux" "AppImage" "helium"

  catalog_item thunderbird mail "Thunderbird" "Desktop mail client" "thunderbird" "thunderbird" "thunderbird"
  catalog_item fastmail mail "Fastmail" "Fastmail desktop app" "" "" "" "com.fastmail.Fastmail"
  catalog_item proton_mail mail "Proton Mail" "Proton Mail desktop app" "" "" "" "" "" "" "proton_mail"
  catalog_item tuta mail "Tuta/Tutanota" "Encrypted mail desktop app" "" "" "" "" "tutao/tutanota" "AppImage"

  catalog_item discord messengers "Discord" "Voice and chat client" "discord" "" "" "com.discordapp.Discord"
  catalog_item signal messengers "Signal" "Encrypted messenger" "signal-desktop" "" "" "org.signal.Signal" "" "" "signal"
  catalog_item telegram messengers "Telegram" "Telegram Desktop" "telegram-desktop" "telegram-desktop" "telegram-desktop"
  catalog_item element messengers "Element" "Matrix client" "element-desktop" "" "" "im.riot.Riot"

  catalog_item bitwarden passwords "Bitwarden" "Password manager" "bitwarden" "" "" "com.bitwarden.desktop"
  catalog_item onepassword passwords "1Password" "Password manager" "" "" "" "com.onepassword.OnePassword" "" "" "onepassword"
  catalog_item keepassxc passwords "KeePassXC" "Offline password manager" "keepassxc" "keepassxc" "keepassxc" "org.keepassxc.KeePassXC"

  catalog_item onlyoffice office "OnlyOffice" "Desktop office suite" "onlyoffice-desktopeditors" "" "" "org.onlyoffice.desktopeditors"
  catalog_item libreoffice office "LibreOffice" "Desktop office suite" "libreoffice-fresh" "libreoffice" "libreoffice" "org.libreoffice.LibreOffice"

  catalog_item dev_tools devtools "Core dev tools" "CLI/dev bundle from this repo" "" "" ""

  ITEM_AUR[vscode]="visual-studio-code-bin"
  ITEM_AUR[zed]="zed-git"
  ITEM_AUR[jetbrains_toolbox]="jetbrains-toolbox"
  ITEM_AUR[ghostty]="ghostty-git"
  ITEM_AUR[wezterm]="wezterm-git"
  ITEM_AUR[zen]="zen-browser-bin"
  ITEM_AUR[brave]="brave-bin"
  ITEM_AUR[helium]="helium-browser-bin"
  ITEM_AUR[fastmail]="fastmail"
  ITEM_AUR[proton_mail]="proton-mail-bin"
  ITEM_AUR[tuta]="tutanota-desktop-bin"
  ITEM_AUR[bitwarden]="bitwarden-bin"
  ITEM_AUR[onepassword]="1password"
  ITEM_AUR[onlyoffice]="onlyoffice-bin"
}

native_packages_for_item() {
  local id="$1"
  case "$DISTRO" in
    arch) echo "${ITEM_ARCH[$id]:-}" ;;
    fedora) echo "${ITEM_FEDORA[$id]:-}" ;;
    ubuntu) echo "${ITEM_UBUNTU[$id]:-}" ;;
  esac
}

list_catalog() {
  local category id
  for category in "${CATEGORIES[@]}"; do
    echo
    echo "${CATEGORY_NAME[$category]}:"
    for id in ${CATEGORY_ITEMS[$category]}; do
      echo "  - ${ITEM_NAME[$id]}"
    done
  done
}

# ============================================================
# TUI
# ============================================================

whiptail_checklist() {
  local title="$1" text="$2"
  shift 2
  whiptail --title "$title" --checklist "$text" 22 78 12 "$@" 3>&1 1> /dev/tty 2>&3 < /dev/tty
}

whiptail_radiolist() {
  local title="$1" text="$2"
  shift 2
  whiptail --title "$title" --radiolist "$text" 18 78 8 "$@" 3>&1 1> /dev/tty 2>&3 < /dev/tty
}

normalize_whiptail_selection() {
  tr -d '"' | xargs
}

bash_category_select() {
  local category raw choice selected=()
  local i=1
  local ids=()
  local out="/dev/stderr"

  has_tty && out="/dev/tty"
  {
    echo
    echo "Categories"
    echo "Enter category numbers separated by spaces, press Enter for all, or type none to skip software selection."
    for category in "${CATEGORIES[@]}"; do
      ids+=("$category")
      printf "  %2d) %s\n" "$i" "${CATEGORY_NAME[$category]}"
      i=$((i + 1))
    done
  } > "$out"

  if has_tty; then
    printf "Categories: " > /dev/tty
    IFS= read -r raw < /dev/tty || raw=""
  else
    raw=""
  fi

  raw=${raw:-all}
  [[ $raw == "none" ]] && return 0
  if [[ $raw == "all" ]]; then
    echo "${CATEGORIES[*]}"
    return 0
  fi

  for choice in $raw; do
    if [[ $choice =~ ^[0-9]+$ && $choice -ge 1 && $choice -le ${#ids[@]} ]]; then
      selected+=("${ids[$((choice - 1))]}")
    fi
  done
  echo "${selected[*]}"
}

select_categories() {
  local category result args=()

  if [[ $TUI_BACKEND == "whiptail" ]]; then
    for category in "${CATEGORIES[@]}"; do
      args+=("$category" "${CATEGORY_NAME[$category]}" "ON")
    done
    result=$(whiptail_checklist "Categories" "Choose categories to configure. Uncheck any category you want to skip." "${args[@]}") || result=""
    normalize_whiptail_selection <<< "$result"
    return 0
  fi

  bash_category_select
}

bash_multi_select() {
  local category="$1" id choices raw choice selected=()
  local out="/dev/stderr"
  local i=1
  local ids=()

  has_tty && out="/dev/tty"
  {
    echo
    echo "${CATEGORY_NAME[$category]}"
    echo "Enter one or more numbers separated by spaces, or press Enter to skip."
    for id in ${CATEGORY_ITEMS[$category]}; do
      ids+=("$id")
      printf "  %2d) %s - %s\n" "$i" "${ITEM_NAME[$id]}" "${ITEM_DESC[$id]}"
      i=$((i + 1))
    done
  } > "$out"
  if has_tty; then
    printf "Selection: " > /dev/tty
    IFS= read -r raw < /dev/tty || raw=""
  else
    raw=""
  fi

  for choice in $raw; do
    if [[ $choice =~ ^[0-9]+$ && $choice -ge 1 && $choice -le ${#ids[@]} ]]; then
      selected+=("${ids[$((choice - 1))]}")
    fi
  done
  echo "${selected[*]}"
}

bash_single_select() {
  local category="$1" id raw
  local out="/dev/stderr"
  local i=1
  local ids=()

  has_tty && out="/dev/tty"
  {
    echo
    echo "${CATEGORY_NAME[$category]}"
    for id in ${CATEGORY_ITEMS[$category]}; do
      ids+=("$id")
      printf "  %2d) %s - %s\n" "$i" "${ITEM_NAME[$id]}" "${ITEM_DESC[$id]}"
      i=$((i + 1))
    done
  } > "$out"
  if has_tty; then
    printf "Selection [4]: " > /dev/tty
    IFS= read -r raw < /dev/tty || raw="4"
  else
    raw="4"
  fi
  raw=${raw:-4}
  if [[ $raw =~ ^[0-9]+$ && $raw -ge 1 && $raw -le ${#ids[@]} ]]; then
    echo "${ids[$((raw - 1))]}"
  else
    echo "desktop_none"
  fi
}

select_category_items() {
  local category="$1" id result default_state args=()
  if [[ $TUI_BACKEND == "whiptail" ]]; then
    if [[ $category == "desktop" ]]; then
      for id in ${CATEGORY_ITEMS[$category]}; do
        default_state="OFF"
        [[ $id == "desktop_none" ]] && default_state="ON"
        args+=("$id" "${ITEM_NAME[$id]} - ${ITEM_DESC[$id]}" "$default_state")
      done
      result=$(whiptail_radiolist "${CATEGORY_NAME[$category]}" "Choose one desktop option." "${args[@]}") || result="desktop_none"
      echo "$(normalize_whiptail_selection <<< "$result")"
      return 0
    fi

    for id in ${CATEGORY_ITEMS[$category]}; do
      args+=("$id" "${ITEM_NAME[$id]} - ${ITEM_DESC[$id]}" "OFF")
    done
    result=$(whiptail_checklist "${CATEGORY_NAME[$category]}" "Select software to install." "${args[@]}") || result=""
    normalize_whiptail_selection <<< "$result"
    return 0
  fi

  if [[ $category == "desktop" ]]; then
    bash_single_select "$category"
  else
    bash_multi_select "$category"
  fi
}

select_software() {
  local category selection id
  local selected_categories=()
  SELECTED_ITEMS=()

  # shellcheck disable=SC2206
  selected_categories=($(select_categories))

  for category in "${selected_categories[@]}"; do
    selection=$(select_category_items "$category")
    for id in $selection; do
      [[ $id == "desktop_none" ]] && continue
      SELECTED_ITEMS+=("$id")
    done
  done
}

print_selected_summary() {
  local id
  echo
  if [[ ${#SELECTED_ITEMS[@]} -eq 0 ]]; then
    log_warning "No software selected."
    return 0
  fi
  log_info "Selected software:"
  for id in "${SELECTED_ITEMS[@]}"; do
    echo "  - ${ITEM_NAME[$id]}"
  done
}

# ============================================================
# Vendor/community source helpers
# ============================================================

download_to_tmp() {
  local url="$1" suffix="$2" tmp
  tmp=$(mktemp --suffix="$suffix") || return 1
  if curl -fsSL "$url" -o "$tmp"; then
    echo "$tmp"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

apt_install_deb_url() {
  local url="$1" tmp
  tmp=$(download_to_tmp "$url" ".deb") || return 1
  sudo_cmd apt install -y "$tmp"
  local status=$?
  rm -f "$tmp"
  return "$status"
}

dnf_install_rpm_url() {
  local url="$1"
  sudo_cmd dnf install -y "$url"
}

setup_vscode_repo() {
  case "$DISTRO" in
    ubuntu)
      install_available_native_subset ca-certificates curl gpg apt-transport-https
      if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
        log_info "Configuring Microsoft VS Code APT repository..."
        if [[ $DRY_RUN -eq 1 ]]; then
          dry_run "install Microsoft keyring and /etc/apt/sources.list.d/vscode.list"
        else
          curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg || return 1
          sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg || return 1
          rm -f /tmp/packages.microsoft.gpg
          echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |
            sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null || return 1
        fi
      fi
      APT_UPDATED=0
      refresh_native_metadata && install_native_packages code
      ;;
    fedora)
      log_info "Configuring Microsoft VS Code RPM repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "install Microsoft RPM key and vscode.repo"
      else
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || return 1
        sudo sh -c 'printf "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" > /etc/yum.repos.d/vscode.repo' || return 1
      fi
      refresh_native_metadata && install_native_packages code
      ;;
    arch)
      return 1
      ;;
  esac
}

setup_brave_repo() {
  case "$DISTRO" in
    ubuntu)
      install_available_native_subset curl gpg
      log_info "Configuring Brave APT repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "install Brave keyring and /etc/apt/sources.list.d/brave-browser-release.sources"
      else
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
          https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg || return 1
        sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
          https://brave-browser-apt-release.s3.brave.com/brave-browser.sources || return 1
      fi
      APT_UPDATED=0
      refresh_native_metadata && install_native_packages brave-browser
      ;;
    fedora)
      log_info "Configuring Brave RPM repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "dnf config-manager addrepo Brave repository"
      else
        sudo dnf install -y dnf-plugins-core || return 1
        sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo || return 1
        sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc || return 1
      fi
      refresh_native_metadata && install_native_packages brave-browser
      ;;
    arch)
      return 1
      ;;
  esac
}

setup_signal_repo() {
  case "$DISTRO" in
    ubuntu)
      install_available_native_subset curl gpg
      log_info "Configuring Signal APT repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "install Signal keyring and /etc/apt/sources.list.d/signal-desktop.sources"
      else
        curl -fsSL https://updates.signal.org/desktop/apt/keys.asc |
          gpg --dearmor > /tmp/signal-desktop-keyring.gpg || return 1
        sudo install -m 0644 /tmp/signal-desktop-keyring.gpg /usr/share/keyrings/signal-desktop-keyring.gpg || return 1
        rm -f /tmp/signal-desktop-keyring.gpg
        sudo curl -fsSL https://updates.signal.org/static/desktop/apt/signal-desktop.sources \
          -o /etc/apt/sources.list.d/signal-desktop.sources || return 1
      fi
      APT_UPDATED=0
      refresh_native_metadata && install_native_packages signal-desktop
      ;;
    arch | fedora)
      return 1
      ;;
  esac
}

setup_helium_repo() {
  case "$DISTRO" in
    ubuntu)
      install_available_native_subset curl gpg
      log_info "Configuring Helium APT repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "install Helium keyring and /etc/apt/sources.list.d/helium.list"
      else
        curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc |
          sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg || return 1
        echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" |
          sudo tee /etc/apt/sources.list.d/helium.list > /dev/null || return 1
      fi
      APT_UPDATED=0
      refresh_native_metadata && install_native_packages helium-bin
      ;;
    fedora)
      log_info "Configuring Helium COPR repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "dnf copr enable imput/helium"
      else
        sudo dnf install -y 'dnf-command(copr)' || true
        sudo dnf copr enable -y imput/helium || return 1
      fi
      refresh_native_metadata && install_native_packages helium-bin
      ;;
    arch)
      return 1
      ;;
  esac
}

setup_onepassword_repo() {
  case "$DISTRO" in
    ubuntu)
      install_available_native_subset curl gpg
      log_info "Configuring 1Password APT repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "install 1Password keyring and /etc/apt/sources.list.d/1password.list"
      else
        curl -sS https://downloads.1password.com/linux/keys/1password.asc |
          sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg || return 1
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
          sudo tee /etc/apt/sources.list.d/1password.list > /dev/null || return 1
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ /usr/share/debsig/keyrings/AC2D62742012EA22 || return 1
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
          sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null || return 1
        curl -sS https://downloads.1password.com/linux/keys/1password.asc |
          sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg || return 1
      fi
      APT_UPDATED=0
      refresh_native_metadata && install_native_packages 1password
      ;;
    fedora)
      log_info "Configuring 1Password RPM repository..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "install 1Password RPM key and yum repo"
      else
        sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc || return 1
        printf "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc\n" |
          sudo tee /etc/yum.repos.d/1password.repo > /dev/null || return 1
      fi
      refresh_native_metadata && install_native_packages 1password
      ;;
    arch)
      return 1
      ;;
  esac
}

setup_cosmic_repo() {
  case "$DISTRO" in
    ubuntu)
      if native_all_available_or_installed cosmic-session cosmic-greeter; then
        install_native_packages cosmic-session cosmic-greeter
        return $?
      fi
      log_warning "COSMIC packages are not available in this Ubuntu-family repo set."
      return 1
      ;;
    arch | fedora)
      return 1
      ;;
  esac
}

install_proton_mail_vendor() {
  local page pkg_url
  log_info "Looking for an official Proton Mail Linux package link..."
  if [[ $DRY_RUN -eq 1 ]]; then
    dry_run "scrape https://proton.me/mail/download for .deb/.rpm Linux desktop package"
    return 0
  fi

  page=$(curl -fsSL https://proton.me/mail/download) || return 1
  case "$DISTRO" in
    ubuntu)
      pkg_url=$(grep -Eo 'https://[^"]+\.deb' <<< "$page" | head -n1 || true)
      [[ -n $pkg_url ]] || return 1
      apt_install_deb_url "$pkg_url"
      ;;
    fedora)
      pkg_url=$(grep -Eo 'https://[^"]+\.rpm' <<< "$page" | head -n1 || true)
      [[ -n $pkg_url ]] || return 1
      dnf_install_rpm_url "$pkg_url"
      ;;
    arch)
      return 1
      ;;
  esac
}

install_vendor_item() {
  local id="$1"
  case "${ITEM_VENDOR[$id]:-}" in
    vscode) setup_vscode_repo ;;
    brave) setup_brave_repo ;;
    signal) setup_signal_repo ;;
    helium) setup_helium_repo ;;
    onepassword) setup_onepassword_repo ;;
    cosmic) setup_cosmic_repo ;;
    proton_mail) install_proton_mail_vendor ;;
    "") return 1 ;;
    *) return 1 ;;
  esac
}

# ============================================================
# Arch AUR helpers
# ============================================================

aur_helper() {
  [[ $DISTRO == "arch" ]] || return 1
  if [[ -n $AUR_HELPER ]]; then
    echo "$AUR_HELPER"
    return 0
  fi
  if command_exists yay; then
    AUR_HELPER="yay"
    echo "$AUR_HELPER"
    return 0
  fi
  if command_exists paru; then
    AUR_HELPER="paru"
    echo "$AUR_HELPER"
    return 0
  fi
  return 1
}

ensure_aur_helper() {
  local build_dir
  [[ $DISTRO == "arch" ]] || return 1

  if aur_helper > /dev/null; then
    log_success "AUR helper found: $AUR_HELPER"
    return 0
  fi

  log_info "No AUR helper found; installing yay..."
  refresh_native_metadata || true
  install_native_packages git base-devel || return 1

  if [[ $DRY_RUN -eq 1 ]]; then
    AUR_HELPER="yay"
    dry_run "git clone https://aur.archlinux.org/yay.git and makepkg -si --noconfirm"
    return 0
  fi

  build_dir=$(mktemp -d) || return 1
  if git clone https://aur.archlinux.org/yay.git "$build_dir/yay" &&
    (cd "$build_dir/yay" && makepkg -si --noconfirm); then
    rm -rf "$build_dir"
    AUR_HELPER="yay"
    return 0
  fi

  rm -rf "$build_dir"
  return 1
}

install_aur_package() {
  local pkg="$1" helper
  [[ $DISTRO == "arch" ]] || return 1

  ensure_aur_helper || return 1
  helper=$(aur_helper) || return 1

  log_info "Installing AUR package: $pkg"
  run_cmd "$helper" -S --needed --noconfirm "$pkg"
}

install_aur_item() {
  local id="$1" pkg
  [[ $DISTRO == "arch" ]] || return 1

  pkg="${ITEM_AUR[$id]:-}"
  [[ -n $pkg ]] || return 1

  install_aur_package "$pkg"
}

# ============================================================
# Flatpak and AppImage helpers
# ============================================================

queue_flatpak() {
  local app_id="$1" item_name="$2"
  [[ -n $app_id ]] || return 1
  if [[ -z ${SEEN_FLATPAKS[$app_id]:-} ]]; then
    QUEUED_FLATPAKS+=("$app_id")
    SEEN_FLATPAKS[$app_id]="$item_name"
    log_info "Queued Flatpak: $item_name ($app_id)"
  fi
}

flatpak_installed() {
  command_exists flatpak && flatpak info "$1" &> /dev/null
}

ensure_flatpak() {
  if command_exists flatpak; then
    return 0
  fi

  log_info "Installing Flatpak because selected software requires it..."
  refresh_native_metadata || true
  install_native_packages flatpak
}

install_queued_flatpaks() {
  local app_id
  [[ ${#QUEUED_FLATPAKS[@]} -gt 0 ]] || return 0

  ensure_flatpak || {
    record_error "flatpak is unavailable; skipping queued Flatpak apps"
    return 1
  }

  log_info "Configuring Flathub remote..."
  sudo_cmd flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || {
    record_error "Failed to configure Flathub"
    return 1
  }

  for app_id in "${QUEUED_FLATPAKS[@]}"; do
    if flatpak_installed "$app_id"; then
      log_success "Flatpak already installed: $app_id"
      continue
    fi
    log_info "Installing Flatpak: $app_id"
    run_cmd flatpak install -y flathub "$app_id" || record_error "Failed to install Flatpak: $app_id"
  done
}

queue_appimage() {
  local id="$1" name="$2"
  [[ -n ${ITEM_APPIMAGE_REPO[$id]:-} ]] || return 1
  if [[ -z ${SEEN_APPIMAGES[$id]:-} ]]; then
    QUEUED_APPIMAGES+=("$id")
    SEEN_APPIMAGES[$id]="$name"
    log_info "Queued AppImage: $name"
  fi
}

queue_appimage_url() {
  local id="$1" name="$2" url="$3"
  ITEM_APPIMAGE_REPO[$id]="direct:$url"
  ITEM_APPIMAGE_PATTERN[$id]=""
  if [[ -z ${SEEN_APPIMAGES[$id]:-} ]]; then
    QUEUED_APPIMAGES+=("$id")
    SEEN_APPIMAGES[$id]="$name"
    log_info "Queued AppImage: $name"
  fi
}

github_latest_appimage_url() {
  local repo="$1" pattern="$2" api url
  api="https://api.github.com/repos/$repo/releases/latest"
  url=$(curl -fsSL "$api" | awk -v pat="$pattern" '
    /"browser_download_url":/ {
      line=$0
      sub(/^.*"browser_download_url": "/, "", line)
      sub(/".*$/, "", line)
      if (line ~ pat) {
        print line
        exit
      }
    }
  ')
  [[ -n $url ]] || return 1
  echo "$url"
}

install_appimage_from_url() {
  local name="$1" url="$2" slug target desktop_file
  slug=$(tr '[:upper:] ' '[:lower:]-' <<< "$name" | tr -cd '[:alnum:]-')
  target="$HOME/AppImages/${slug}.AppImage"
  desktop_file="$HOME/.local/share/applications/${slug}.desktop"

  if [[ $DRY_RUN -eq 1 ]]; then
    dry_run "mkdir -p $HOME/AppImages and download $url to $target"
    return 0
  fi

  mkdir -p "$HOME/AppImages" "$HOME/.local/share/applications" || return 1
  curl -fL "$url" -o "$target" || return 1
  chmod +x "$target" || return 1
  cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=$name
Exec=$target
Icon=application-x-executable
Terminal=false
Categories=Utility;
EOF
  log_success "Installed AppImage: $target"
}

install_queued_appimages() {
  local id name repo pattern url
  [[ ${#QUEUED_APPIMAGES[@]} -gt 0 ]] || return 0

  for id in "${QUEUED_APPIMAGES[@]}"; do
    name="${SEEN_APPIMAGES[$id]}"
    repo="${ITEM_APPIMAGE_REPO[$id]:-}"
    pattern="${ITEM_APPIMAGE_PATTERN[$id]:-AppImage}"
    if [[ $repo == direct:* ]]; then
      url="${repo#direct:}"
    else
      log_info "Checking latest AppImage release for $name..."
      if [[ $DRY_RUN -eq 1 ]]; then
        dry_run "query GitHub latest release for $repo matching $pattern"
        continue
      fi
      url=$(github_latest_appimage_url "$repo" "$pattern") || {
        record_error "No AppImage asset found for $name"
        continue
      }
    fi
    install_appimage_from_url "$name" "$url" || record_error "Failed to install AppImage for $name"
  done
}

# ============================================================
# Software installation
# ============================================================

install_dev_tools() {
  local packages=()
  case "$DISTRO" in
    arch)
      packages=(
        base-devel ca-certificates curl wget git gnupg zsh trash-cli jq eza fd ripgrep
        wl-clipboard ddcutil ffmpegthumbnailer papirus-icon-theme ffmpeg shfmt bat fzf
        zoxide btop fastfetch starship
      )
      ;;
    fedora)
      packages=(
        ca-certificates curl wget git gnupg2 gcc gcc-c++ make automake autoconf
        pkgconf-pkg-config zsh trash-cli jq eza fd-find ripgrep wl-clipboard ddcutil
        ffmpegthumbnailer papirus-icon-theme ffmpeg shfmt bat fzf zoxide btop fastfetch starship
      )
      ;;
    ubuntu)
      packages=(
        ca-certificates curl wget git gpg software-properties-common build-essential
        zsh trash-cli jq eza fd-find ripgrep wl-clipboard ddcutil ffmpegthumbnailer
        papirus-icon-theme ffmpeg shfmt bat fzf zoxide btop fastfetch starship
      )
      ;;
  esac

  install_available_native_subset "${packages[@]}"
  setup_debian_cli_names
  install_uv
}

install_item() {
  local id="$1" name packages_string flatpak_id
  local packages=()

  [[ $id == "dev_tools" ]] && {
    install_dev_tools
    return 0
  }

  name="${ITEM_NAME[$id]}"
  packages_string=$(native_packages_for_item "$id")

  if [[ -n $packages_string ]]; then
    # shellcheck disable=SC2206
    packages=($packages_string)
    if native_all_available_or_installed "${packages[@]}"; then
      install_native_packages "${packages[@]}" && {
        log_success "Installed $name from distro repositories"
        configure_desktop_manager "$id"
        return 0
      }
    fi
    log_info "$name is not fully available from default distro repositories"
  fi

  if [[ $DISTRO == "arch" ]] && install_aur_item "$id"; then
    log_success "Installed $name from the AUR"
    configure_desktop_manager "$id"
    return 0
  fi

  if [[ $DISTRO != "arch" ]] && install_vendor_item "$id"; then
    log_success "Installed $name from vendor/community source"
    configure_desktop_manager "$id"
    return 0
  fi

  flatpak_id="${ITEM_FLATPAK[$id]:-}"
  if [[ -n $flatpak_id ]]; then
    queue_flatpak "$flatpak_id" "$name"
    return 0
  fi

  if queue_appimage "$id" "$name"; then
    return 0
  fi

  record_error "No automated install source configured for $name on $DISTRO"
}

install_selected_software() {
  local id
  [[ ${#SELECTED_ITEMS[@]} -gt 0 ]] || return 0

  refresh_native_metadata || record_error "Failed to refresh native package metadata"

  for id in "${SELECTED_ITEMS[@]}"; do
    log_info "Resolving ${ITEM_NAME[$id]}..."
    install_item "$id"
  done

  install_queued_flatpaks
  install_queued_appimages
}

configure_desktop_manager() {
  local id="$1" service=""
  case "$id" in
    desktop_gnome)
      case "$DISTRO" in
        ubuntu) service="gdm3" ;;
        *) service="gdm" ;;
      esac
      ;;
    desktop_kde) service="sddm" ;;
    desktop_cosmic) service="cosmic-greeter" ;;
    *) return 0 ;;
  esac

  if ! command_exists systemctl; then
    log_warning "systemctl not found; cannot enable $service display manager"
    return 0
  fi

  log_info "Enabling display manager: $service"
  sudo_cmd systemctl enable "$service" || record_error "Failed to enable display manager: $service"
}

setup_debian_cli_names() {
  [[ $DISTRO == "ubuntu" ]] || return 0
  mkdir -p "$HOME/.local/bin"

  if ! command_exists bat && command_exists batcat && [[ ! -e "$HOME/.local/bin/bat" ]]; then
    run_cmd ln -s "$(command -v batcat)" "$HOME/.local/bin/bat" &&
      log_success "Created ~/.local/bin/bat -> batcat" ||
      record_error "Failed to create bat alias symlink"
  fi

  if ! command_exists fd && command_exists fdfind && [[ ! -e "$HOME/.local/bin/fd" ]]; then
    run_cmd ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd" &&
      log_success "Created ~/.local/bin/fd -> fdfind" ||
      record_error "Failed to create fd alias symlink"
  fi
}

install_uv() {
  if command_exists uv; then
    log_success "uv already installed"
    return 0
  fi

  log_info "Installing uv..."
  if [[ $DRY_RUN -eq 1 ]]; then
    dry_run "curl -LsSf https://astral.sh/uv/install.sh | sh"
    return 0
  fi
  curl -LsSf https://astral.sh/uv/install.sh | sh || record_error "Failed to install uv"
}

# ============================================================
# Personal dotfile setup
# ============================================================

install_antidote() {
  local antidote_dir="$HOME/.antidote"
  if [[ -d "$antidote_dir/.git" ]]; then
    log_info "Updating antidote..."
    if run_cmd git -C "$antidote_dir" pull --ff-only --quiet; then
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
  run_cmd git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir" &&
    log_success "antidote installed at $antidote_dir" ||
    record_error "Failed to clone antidote"
}

create_symlink() {
  local source="$1" target="$2"

  if [[ ! -e $source && $DRY_RUN -eq 0 ]]; then
    record_error "Source missing: $source"
    return 1
  fi

  if [[ -L $target && "$(readlink "$target")" == "$source" ]]; then
    log_success "Already linked: $target"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    dry_run "link $target -> $source"
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
  log_info "Creating opinionated config symlinks..."
  run_cmd mkdir -p "$HOME/.config"

  create_symlink "$SCRIPT_DIR/btop" "$HOME/.config/btop"
  create_symlink "$SCRIPT_DIR/alacritty" "$HOME/.config/alacritty"
  create_symlink "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
  create_symlink "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
}

setup_shell() {
  log_info "Checking default shell..."
  if [[ ${SHELL:-} == *"zsh"* ]]; then
    log_success "Default shell is already zsh"
    return 0
  fi
  if ! command_exists zsh; then
    record_error "zsh is not installed; cannot change default shell"
    return 1
  fi
  if prompt_yes_no "Change your default shell to zsh?" "N"; then
    run_cmd chsh -s "$(command -v zsh)" || record_error "Failed to change shell to zsh"
  fi
}

run_personal_setup_prompt() {
  echo
  echo "This repo includes my opinionated dotfile configuration for zsh, Neovim,"
  echo "Alacritty, Starship, btop, bat, and fastfetch."
  if prompt_yes_no "Symlink these configs into your home directory? Choosing No leaves you with a blank slate." "N"; then
    install_antidote
    symlink_configs
    setup_shell
  else
    log_info "Skipping opinionated dotfile symlinks and personal shell setup."
  fi
}

# ============================================================
# Main
# ============================================================

main() {
  parse_args "$@"
  detect_distro
  init_catalog

  if [[ $LIST_ONLY -eq 1 ]]; then
    list_catalog
    exit 0
  fi

  resolve_script_dir
  ensure_tui

  echo
  echo -e "${LOG_YELLOW}This installer can add software, configure vendor/community package sources,"
  echo -e "install Flatpaks only when needed, and optionally symlink opinionated dotfiles.${LOG_NC}"
  echo -e "Source tree: ${LOG_GREEN}$SCRIPT_DIR${LOG_NC}"
  echo

  if [[ $DRY_RUN -eq 1 ]] && ! has_tty; then
    log_info "No TTY detected; dry run will use default empty selections."
  else
    if ! prompt_yes_no "Proceed to software selection?" "N"; then
      log_info "Aborted by user."
      exit 0
    fi
  fi

  if [[ $DRY_RUN -eq 1 ]] && ! has_tty; then
    SELECTED_ITEMS=()
  else
    select_software
  fi
  print_selected_summary

  if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
    if prompt_yes_no "Install selected software now?" "Y"; then
      install_selected_software
    else
      log_info "Skipped software installation."
    fi
  fi

  run_personal_setup_prompt

  echo
  log_success "Installation script finished."

  if [[ -d $BACKUP_DIR ]] && [[ "$(ls -A "$BACKUP_DIR" 2> /dev/null)" ]]; then
    log_info "Old configs backed up to: $BACKUP_DIR"
  fi

  if [[ ${#SETUP_ERRORS[@]} -gt 0 ]]; then
    echo
    echo -e "${LOG_RED}Errors during installation:${LOG_NC}"
    local err
    for err in "${SETUP_ERRORS[@]}"; do
      echo -e "  - $err"
    done
    echo -e "${LOG_YELLOW}Review the errors; manual intervention may be needed.${LOG_NC}"
    exit 1
  fi

  echo
  log_success "Zero errors encountered."
}

main "$@"
