#!/usr/bin/env bash
# shellcheck disable=SC2016

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR
readonly GNOME_SHELL_VERSION="50"
readonly FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"
readonly NVM_VERSION="0.40.5"

DRY_RUN=0
ARCH=""
TEMP_DIR=""

readonly -a APT_PACKAGES=(
  7zip
  alacritty
  bat
  btop
  build-essential
  ca-certificates
  curl
  ddcutil
  eza
  fastfetch
  fd-find
  ffmpeg
  ffmpegthumbnailer
  flatpak
  fontconfig
  fwupd
  fzf
  git
  gnome-firmware
  gnome-shell-extension-manager
  gnome-shell-extension-prefs
  gnome-shell-ubuntu-extensions
  gnome-software
  gnome-software-plugin-flatpak
  gnome-tweaks
  gpg
  i2c-tools
  jq
  less
  nautilus
  openssh-client
  python3
  ripgrep
  shellcheck
  shfmt
  socat
  starship
  trash-cli
  unzip
  wget
  wl-clipboard
  xdg-utils
  xz-utils
  zoxide
  zsh
  zsh-antidote
)

readonly -a FLATPAK_APPS=(
  com.bitwarden.desktop
  com.fastmail.Fastmail
  org.localsend.localsend_app
)

readonly -a EXTENSION_IDS=(3193 9875 3843 1007 10319)
readonly -a EXTENSION_UUIDS=(
  blur-my-shell@aunetx
  o-tiling@oliwebd.github.com
  just-perfection-desktop@just-perfection
  windowIsReady_Remover@nunofarruca@gmail.com
  window-title-pro@eprahemi.github.io
)

readonly APPINDICATOR_UUID="ubuntu-appindicators@ubuntu.com"
readonly -a DISABLED_UBUNTU_EXTENSIONS=(
  ding@rastersoft.com
  snapd-prompting@canonical.com
  snapd-search-provider@canonical.com
  tiling-assistant@ubuntu.com
  ubuntu-dock@ubuntu.com
  web-search-provider@ubuntu.com
)

log() { printf '[ok] %s\n' "$*"; }
info() { printf '[..] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      *) die "unknown option: $arg" ;;
    esac
  done
}

format_command() {
  local arg
  printf '  $'
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

run_cmd() {
  if ((DRY_RUN)); then
    format_command "$@"
    return 0
  fi
  "$@"
}

run_sudo() {
  if ((DRY_RUN)); then
    format_command sudo "$@"
    return 0
  fi
  sudo "$@"
}

run_apt() {
  if ((DRY_RUN)); then
    format_command sudo env DEBIAN_FRONTEND=noninteractive apt-get "$@"
    return 0
  fi
  sudo env DEBIAN_FRONTEND=noninteractive apt-get "$@"
}

validate_sha256() {
  [[ $1 =~ ^[[:xdigit:]]{64}$ ]]
}

dpkg_installed_version() {
  local result state version
  result=$(dpkg-query -W -f='${db:Status-Status}\t${Version}' "$1" 2>/dev/null) || return 1
  IFS=$'\t' read -r state version <<<"$result"
  [[ $state == installed ]] || return 1
  printf '%s\n' "$version"
}

verify_file() {
  local file="$1" expected="$2" actual
  validate_sha256 "$expected" || die "invalid SHA-256 digest for $(basename "$file")"
  actual=$(sha256sum "$file" | awk '{print $1}')
  [[ $actual == "$expected" ]] || die "checksum mismatch for $(basename "$file")"
}

fetch() {
  local url="$1" destination="$2"
  curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    --retry 3 --output "$destination" "$url"
}

ensure_root_file() {
  local path="$1" content="$2" tmp
  if ((DRY_RUN)); then
    info "write $path"
    return 0
  fi

  tmp="$TEMP_DIR/$(basename "$path").new"
  printf '%s' "$content" >"$tmp"
  if sudo test -f "$path" && sudo cmp --silent "$tmp" "$path"; then
    return 0
  fi
  sudo install -D -o root -g root -m 0644 "$tmp" "$path"
}

read_os_release() {
  local os_release="${OS_RELEASE_FILE:-/etc/os-release}"
  [[ -r $os_release ]] || die "missing $os_release"
  # shellcheck disable=SC1090
  source "$os_release"
  [[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 26.04 ]] ||
    die "Ubuntu 26.04 is required"
}

detect_architecture() {
  ARCH=$(dpkg --print-architecture)
  [[ $ARCH == amd64 ]] || die "this setup currently supports amd64 only (detected $ARCH)"
}

validate_user_id() {
  (($1 != 0)) || die "run as the desktop user, not root"
}

validate_environment() {
  read_os_release
  detect_architecture
  validate_user_id "$EUID"
  validate_desktop_session
}

validate_desktop_session() {
  [[ ${XDG_CURRENT_DESKTOP:-} =~ (GNOME|Ubuntu) ]] ||
    die "run from a logged-in Ubuntu GNOME session"
  [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] ||
    die "a desktop D-Bus session is required"
  command -v gnome-shell >/dev/null || die "GNOME Shell is required"
}

create_temp_dir() {
  if ((DRY_RUN)); then
    TEMP_DIR="/tmp/dotfiles-setup-dry-run"
    return 0
  fi
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "${TEMP_DIR:-}"' EXIT
}

local_user_homes() {
  local passwd_file="${PASSWD_FILE:-/etc/passwd}"
  awk -F: '($3 == 0 || ($3 >= 1000 && $3 < 65534)) && $6 ~ /^\// {print $6}' \
    "$passwd_file" | sort -u
}

user_snap_data_present() {
  local home
  while IFS= read -r home; do
    [[ -e $home/snap || -e $home/.snap ]] && return 0
  done < <(local_user_homes)
  return 1
}

snap_state_present() {
  command -v snap >/dev/null || dpkg_installed_version snapd >/dev/null ||
    [[ -e /var/lib/snapd || -e /var/snap ]] || user_snap_data_present
}

confirm_snap_purge() {
  ((DRY_RUN)) && return 0
  snap_state_present || return 0
  [[ -r /dev/tty && -w /dev/tty ]] ||
    die "Snap deletion requires an interactive terminal"

  local reply
  printf 'Permanently delete all Snap packages and data? [y/N] ' >/dev/tty
  IFS= read -r reply </dev/tty || reply=""
  [[ ${reply,,} == y || ${reply,,} == yes ]] || die "cancelled"
}

bootstrap_apt() {
  info "refreshing APT metadata"
  run_apt update
  run_apt install -y ca-certificates curl gpg jq
}

snap_names() {
  snap list 2>/dev/null | awk 'NR > 1 {print $1}'
}

remove_snap_packages() {
  command -v snap >/dev/null || return 0

  local attempt snap removed
  local -a snaps=()
  for ((attempt = 1; attempt <= 3; attempt++)); do
    mapfile -t snaps < <(snap_names | grep -v '^snapd$' || true)
    ((${#snaps[@]})) || break
    removed=0
    for snap in "${snaps[@]}"; do
      if run_sudo snap remove --purge "$snap"; then
        removed=1
      else
        warn "Snap removal deferred for dependency ordering: $snap"
      fi
    done
    ((removed)) || break
  done

  if snap_names | grep -qx snapd; then
    run_sudo snap remove --purge snapd || warn "snapd Snap could not be removed separately"
  fi
}

remove_user_snap_data() {
  local home
  local -a homes=()
  mapfile -t homes < <(local_user_homes)
  for home in "${homes[@]}"; do
    run_sudo rm -rf -- "$home/snap" "$home/.snap"
  done
}

purge_snap() {
  info "removing Snap"
  ensure_root_file /etc/apt/preferences.d/no-snap.pref $'Package: snapd\nPin: release a=*\nPin-Priority: -10\n'

  if ((DRY_RUN)); then
    info "remove every installed Snap with snap remove --purge"
  else
    remove_snap_packages
  fi

  run_sudo systemctl disable --now snapd.socket snapd.service snapd.seeded.service 2>/dev/null || true
  run_apt purge -y snapd
  run_sudo rm -rf \
    /snap \
    /var/cache/snapd \
    /var/lib/snapd \
    /var/snap \
    /var/tmp/snap-private-tmp
  remove_user_snap_data
}

install_keyring() {
  local url="$1" path="$2"
  local armored binary
  armored="$TEMP_DIR/$(basename "$path").asc"
  binary="$TEMP_DIR/$(basename "$path")"
  if ((DRY_RUN)); then
    info "install signing key $path from $url"
    return 0
  fi
  fetch "$url" "$armored"
  gpg --batch --yes --dearmor --output "$binary" "$armored"
  if sudo test -f "$path" && sudo cmp --silent "$binary" "$path"; then
    return 0
  fi
  sudo install -D -o root -g root -m 0644 "$binary" "$path"
}

configure_vendor_repositories() {
  info "configuring Microsoft and Signal APT repositories"
  run_sudo rm -f \
    /etc/apt/sources.list.d/helium.list \
    /usr/share/keyrings/helium.gpg \
    /etc/apt/sources.list.d/vscode.list
  install_keyring \
    https://packages.microsoft.com/keys/microsoft.asc \
    /usr/share/keyrings/packages.microsoft.gpg
  ensure_root_file /etc/apt/sources.list.d/vscode.sources "Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: $ARCH
Signed-By: /usr/share/keyrings/packages.microsoft.gpg
"

  install_keyring \
    https://updates.signal.org/desktop/apt/keys.asc \
    /usr/share/keyrings/signal-desktop-keyring.gpg
  ensure_root_file /etc/apt/sources.list.d/signal-desktop.sources 'Types: deb
URIs: https://updates.signal.org/desktop/apt
Suites: xenial
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/signal-desktop-keyring.gpg
'
}

install_apt_software() {
  info "installing Ubuntu and vendor APT packages"
  run_apt update
  run_apt install -y "${APT_PACKAGES[@]}" code signal-desktop
}

install_uv() {
  if [[ -x $HOME/.local/bin/uv ]]; then
    log "$("$HOME/.local/bin/uv" --version) already installed"
    return 0
  fi
  if ((DRY_RUN)); then
    info "install uv with the official Astral installer"
    format_command bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    return 0
  fi

  curl -LsSf https://astral.sh/uv/install.sh | sh
  "$HOME/.local/bin/uv" --version >/dev/null || die "uv installation failed"
}

installed_nvm_version() {
  [[ -s $HOME/.nvm/nvm.sh ]] || return 1
  env NVM_DIR="$HOME/.nvm" bash -c '. "$NVM_DIR/nvm.sh"; nvm --version'
}

install_nvm() {
  local installed
  installed=$(installed_nvm_version 2>/dev/null || true)
  if [[ $installed == "$NVM_VERSION" ]]; then
    log "NVM $NVM_VERSION already installed"
    return 0
  fi
  if ((DRY_RUN)); then
    info "install NVM $NVM_VERSION with the official installer"
    format_command bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash"
    return 0
  fi

  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh" | bash
  installed=$(installed_nvm_version 2>/dev/null || true)
  [[ $installed == "$NVM_VERSION" ]] || die "NVM $NVM_VERSION installation failed"
}

install_node_lts() {
  if ((DRY_RUN)); then
    info "install current Node.js LTS and bundled npm with NVM"
    format_command bash -c '. "$NVM_DIR/nvm.sh"; nvm install --lts; nvm alias default "lts/*"'
    return 0
  fi

  [[ -s $HOME/.nvm/nvm.sh ]] || die "NVM is required before installing Node.js"
  env NVM_DIR="$HOME/.nvm" bash -c '
    set -e
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default "lts/*"
    nvm use default > /dev/null
    node --version
    npm --version
  '
}

install_pnpm() {
  if ((DRY_RUN)); then
    info "install pnpm globally with npm"
    format_command bash -c '. "$NVM_DIR/nvm.sh"; nvm use default; npm install --global pnpm'
    return 0
  fi

  env NVM_DIR="$HOME/.nvm" bash -c '
    set -e
    . "$NVM_DIR/nvm.sh"
    nvm use default > /dev/null
    npm install --global pnpm
    pnpm --version
  '
}

install_developer_tools() {
  info "installing developer runtimes and package managers"
  install_uv
  install_nvm
  install_node_lts
  install_pnpm
}

release_is_stable() {
  local json="$1"
  jq -e '.draft == false and .prerelease == false and (.tag_name | type == "string")' \
    "$json" >/dev/null
}

select_release_asset() {
  local json="$1" pattern="$2" label="$3" asset name url digest
  local -a assets=()
  release_is_stable "$json" || die "$label latest release is not stable"
  mapfile -t assets < <(
    jq -r --arg pattern "$pattern" '.assets[] | select(.name | test($pattern)) |
      [.name, .browser_download_url, .digest] | @tsv' "$json"
  )
  ((${#assets[@]} == 1)) || die "expected one $label release asset"
  asset=${assets[0]}
  IFS=$'\t' read -r name url digest <<<"$asset"
  digest=${digest#sha256:}
  [[ $url == https://* ]] || die "$label release asset has an invalid URL"
  validate_sha256 "$digest" || die "$label release asset has no valid digest"
  printf '%s\t%s\t%s\n' "$name" "$url" "$digest"
}

install_pacstall() {
  if ((DRY_RUN)); then
    info "resolve latest stable Pacstall .deb, verify GitHub digest, install with APT"
    return 0
  fi

  local json="$TEMP_DIR/pacstall-release.json"
  local tag name url digest installed deb asset
  fetch https://api.github.com/repos/pacstall/pacstall/releases/latest "$json"
  tag=$(jq -r '.tag_name | ltrimstr("v")' "$json")
  asset=$(select_release_asset "$json" '^pacstall_.+_all[.]deb$' 'Pacstall all-architecture .deb')
  IFS=$'\t' read -r name url digest <<<"$asset"

  installed=$(dpkg_installed_version pacstall || true)
  if [[ $installed == "$tag" || $installed == "$tag-"* ]]; then
    log "Pacstall $tag already installed"
    return 0
  fi

  deb="$TEMP_DIR/$name"
  fetch "$url" "$deb"
  verify_file "$deb" "$digest"
  run_apt install -y "$deb"
}

install_neovim() {
  info "installing Neovim from Pacstall"
  run_cmd pacstall -P -I neovim
}

nerd_fonts_release() {
  local json="$1"
  fetch https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest "$json"
  release_is_stable "$json" || die "Nerd Fonts latest release is not stable"
}

prepare_font_directory() {
  local path="$1"
  [[ -e $path || -L $path ]] || return 0
  if [[ -f $path/.version ]]; then
    rm -rf "$path"
  else
    backup_target "$path"
  fi
}

install_archive_font() {
  local release_json="$1" asset_name="$2" family_dir="$3" version="$4"
  local font_dir="$HOME/.local/share/fonts/$family_dir"
  local checksums_url asset_url checksum archive checksums extract_dir

  if [[ -f $font_dir/.version ]] && [[ $(<"$font_dir/.version") == "$version" ]]; then
    log "$family_dir $version already installed"
    return 0
  fi

  checksums_url=$(jq -r '.assets[] | select(.name == "SHA-256.txt") | .browser_download_url' "$release_json")
  asset_url=$(jq -r --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .browser_download_url' "$release_json")
  [[ -n $checksums_url && $checksums_url != null ]] || die "Nerd Fonts checksum asset missing"
  [[ -n $asset_url && $asset_url != null ]] || die "Nerd Fonts asset missing: $asset_name"

  checksums="$TEMP_DIR/nerd-fonts-SHA-256.txt"
  archive="$TEMP_DIR/$asset_name"
  extract_dir="$TEMP_DIR/${family_dir}-extract"
  fetch "$checksums_url" "$checksums"
  checksum=$(awk -v name="$asset_name" '$2 == name {print $1}' "$checksums")
  validate_sha256 "$checksum" || die "invalid Nerd Fonts checksum for $asset_name"
  fetch "$asset_url" "$archive"
  verify_file "$archive" "$checksum"

  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  tar -xJf "$archive" -C "$extract_dir"
  prepare_font_directory "$font_dir"
  mkdir -p "$font_dir"
  find "$extract_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp -f {} "$font_dir/" \;
  printf '%s\n' "$version" >"$font_dir/.version"
}

install_fonts() {
  if ((DRY_RUN)); then
    info "install current nerd-fonts-jetbrains-mono from Pacstall"
    info "install verified AdwaitaMono.tar.xz per-user"
    format_command fc-cache -f "$HOME/.local/share/fonts"
    return 0
  fi

  local release_json="$TEMP_DIR/nerd-fonts-release.json"
  local package_json="$TEMP_DIR/jetbrains-pacstall.json"
  local latest_version recipe_version recipe_checksum recipe_source upstream_checksum checksums_url
  nerd_fonts_release "$release_json"
  latest_version=$(jq -r '.tag_name | ltrimstr("v")' "$release_json")

  fetch https://pacstall.dev/api/packages/nerd-fonts-jetbrains-mono "$package_json"
  recipe_version=$(jq -r '.sourceVersion // empty' "$package_json")
  recipe_checksum=$(jq -r '.sha256sums[0].value // empty' "$package_json")
  recipe_source=$(jq -r '.source[0].value // empty' "$package_json")
  checksums_url=$(jq -r '.assets[] | select(.name == "SHA-256.txt") | .browser_download_url' "$release_json")
  fetch "$checksums_url" "$TEMP_DIR/nerd-fonts-SHA-256.txt"
  upstream_checksum=$(awk '$2 == "JetBrainsMono.tar.xz" {print $1}' \
    "$TEMP_DIR/nerd-fonts-SHA-256.txt")

  if pacstall_recipe_matches \
    "$recipe_version" "$recipe_checksum" "$recipe_source" \
    "$latest_version" "$upstream_checksum"; then
    local installed_jetbrains
    installed_jetbrains=$(dpkg_installed_version nerd-fonts-jetbrains-mono || true)
    if [[ $installed_jetbrains == "$latest_version" || $installed_jetbrains == "$latest_version-"* ]]; then
      log "JetBrains Mono Nerd Font $latest_version already installed"
    else
      run_cmd pacstall -P -I nerd-fonts-jetbrains-mono
    fi
    prepare_font_directory "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  else
    warn "Pacstall JetBrains Mono recipe is stale; using verified upstream font exception"
    if dpkg_installed_version nerd-fonts-jetbrains-mono >/dev/null; then
      run_apt purge -y nerd-fonts-jetbrains-mono
    fi
    install_archive_font "$release_json" JetBrainsMono.tar.xz JetBrainsMonoNerdFont "$latest_version"
  fi

  install_archive_font "$release_json" AdwaitaMono.tar.xz AdwaitaMonoNerdFont "$latest_version"
  run_cmd fc-cache -f "$HOME/.local/share/fonts"
}

pacstall_recipe_matches() {
  local recipe_version="$1" recipe_checksum="$2" recipe_source="$3"
  local latest_version="$4" upstream_checksum="$5"
  [[ $recipe_version == "$latest_version" &&
    $recipe_checksum == "$upstream_checksum" &&
    $recipe_source == *"/v$latest_version/JetBrainsMono.tar.xz" ]]
}

install_flatpaks() {
  info "installing user-scoped Flatpaks"
  verify_flathub_remote
  run_cmd flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL"
  if ((DRY_RUN)); then
    info "remove Zen Browser Flatpak if present"
  else
    if flatpak info --user app.zen_browser.zen >/dev/null 2>&1; then
      flatpak uninstall --user --noninteractive -y app.zen_browser.zen
    fi
    if flatpak info --system app.zen_browser.zen >/dev/null 2>&1; then
      sudo flatpak uninstall --system --noninteractive -y app.zen_browser.zen
    fi
  fi
  run_cmd flatpak install --user --noninteractive -y flathub "${FLATPAK_APPS[@]}"
}

verify_flathub_remote() {
  ((DRY_RUN)) && return 0
  local url
  url=$(flatpak remotes --user --columns=name,url |
    awk -F '\t' '$1 == "flathub" {print $2; exit}')
  [[ -z $url ]] && return 0
  case "${url%/}" in
    https://dl.flathub.org/repo | https://flathub.org/repo) ;;
    *) die "existing user flathub remote points to an unexpected URL: $url" ;;
  esac
}

helium_asset_arch() {
  case "$1" in
    amd64) printf 'amd64\n' ;;
    arm64) printf 'arm64\n' ;;
    *) return 1 ;;
  esac
}

helium_deb_version() {
  local name="$1" arch="$2" version
  [[ $name == helium-bin_*_"$arch".deb ]] || return 1
  version=${name#helium-bin_}
  version=${version%_"$arch".deb}
  [[ -n $version ]] || return 1
  printf '%s\n' "$version"
}

remove_legacy_helium_appimage() {
  local appimage="$HOME/AppImages/helium.AppImage"
  local desktop="$HOME/.local/share/applications/helium.desktop"
  if ((DRY_RUN)); then
    info "remove legacy Helium AppImage only when its desktop entry matches"
    return 0
  fi
  if [[ -f $desktop ]] && grep -Fq "Exec=$appimage" "$desktop"; then
    rm -f "$appimage" "$desktop"
  elif [[ -e $appimage ]]; then
    warn "leaving unrecognized Helium AppImage untouched: $appimage"
  fi
}

install_helium() {
  if ((DRY_RUN)); then
    info "resolve latest stable Helium $(helium_asset_arch "$ARCH") .deb, verify GitHub digest, install with APT"
    remove_legacy_helium_appimage
    format_command xdg-settings set default-web-browser helium.desktop
    return 0
  fi

  local json="$TEMP_DIR/helium-release.json" deb_arch name url digest version installed deb asset
  deb_arch=$(helium_asset_arch "$ARCH") || die "Helium does not support $ARCH"
  fetch https://api.github.com/repos/imputnet/helium-linux/releases/latest "$json"
  asset=$(select_release_asset "$json" "^helium-bin_.+_${deb_arch}[.]deb$" "Helium $deb_arch .deb")
  IFS=$'\t' read -r name url digest <<<"$asset"
  version=$(helium_deb_version "$name" "$deb_arch") || die "invalid Helium .deb filename"
  installed=$(dpkg_installed_version helium-bin || true)

  if [[ -n $installed ]] && dpkg --compare-versions "$installed" ge "$version"; then
    log "Helium $installed already installed"
  else
    deb="$TEMP_DIR/$name"
    fetch "$url" "$deb"
    verify_file "$deb" "$digest"
    run_apt install -y "$deb"
  fi
  remove_legacy_helium_appimage
  run_cmd xdg-settings set default-web-browser helium.desktop
}

extension_installed_version() {
  local uuid="$1"
  local metadata="$HOME/.local/share/gnome-shell/extensions/$uuid/metadata.json"
  [[ -f $metadata ]] || return 1
  jq -r '.version | tostring' "$metadata"
}

extension_metadata_valid() {
  local metadata="$1" uuid="$2" shell="$3" version="$4"
  jq -e --arg uuid "$uuid" --arg shell "$shell" --arg version "$version" \
    '.uuid == $uuid and (.version | tostring) == $version and
      ((."shell-version" // []) | index($shell) != null)' \
    <<<"$metadata" >/dev/null
}

install_extension() {
  local extension_id="$1" expected_uuid="$2"
  local info_json="$TEMP_DIR/extension-$extension_id.json"
  local uuid version installed zip metadata

  fetch "https://extensions.gnome.org/extension-info/?pk=$extension_id" "$info_json"
  uuid=$(jq -r '.uuid // empty' "$info_json")
  version=$(jq -r --arg shell "$GNOME_SHELL_VERSION" \
    '.shell_version_map[$shell].version // empty | tostring' "$info_json")
  [[ $uuid == "$expected_uuid" ]] || die "extension UUID mismatch for ID $extension_id"
  [[ $version =~ ^[0-9]+$ ]] || die "extension $uuid has no GNOME $GNOME_SHELL_VERSION release"

  installed=$(extension_installed_version "$uuid" 2>/dev/null || true)
  if [[ $installed == "$version" ]]; then
    log "$uuid version $version already installed"
    return 0
  fi

  zip="$TEMP_DIR/$uuid-$version.zip"
  fetch "https://extensions.gnome.org/api/v1/extensions/$uuid/versions/$version/?format=zip" "$zip"
  metadata=$(unzip -p "$zip" metadata.json) || die "metadata missing from extension $uuid"
  extension_metadata_valid "$metadata" "$uuid" "$GNOME_SHELL_VERSION" "$version" ||
    die "invalid extension metadata for $uuid"
  run_cmd gnome-extensions install --force "$zip"
}

install_extensions() {
  info "installing reviewed GNOME $GNOME_SHELL_VERSION extensions"
  if ((DRY_RUN)); then
    local uuid
    for uuid in "${EXTENSION_UUIDS[@]}"; do
      info "resolve, validate, and install $uuid"
    done
    return 0
  fi

  local index
  for index in "${!EXTENSION_IDS[@]}"; do
    install_extension "${EXTENSION_IDS[$index]}" "${EXTENSION_UUIDS[$index]}"
  done
}

array_contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ $item == "$needle" ]] && return 0
  done
  return 1
}

gvariant_array() {
  local item escaped separator="" output="["
  for item in "$@"; do
    escaped=${item//\'/\\\'}
    output+="$separator'$escaped'"
    separator=", "
  done
  printf '%s]\n' "$output"
}

read_gsettings_array() {
  gsettings get "$1" "$2" | python3 -c '
import ast
import sys

raw = sys.stdin.read().strip()
if raw.startswith("@as "):
    raw = raw[4:]
for value in ast.literal_eval(raw):
    print(value)
'
}

gs_set() {
  run_cmd gsettings set "$@"
}

configure_extension_state() {
  if ((DRY_RUN)); then
    info "enable requested extensions and AppIndicator; disable Ubuntu extensions; preserve unrelated extensions"
    return 0
  fi

  local item
  local -a enabled=() disabled=() new_enabled=() new_disabled=() required=()
  required=("${EXTENSION_UUIDS[@]}" "$APPINDICATOR_UUID")
  mapfile -t enabled < <(read_gsettings_array org.gnome.shell enabled-extensions)
  mapfile -t disabled < <(read_gsettings_array org.gnome.shell disabled-extensions)

  for item in "${enabled[@]}"; do
    if ! array_contains "$item" "${DISABLED_UBUNTU_EXTENSIONS[@]}" &&
      ! array_contains "$item" "${new_enabled[@]}"; then
      new_enabled+=("$item")
    fi
  done
  for item in "${required[@]}"; do
    array_contains "$item" "${new_enabled[@]}" || new_enabled+=("$item")
  done

  for item in "${disabled[@]}"; do
    if ! array_contains "$item" "${required[@]}" &&
      ! array_contains "$item" "${new_disabled[@]}"; then
      new_disabled+=("$item")
    fi
  done
  for item in "${DISABLED_UBUNTU_EXTENSIONS[@]}"; do
    array_contains "$item" "${new_disabled[@]}" || new_disabled+=("$item")
  done

  gs_set org.gnome.shell enabled-extensions "$(gvariant_array "${new_enabled[@]}")"
  gs_set org.gnome.shell disabled-extensions "$(gvariant_array "${new_disabled[@]}")"
}

configure_workspace_shortcuts() {
  local workspace
  for workspace in {1..7}; do
    gs_set org.gnome.desktop.wm.keybindings "switch-to-workspace-$workspace" \
      "['<Super>$workspace']"
    gs_set org.gnome.desktop.wm.keybindings "move-to-workspace-$workspace" \
      "['<Super><Shift>$workspace']"
    gs_set org.gnome.shell.keybindings "switch-to-application-$workspace" '[]'
  done
}

set_custom_shortcut() {
  local path="$1" name="$2" command="$3" binding="$4"
  local schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path"
  gs_set "$schema" name "$name"
  gs_set "$schema" command "$command"
  gs_set "$schema" binding "$binding"
}

configure_custom_shortcuts() {
  local base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
  local -a paths=(
    "$base/dotfiles-browser/"
    "$base/dotfiles-home/"
    "$base/dotfiles-signal/"
    "$base/dotfiles-fastmail/"
  )

  if ((DRY_RUN)); then
    info "append managed shortcuts while preserving unrelated custom shortcuts"
  else
    local path
    local -a existing=() merged=()
    mapfile -t existing < <(
      read_gsettings_array org.gnome.settings-daemon.plugins.media-keys custom-keybindings
    )
    for path in "${existing[@]}"; do
      array_contains "$path" "${merged[@]}" || merged+=("$path")
    done
    for path in "${paths[@]}"; do
      array_contains "$path" "${merged[@]}" || merged+=("$path")
    done
    gs_set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
      "$(gvariant_array "${merged[@]}")"
  fi

  set_custom_shortcut "${paths[0]}" Helium helium '<Super>w'
  set_custom_shortcut "${paths[1]}" Home "nautilus --new-window $HOME" '<Super>e'
  set_custom_shortcut "${paths[2]}" Signal signal-desktop '<Super>s'
  set_custom_shortcut "${paths[3]}" Fastmail \
    'flatpak run com.fastmail.Fastmail' '<Super>m'
}

configure_gnome() {
  info "configuring GNOME"
  gs_set org.gnome.shell disable-user-extensions false
  gs_set org.gnome.desktop.peripherals.keyboard repeat true
  gs_set org.gnome.desktop.peripherals.keyboard delay 250
  gs_set org.gnome.desktop.peripherals.keyboard repeat-interval 50
  gs_set org.gnome.mutter dynamic-workspaces false
  gs_set org.gnome.desktop.wm.preferences num-workspaces 7
  gs_set org.gnome.desktop.wm.preferences mouse-button-modifier '<Super>'
  gs_set org.gnome.desktop.wm.preferences resize-with-right-button true
  configure_workspace_shortcuts
  configure_custom_shortcuts
  configure_extension_state
}

backup_target() {
  local target="$1"
  local backup
  backup="$BACKUP_DIR/$(basename "$target")"
  mkdir -p "$BACKUP_DIR"
  if [[ -e $backup || -L $backup ]]; then
    backup="$backup.$(date +%s%N)"
  fi
  mv "$target" "$backup"
  info "backed up $target to $backup"
}

link_path() {
  local source="$1" target="$2"
  if [[ -L $target && $(readlink "$target") == "$source" ]]; then
    return 0
  fi
  if ((DRY_RUN)); then
    info "link $target -> $source"
    return 0
  fi
  [[ -e $source || -L $source ]] || die "missing dotfile source: $source"
  if [[ -e $target || -L $target ]]; then
    backup_target "$target"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
}

configure_dotfiles() {
  info "linking Ashen dotfiles"
  link_path "$SCRIPT_DIR/alacritty" "$HOME/.config/alacritty"
  link_path "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  link_path "$SCRIPT_DIR/btop" "$HOME/.config/btop"
  link_path "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  link_path "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
  link_path "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  link_path "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"

  link_path /usr/bin/batcat "$HOME/.local/bin/bat"
  link_path /usr/bin/fdfind "$HOME/.local/bin/fd"

  local current_shell
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  if [[ $current_shell != /usr/bin/zsh ]]; then
    run_sudo chsh -s /usr/bin/zsh "$USER"
  fi
}

configure_ddcutil() {
  info "reloading ddcutil device permissions"
  run_sudo udevadm control --reload-rules
  run_sudo udevadm trigger --subsystem-match=i2c-dev || warn "could not trigger i2c-dev udev rules"

  if ((DRY_RUN)); then
    format_command ddcutil detect
    format_command ddcutil getvcp 10
    return 0
  fi

  if ddcutil detect; then
    ddcutil getvcp 10 || warn "monitors detected, but brightness VCP 10 was unavailable"
  else
    warn "ddcutil found no controllable monitor; enable DDC/CI in each external monitor's OSD"
  fi
}

main() {
  parse_args "$@"
  validate_environment
  create_temp_dir
  confirm_snap_purge
  ((DRY_RUN)) || sudo -v

  bootstrap_apt
  purge_snap
  configure_vendor_repositories
  install_apt_software
  install_developer_tools
  install_pacstall
  install_neovim
  install_fonts
  install_flatpaks
  install_helium
  install_extensions
  configure_gnome
  configure_dotfiles
  configure_ddcutil

  log "setup complete"
  info "reboot once, then log in to activate GNOME extensions, shell, and device rules"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
