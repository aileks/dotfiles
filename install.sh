#!/usr/bin/env bash
set -Eeuo pipefail

repo=$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
dry_run=false
in_chroot=false
phase=system
target_user=
target_home=
target_uid=
target_gid=
config_home=
data_home=
stamp=
work=
cleanup_directory=

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

parse_arguments() {
  while (($#)); do
    case $1 in
      --dry-run) dry_run=true ;;
      --chroot) in_chroot=true ;;
      --user)
        (($# >= 2)) && [[ -n $2 && $2 != -* ]] || fail '--user requires a username.'
        target_user=$2
        shift
        ;;
      --user-setup) phase=user ;;
      --help)
        echo 'Usage: ./install.sh [--chroot] [--user USER] [--dry-run]'
        exit 0
        ;;
      *) fail "Unknown argument: $1. Use --help for usage." ;;
    esac
    shift
  done
}

select_user() {
  local account
  if [[ -z $target_user ]]; then
    if ((EUID == 0)); then
      target_user=${SUDO_USER:-}
    else
      target_user=$(id -un)
    fi
  fi
  [[ -n $target_user && $target_user != root ]] || fail 'Root must specify an existing desktop account with --user USER.'
  account=$(getent passwd "$target_user") || fail "No such account: $target_user"
  IFS=: read -r target_user _ target_uid target_gid _ target_home _ <<<"$account"
  [[ $target_uid != 0 && $target_home == /* && -d $target_home ]] || fail 'The desktop account must have an existing home directory and a nonzero UID.'
  ((EUID == 0 || EUID == target_uid)) || fail 'Only root can configure another user.'
  [[ $phase != user || $EUID == "$target_uid" ]] || fail 'User setup must run as the desktop account.'
  config_home=$target_home/.config
  data_home=$target_home/.local/share
}

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  "$dry_run" || "$@"
}

as_user() {
  runuser -u "$target_user" -- env -i \
    HOME="$target_home" USER="$target_user" LOGNAME="$target_user" \
    PATH="$target_home/.local/bin:$target_home/.local/share/pnpm:/usr/local/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$config_home" XDG_DATA_HOME="$data_home" \
    LANG="${LANG:-C.UTF-8}" TERM="${TERM:-dumb}" "$@"
}

check_system_target() {
  local target=$1 parent=$1
  while [[ $parent != / ]]; do
    [[ ! -L $parent ]] || fail "Refusing system symlink: $parent"
    if [[ $parent != "$target" && -e $parent && ! -d $parent ]]; then
      fail "Expected a directory at $parent. Preserve its contents in a directory before rerunning."
    fi
    parent=$(dirname -- "$parent")
  done
  [[ ! -d $target ]] || fail "Expected a file at $target."
}

check_network_services() {
  local service
  for service in /etc/runlevels/{boot,default}/{dhcpcd,net.*,connman,wicd}; do
    [[ -L $service && ${service##*/} != net.lo ]] || continue
    fail "Conflicting network service: $service. Prepare NetworkManager and disable this service before rerunning."
  done
}

preflight() {
  local source relative path booted_root
  [[ -f /etc/gentoo-release && -d /etc/runlevels ]] || fail 'This installer requires Gentoo OpenRC.'
  [[ $(readlink -f /etc/portage/make.profile) == */profiles/default/linux/amd64/23.0/desktop ]] \
    || fail 'Prepare the default/linux/amd64/23.0/desktop OpenRC profile before running this installer.'
  portageq has_version / virtual/dist-kernel || fail 'Install and configure a Gentoo distribution kernel as part of the base installation.'
  if "$in_chroot"; then
    for path in /proc /sys /dev; do
      mountpoint -q "$path" || fail "Mount $path inside the installation chroot first."
    done
  else
    booted_root=$(stat -Lc '%d:%i' /proc/1/root 2>/dev/null || true)
    if [[ -n $booted_root && $(stat -Lc '%d:%i' /) != "$booted_root" ]]; then
      fail 'The target is not the booted root. Run with --chroot inside the installed Gentoo system.'
    fi
  fi
  [[ $repo == "$target_home/"* && -d $repo/.git ]] || fail 'Keep a Git checkout inside the desktop user home before running this installer.'
  [[ $(stat -c %u "$repo") == "$target_uid" ]] || fail "The checkout must belong to $target_user."
  for source in install.sh session/start-dwm session/start-session session/dwm.desktop config/xdg/mime-policy.json config/cron/crontab; do
    [[ -r $repo/$source ]] || fail "Missing repository source: $source"
  done
  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    check_system_target "/$relative"
  done < <(find "$repo/etc" -type f -print0)
  for path in /usr/share/xsessions/dwm.desktop /usr/local/bin/start-session /usr/local/bin/start-dwm /etc/nsswitch.conf /etc/subuid /etc/subgid /etc/inittab; do
    check_system_target "$path"
  done
  # Check all link sources before any package or system changes.
  (
    dry_run=true
    link_dotfiles
  ) >/dev/null
  if [[ -e $config_home/emacs || -L $config_home/emacs ]]; then
    [[ -x $config_home/emacs/bin/doom && -d $config_home/emacs/.git ]] || fail "Incomplete or unrelated Emacs installation at $config_home/emacs; preserve it elsewhere before rerunning."
  fi
  check_network_services
  (
    dry_run=true
    ensure_subordinate_ids /etc/subuid
    ensure_subordinate_ids /etc/subgid
  ) >/dev/null
}

base_packages=(
  sys-kernel/linux-firmware
  x11-drivers/nvidia-drivers
  net-misc/networkmanager
  sys-apps/dbus
  sys-apps/pciutils
  sys-apps/usbutils
  sys-auth/elogind
  net-misc/openssh
  app-admin/sudo
  sys-process/cronie
  gnome-base/gvfs
  net-dns/avahi
  sys-auth/nss-mdns
  net-print/cups
  net-wireless/bluez
  net-wireless/blueman
  app-shells/bash
  app-portage/gentoolkit
  app-eselect/eselect-repository
  app-portage/eix
)
cli_packages=(
  app-arch/7zip
  app-text/tree
  sys-apps/bat
  sys-apps/eza
  sys-process/psmisc
  sys-apps/fd
  app-shells/fzf
  app-misc/television
  dev-vcs/git
  app-misc/jq
  dev-util/sh
  sys-apps/ripgrep
  dev-db/sqlite
  app-misc/trash-cli
  app-arch/unzip
  net-misc/wget
  app-arch/zip
  app-shells/zoxide
  app-shells/starship
  dev-vcs/lazygit
  sys-fs/gdu
  sys-apps/nvme-cli
  sys-process/btop
  app-misc/fastfetch
  app-containers/podman
  app-containers/podman-compose
  app-containers/podman-tui
  net-misc/curl
)
desktop_packages=(
  x11-base/xorg-server
  x11-base/xorg-proto
  x11-misc/ly
  x11-terms/wezterm
  x11-misc/j4-dmenu-desktop
  x11-misc/picom
  x11-misc/xwallpaper
  x11-misc/i3lock-color
  x11-misc/xss-lock
  x11-misc/xautolock
  x11-misc/xdotool
  x11-misc/autorandr
  x11-apps/setxkbmap
  x11-apps/xset
  x11-libs/libX11
  x11-libs/libXft
  x11-libs/libXinerama
  media-libs/fontconfig
  media-gfx/maim
  x11-misc/slop
  x11-misc/xclip
  x11-misc/clipmenu
  app-misc/yazi
  app-text/zathura
  app-text/zathura-pdf-mupdf
  app-text/zathura-cb
  app-text/zathura-djvu
  media-video/mpv
  mpv-plugin/mpv-mpris
  x11-misc/pcmanfm
  x11-misc/dunst
  x11-misc/gammastep
  media-sound/playerctl
  media-sound/wiremix
  media-video/pipewire
  media-video/wireplumber
  media-sound/cava
  sci-calculators/qalculate-gtk
  sci-libs/libqalculate
  app-arch/file-roller
  sys-apps/gnome-disk-utility
  media-gfx/imv
  gnome-extra/polkit-gnome
  sys-fs/udiskie
  x11-misc/xdg-utils
  x11-misc/xdg-user-dirs
  sys-apps/xdg-desktop-portal-gtk
  x11-libs/libnotify
  media-video/ffmpeg
  media-video/ffmpegthumbnailer
  media-sound/alsa-utils
  app-misc/ddcutil
  media-video/libva-utils
  media-libs/nvidia-vaapi-driver
  x11-apps/mesa-progs
  dev-util/vulkan-tools
  sys-process/nvtop
  media-gfx/zbar
  app-text/tesseract
  app-dicts/myspell-en
  app-text/xmlstarlet
  sys-apps/keyutils
  app-crypt/pinentry
  gnome-base/gnome-keyring
  gnome-base/gsettings-desktop-schemas
  gnome-base/dconf
  gui-apps/qt6ct
  x11-themes/papirus-icon-theme
  x11-themes/adwaita-icon-theme
  media-fonts/adwaita-fonts
  media-fonts/nerdfonts
  media-fonts/noto
  media-fonts/noto-cjk
  media-fonts/noto-emoji
)
app_packages=(
  app-misc/openrgb
  media-video/gpu-screen-recorder
  net-vpn/ivpn
)
dev_packages=(
  sys-devel/gcc
  dev-debug/gdb
  dev-build/make
  sys-apps/bubblewrap
  dev-build/cmake
  app-editors/emacs
  app-editors/neovim
  dev-python/uv
  net-libs/nodejs
  dev-util/tree-sitter-cli
  dev-lang/zig
  dev-util/github-cli
  dev-util/ruff
  llvm-core/clang
  dev-lang/go
)
binary_packages=(
  www-client/zen-browser-bin
  net-im/signal-desktop-bin
  app-office/onlyoffice-bin
  app-admin/bitwarden-desktop-bin
  app-admin/bitwarden-cli-bin
  net-misc/localsend-bin
  net-vpn/ivpn-ui-bin
  sys-apps/pnpm-bin
  dev-util/shellcheck-bin
)
binhost_packages=(
  media-sound/easyeffects
  app-misc/anki
)

install_system_file() {
  local source=$1 target=$2 mode=${3:-644}
  check_system_target "$target"
  if [[ -f $target ]] && cmp -s -- "$source" "$target"; then
    if [[ $(stat -c '%u:%g:%a' "$target") != "0:0:$mode" ]]; then
      run chown root:root -- "$target"
      run chmod "$mode" -- "$target"
    fi
    return
  fi
  if [[ -e $target ]]; then
    run install -d -m 700 -- "/var/backups/dotfiles/$stamp$(dirname -- "$target")"
    run cp -a -- "$target" "/var/backups/dotfiles/$stamp$target"
  fi
  run install -D -o root -g root -m "$mode" -- "$source" "$target"
}

install_system_config() {
  local source relative mode
  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    install_system_file "$source" "/$relative"
  done < <(find "$repo/etc" -type f -print0 | sort -z)
  install_system_file "$repo/session/dwm.desktop" /usr/share/xsessions/dwm.desktop
  install_system_file "$repo/session/start-session" /usr/local/bin/start-session 755
  install_system_file "$repo/session/start-dwm" /usr/local/bin/start-dwm 755
}

install_xkb_layout() {
  local xkb_root
  xkb_root=$(readlink -f /usr/share/X11/xkb)
  install_system_file "$repo/config/xorg/keymap.xkb" "$xkb_root/symbols/aileks"
}

sync_overlays() {
  run emaint sync
}

emerge_options=(
  --verbose --noreplace --changed-use --autounmask=n
  --exclude 'virtual/dist-kernel sys-kernel/gentoo-kernel sys-kernel/gentoo-kernel-bin sys-kernel/installkernel sys-boot/limine dev-qt/qtwebengine'
)

install_packages() {
  local package
  local -a qtwebengine_options=(--verbose --oneshot --update --changed-use
    --autounmask=n --getbinpkg=y --usepkgonly=y --binpkg-respect-use=y)
  local -a source_packages=("${base_packages[@]}" "${cli_packages[@]}"
    "${desktop_packages[@]}" "${app_packages[@]}" "${dev_packages[@]}")
  # Install QtWebEngine only from binaries, then exclude it from source merges.
  run emerge "${qtwebengine_options[@]}" --pretend dev-qt/qtwebengine:6 \
    || fail 'Compatible binaries for QtWebEngine and its dependencies are required; source compilation is disabled.'
  run emerge "${qtwebengine_options[@]}" dev-qt/qtwebengine:6 \
    || fail 'QtWebEngine binary installation failed; source compilation is disabled.'
  run emerge "${emerge_options[@]}" --pretend --getbinpkg=n --usepkg=n \
    "${source_packages[@]}" "${binary_packages[@]}" "${binhost_packages[@]}"
  run emerge "${emerge_options[@]}" --getbinpkg=n --usepkg=n \
    "${source_packages[@]}" "${binary_packages[@]}"
  for package in "${binhost_packages[@]}"; do
    if "$dry_run"; then
      printf 'try emerge --pretend -gK %s; allow source fallback if unavailable\n' "$package"
    elif ! emerge --pretend --getbinpkg --usepkgonly --autounmask=n "$package"; then
      printf 'No compatible binary for %s; allowing a source build.\n' "$package"
    fi
    run emerge "${emerge_options[@]}" --getbinpkg=y --usepkg=y "$package"
  done
  # User patches do not trigger a rebuild of an already installed package.
  run emerge --oneshot --autounmask=n --getbinpkg=n --usepkg=n --exclude dev-qt/qtwebengine x11-misc/clipmenu
  run eix-update
}

build_desktop() {
  local program source relative mode
  run install -d -o "$target_uid" -g "$target_gid" -m 700 "$work/build"
  for program in dmenu dwm dwmblocks-async; do
    run as_user cp -a -- "$repo/config/$program" "$work/build/$program"
    if [[ $program == dwm ]]; then
      run as_user cp -- "$repo/config/dwm/config.def.h" "$work/build/dwm/config.h"
      run as_user cp -- "$repo/config/dwm/patches.def.h" "$work/build/dwm/patches.h"
    fi
    run as_user make -C "$work/build/$program" clean all
    run as_user make -C "$work/build/$program" DESTDIR="$work/build/stage" install
  done
  if "$dry_run"; then
    printf 'install staged desktop executables and manuals as root-owned files\n'
    return
  fi
  while IFS= read -r -d '' source; do
    relative=${source#"$work/build/stage/"}
    [[ $relative != usr/local/share/xsessions/dwm.desktop ]] || continue
    mode=644
    [[ $relative != usr/local/bin/* ]] || mode=755
    install_system_file "$source" "/$relative" "$mode"
  done < <(find "$work/build/stage" -type f -print0)
}

ensure_subordinate_ids() {
  local target=$1 start
  if [[ -f $target ]] && awk -F: -v user="$target_user" -v uid="$target_uid" \
    '($1 == user || $1 == uid) && $2 ~ /^[0-9]+$/ && $2 > 0 && $3 ~ /^[0-9]+$/ && $3 >= 65536 { found=1 } END { exit !found }' "$target"; then
    return
  fi
  if [[ -f $target ]] && awk -F: -v user="$target_user" -v uid="$target_uid" \
    '$1 == user || $1 == uid { found=1 } END { exit !found }' "$target"; then
    fail "Existing mappings for $target_user in $target need at least 65536 IDs; resolve them before rerunning."
  fi
  if "$dry_run"; then
    printf 'allocate 65536 unused IDs for %s in %s\n' "$target_user" "$target"
    return
  fi
  # Allocate above all existing ranges and real account/group IDs.
  start=$(awk -F: 'BEGIN { next_id=100000 }
    FILENAME == ARGV[1] { if ($2 + $3 > next_id) next_id=$2 + $3; next }
    $3 >= next_id && $3 < 4294967294 { next_id=$3 + 1 }
    END { printf "%.0f\n", next_id }' "${target}" /etc/passwd /etc/group)
  ((start + 65536 < 4294967294)) || fail "No subordinate IDs available in $target."
  cat "$target" >"$work/${target##*/}"
  printf '%s:%s:65536\n' "$target_user" "$start" >>"$work/${target##*/}"
  install_system_file "$work/${target##*/}" "$target"
}

configure_account() {
  local shell mapping_file
  shell=$(command -v bash || true)
  if "$dry_run"; then
    printf 'set %s login shell to Bash and add i2c membership if missing\n' "$target_user"
  else
    [[ -n $shell ]] || fail 'Bash was not installed.'
    shell=$(readlink -f "$shell")
    grep -Fxq "$shell" /etc/shells || fail "Bash is not listed in /etc/shells: $shell"
    if [[ $(getent passwd "$target_user" | cut -d: -f7) != "$shell" ]]; then
      run usermod --shell "$shell" "$target_user"
    fi
    if [[ " $(id -nG "$target_user") " != *' i2c '* ]]; then
      run usermod -aG i2c "$target_user"
    fi
    for mapping_file in /etc/subuid /etc/subgid; do
      if [[ ! -e $mapping_file ]]; then
        run install -m 644 /dev/null "$mapping_file"
      fi
    done
  fi
  ensure_subordinate_ids /etc/subuid
  ensure_subordinate_ids /etc/subgid
}

configure_mdns() {
  if "$dry_run"; then
    printf 'enable mDNS lookup in /etc/nsswitch.conf, preserving other lookup rules\n'
    return
  fi
  awk '
    /^hosts:[[:space:]]/ {
      found=1
      if ($0 !~ /(^|[[:space:]])mdns(4|6)?(_minimal)?([[:space:]]|$)/) {
        if (!sub(/(^|[[:space:]])files([[:space:]]|$)/, " files mdns4_minimal [NOTFOUND=return] ")) exit 1
      }
    }
    { print }
    END { if (!found) exit 1 }
  ' /etc/nsswitch.conf >"$work/nsswitch.conf" || fail 'Expected a hosts lookup containing files in /etc/nsswitch.conf.'
  install_system_file "$work/nsswitch.conf" /etc/nsswitch.conf
}

enable_services() {
  local service runlevel
  local services=(dbus elogind NetworkManager cronie bluetooth cupsd avahi-daemon ivpn ly)
  if ! "$dry_run"; then
    for service in "${services[@]}"; do
      [[ -x /etc/init.d/$service ]] || {
        echo "Missing OpenRC service: $service" >&2
        return 1
      }
    done
  fi

  check_network_services
  for service in display-manager xdm agetty.tty2; do
    for runlevel in boot default; do
      if [[ -L /etc/runlevels/$runlevel/$service ]]; then
        run rc-update del "$service" "$runlevel"
      fi
    done
  done
  if [[ -f /etc/inittab ]] && grep -qE '^[^#].*[[:space:]]tty2[[:space:]]' /etc/inittab; then
    run install -d -m 700 -- "/var/backups/dotfiles/$stamp/etc"
    run cp -a -- /etc/inittab "/var/backups/dotfiles/$stamp/etc/inittab"
    run sed -i '/^[^#].*[[:space:]]tty2[[:space:]]/s/^/#/' /etc/inittab
  fi
  for service in "${services[@]}"; do
    if [[ ! -L /etc/runlevels/default/$service && ! -L /etc/runlevels/boot/$service ]]; then
      run rc-update add "$service" default
    fi
  done
}

link() {
  local source=$1 target=$2 backup

  [[ -e $source ]] || {
    echo "Missing source: $source" >&2
    exit 1
  }
  [[ -L $target && $(readlink "$target") == "$source" ]] && return
  printf 'link %s -> %s\n' "$target" "$source"
  "$dry_run" && return
  mkdir -p -- "$(dirname "$target")"

  if [[ -e $target || -L $target ]]; then
    backup=$target.backup.$stamp
    [[ ! -e $backup && ! -L $backup ]] || exit 1
    mv -T -- "$target" "$backup"
    printf 'backup %s\n' "$backup"
  fi
  ln -sfnT -- "$source" "$target"
}

link_dotfiles() {
  local name desktop script target

  for name in bat btop cava dunst fastfetch fontconfig doom qt6ct zathura wezterm yazi picom nvim xdg-desktop-portal; do
    link "$repo/config/$name" "$config_home/$name"
  done

  link "$repo/config/mpv/mpv.conf" "$config_home/mpv/mpv.conf"
  link "$repo/config/mpv/script-opts" "$config_home/mpv/script-opts"
  link "$repo/config/bash/bashrc" "$target_home/.bashrc"
  link "$repo/config/bash/bash_profile" "$target_home/.bash_profile"
  link "$repo/config/starship/starship.toml" "$config_home/starship.toml"
  link "$repo/config/rsync-home.excludes" "$config_home/rsync-home.excludes"
  link "$repo/config/xorg/keymap.xkb" "$config_home/xkb/symbols/aileks"
  link "$repo/config/wallpaper/fantasy-woods.jpg" "$data_home/backgrounds/fantasy-woods.jpg"
  link "$repo/config/OpenRGB/NRGB.orp" "$config_home/OpenRGB/NRGB.orp"
  link "$repo/config/television/cable/portage.toml" "$config_home/television/cable/portage.toml"
  link "$repo/config/dwm/autostart.sh" "$data_home/dwm/autostart.sh"
  link "$repo/config/dwm/autostart_blocking.sh" "$data_home/dwm/autostart_blocking.sh"

  for desktop in "$repo/config/applications/"*.desktop; do
    link "$desktop" "$data_home/applications/${desktop##*/}"
  done

  for script in "$repo/bin/"*; do
    link "$script" "$target_home/.local/bin/${script##*/}"
  done
}

install_user_tools() {
  local work=$work/user-tools
  if "$dry_run"; then
    printf 'install bemoji, ModernZ, SQLFluff, SQLs, and Prettier\n'
    return
  fi
  mkdir -p "$work" "$HOME/.local/bin" "$data_home"
  git clone --depth 1 https://github.com/marty-oehme/bemoji.git "$work/bemoji"
  install -b -m 755 "$work/bemoji/bemoji" "$HOME/.local/bin/bemoji"
  mkdir -p "$data_home/bemoji"
  if [[ ! -s $data_home/bemoji/emojis.txt ]]; then
    curl --fail --location https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt \
      --output "$work/emoji-test.txt"
    sed -n 's/^.*; fully-qualified.*# \([^[:space:]]*\) [^[:space:]]* \(.*$\)/\1 \2/p' \
      "$work/emoji-test.txt" >"$work/emojis.txt"
    [[ -s $work/emojis.txt ]]
    install -m 644 "$work/emojis.txt" "$data_home/bemoji/emojis.txt"
  fi

  git clone --depth 1 https://github.com/Samillion/ModernZ.git "$work/modernz"
  mkdir -p "$config_home/mpv/scripts" "$config_home/mpv/fonts"
  install -b -m 644 "$work/modernz/modernz.lua" "$config_home/mpv/scripts/modernz.lua"
  install -b -m 644 "$work/modernz/modernz-icons.ttf" "$config_home/mpv/fonts/modernz-icons.ttf"

  uv tool install sqlfluff
  GOBIN="$HOME/.local/bin" go install github.com/sqls-server/sqls@v0.2.48
  PNPM_HOME="$data_home/pnpm" pnpm add --global prettier
}

install_doom() {
  local emacs_dir=${XDG_CONFIG_HOME:-$HOME/.config}/emacs
  if "$dry_run"; then
    printf 'clone Doom Emacs and install or sync packages\n'
    return
  fi
  if [[ ! -d $emacs_dir ]]; then
    git clone --depth 1 https://github.com/doomemacs/doomemacs.git "$work/doom-emacs"
    mv -T -- "$work/doom-emacs" "$emacs_dir"
    "$emacs_dir/bin/doom" install
    return
  fi
  [[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/doom/init.el ]] || {
    echo 'Doom config has no init.el yet; skipping sync.' >&2
    return 0
  }
  "$emacs_dir/bin/doom" sync
}

install_appearance() {
  local work=$work/appearance
  local name answer
  if "$dry_run"; then
    printf 'prompt for Cinder Grove GTK theme and recolored Papirus icons\n'
    return
  fi

  printf 'Install Cinder Grove GTK theme and recolored Papirus icons? [y/N] '
  if ! IFS= read -r answer; then
    answer=
  fi
  case $answer in
    y | Y | yes | YES) ;;
    *)
      printf 'skipping appearance setup\n'
      return 0
      ;;
  esac

  [[ -d /usr/share/icons/Papirus-Dark ]] || {
    echo 'Install Papirus first.' >&2
    return 1
  }
  mkdir -p "$work"

  replace() {
    local source=$1 target=$2
    if [[ ! -L $target && -e $target ]] && diff -qr -- "$source" "$target" >/dev/null; then
      return
    fi
    mkdir -p -- "$(dirname -- "$target")"
    if [[ -e $target || -L $target ]]; then
      mv -T -- "$target" "$target.backup.$stamp"
    fi
    cp -a -- "$source" "$target"
  }

  git clone --depth 1 https://github.com/aileks/cinder-grove-gtk.git "$work/gtk"
  printf 'y\n\n' | dbus-run-session -- "$work/gtk/install.sh"

  git clone --depth 1 --branch cinder-grove-folders \
    https://github.com/aileks/papirus-folders.git "$work/folders"
  mkdir -p "$work/icons" "$HOME/.local/bin"
  install -m 755 "$work/folders/papirus-folders-cg" "$work/papirus-folders-cg"
  for name in Papirus Papirus-Dark Papirus-Light; do
    cp -a -- "/usr/share/icons/$name" "$work/icons/$name"
    chmod -R u+w "$work/icons/$name"
  done
  USER_HOME="$work" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work" XDG_DATA_DIRS="$work" \
    "$work/papirus-folders-cg" --theme Papirus-Dark --color grove
  for name in Papirus Papirus-Dark Papirus-Light; do
    replace "$work/icons/$name" "$data_home/icons/$name"
  done
  replace "$work/papirus-folders-cg" "$HOME/.local/bin/papirus-folders-cg"

  run dbus-run-session -- gsettings set org.gnome.desktop.interface gtk-theme Cinder-Grove-Dark
}

setup_mime() {
  local directory name
  local -A installed=() resolved=() missing=()
  local policy mime browser target existing backup
  if "$dry_run"; then
    printf 'set MIME defaults from config/xdg/mime-policy.json\n'
    return
  fi

  for directory in "$data_home/applications" /usr/local/share/applications /usr/share/applications; do
    [[ -d $directory ]] || continue
    for name in "$directory/"*.desktop; do
      installed[${name##*/}]=$name
    done
  done

  browser=zen-browser-bin.desktop
  [[ -v installed[$browser] ]] || {
    echo "Missing desktop entry: $browser" >&2
    return 1
  }

  policy=$(jq -er 'to_entries[] | [.key, .value[0]] | @tsv' "$repo/config/xdg/mime-policy.json")
  while IFS=$'\t' read -r mime name; do
    [[ -v installed[$name] ]] || missing[$name]=1
    resolved[$mime]=$name
  done <<<"$policy"

  if ((${#missing[@]})); then
    echo 'Install or resolve these desktop IDs first:' >&2
    printf '  %s\n' "${!missing[@]}" | sort >&2
    return 1
  fi

  for mime in "${!resolved[@]}"; do
    printf '%s=%s;\n' "$mime" "${resolved[$mime]}"
  done | sort >"$work/mime-defaults"

  target=$config_home/mimeapps.list
  existing=/dev/null
  [[ -f $target ]] && existing=$target

  awk '
    function remaining( key) {
      for (key in defaults)
        if (!written[key]++) print key "=" defaults[key]
    }
    FILENAME == ARGV[1] {
      key = substr($0, 1, index($0, "=") - 1)
      defaults[key] = substr($0, index($0, "=") + 1)
      next
    }
    /^\[/ {
      if (section) remaining()
      section = ($0 ~ /^\[Default Applications\][[:space:]]*$/)
      if (section) found = 1
    }
    section && /^[^#;=]+=/ {
      key = substr($0, 1, index($0, "=") - 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key in defaults) {
        if (!written[key]++) print key "=" defaults[key]
        next
      }
    }
    { print }
    END {
      if (!found) print "\n[Default Applications]"
      remaining()
    }
  ' "$work/mime-defaults" "$existing" >"$work/mimeapps.list.merged"
  chmod 600 "$work/mimeapps.list.merged"

  if [[ -f $target ]] && cmp -s "$work/mimeapps.list.merged" "$target"; then
    rm -- "$work/mimeapps.list.merged"
  else
    if [[ -e $target || -L $target ]]; then
      backup=$target.backup.$stamp
      [[ ! -e $backup && ! -L $backup ]] || {
        echo 'MIME backup already exists' >&2
        return 1
      }
      mv -T -- "$target" "$backup"
    fi
    mv -- "$work/mimeapps.list.merged" "$target"
  fi

  xdg-settings set default-web-browser "$browser"

  for mime in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
    if [[ $(xdg-mime query default "$mime") != "$browser" ]]; then
      echo "MIME default verification failed for $mime" >&2
      return 1
    fi
  done
}

install_crontab() {
  if "$dry_run"; then
    printf 'merge config/cron/crontab into the user crontab (preserve unrelated jobs)\n'
    return
  fi
  if ! LC_ALL=C crontab -l >"$work/crontab" 2>"$work/crontab-error"; then
    grep -q '^no crontab for ' "$work/crontab-error" || {
      cat "$work/crontab-error" >&2
      return 1
    }
  fi
  awk '/^# BEGIN dotfiles$/ { managed=1; next }
       /^# END dotfiles$/ { managed=0; next }
       !managed { print }
       END { if (managed) exit 1 }' "$work/crontab" >"$work/crontab-new"
  {
    echo '# BEGIN dotfiles'
    cat "$repo/config/cron/crontab"
    echo '# END dotfiles'
  } >>"$work/crontab-new"
  if ! cmp -s "$work/crontab" "$work/crontab-new"; then
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
    cp "$work/crontab" "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/crontab-$stamp"
    crontab "$work/crontab-new"
  fi
}

setup_user() {
  export PATH="$target_home/.local/bin:$data_home/pnpm:$PATH"
  if ! "$dry_run"; then
    install -d -m 700 "$work/runtime"
    export XDG_RUNTIME_DIR="$work/runtime"
  fi
  link_dotfiles
  install_user_tools
  install_doom
  install_appearance
  run dbus-run-session -- gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  run dbus-run-session -- gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
  run dbus-run-session -- gsettings set org.gnome.desktop.interface cursor-theme Adwaita
  run dbus-run-session -- gsettings set org.gnome.desktop.interface cursor-size 24
  run dbus-run-session -- gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
  run dbus-run-session -- gsettings set org.gnome.desktop.interface monospace-font-name 'Iosevka Nerd Font 11'
  run dbus-run-session -- gsettings set org.gnome.desktop.interface clock-format 24h
  run dbus-run-session -- gsettings set org.gnome.desktop.wm.preferences button-layout ''
  run xdg-user-dirs-update
  setup_mime
  run fc-cache -f
  run bat cache --build
  install_crontab
}

main() {
  parse_arguments "$@"
  select_user
  if [[ $phase == system ]]; then
    preflight
    if ((EUID != 0)) && ! "$dry_run"; then
      command -v sudo >/dev/null || fail "Run as root with --user $target_user to bootstrap sudo."
      local -a arguments=(--user "$target_user")
      "$in_chroot" && arguments+=(--chroot)
      exec sudo -- "$repo/install.sh" "${arguments[@]}"
    fi
  fi

  stamp=$(date -u +%Y%m%dT%H%M%SZ)-$$
  umask 077
  work=/tmp/dotfiles-dry-run
  if ! "$dry_run"; then
    work=$(mktemp -d -t dotfiles.XXXXXXXX)
    cleanup_directory=$work
    trap 'rm -rf -- "$cleanup_directory"' EXIT
    trap 'printf "Installation failed at line %s. Fix the error above and rerun the same command.\n" "$LINENO" >&2' ERR
  fi

  if [[ $phase == user ]]; then
    setup_user
    return
  fi

  run emerge --noreplace --autounmask=n --getbinpkg=n --usepkg=n \
    dev-vcs/git app-admin/sudo app-eselect/eselect-repository
  run as_user git -C "$repo" submodule update --init --recursive
  if ! "$dry_run"; then
    [[ -r $repo/config/doom/init.el ]] || fail 'The Doom configuration submodule is incomplete.'
    # Only the user-owned build directory beneath this directory is accessible.
    chmod 711 "$work"
  fi
  install_system_config
  sync_overlays
  install_packages
  build_desktop
  install_xkb_layout
  configure_account
  configure_mdns
  if "$dry_run"; then
    setup_user
  else
    run as_user "$repo/install.sh" --user "$target_user" --user-setup
  fi
  enable_services
  if "$dry_run"; then
    echo 'Dry run complete; no changes made.'
  else
    echo 'Installation complete. Reboot to activate the services, groups, and desktop session.'
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
