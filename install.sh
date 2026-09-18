#!/usr/bin/env bash

set -Eeuo pipefail

repo=$(readlink -f -- "${BASH_SOURCE[0]}")
repo=${repo%/*}

dry_run=false
target_user=
target_home=
target_uid=
config_home=
data_home=
stamp=
work=
cleanup_directory=

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

select_user() {
  local account

  if ((EUID == 0)); then
    target_user=${SUDO_USER:-}
    [[ -n $target_user ]] || target_user=$(stat -c %U -- "$repo")
  else
    target_user=$(id -un)
  fi

  [[ -n $target_user && $target_user != root ]] || fail 'Could not determine the desktop account to install for.'
  account=$(getent passwd "$target_user") || fail "No such account: $target_user"
  IFS=: read -r target_user _ target_uid _ _ target_home _ <<<"$account"
  [[ $target_uid != 0 && $target_home == /* && -d $target_home ]] || fail 'The desktop account must have an existing home directory and a nonzero UID.'

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
    PATH="$target_home/.local/bin:/usr/local/bin:/usr/bin:/bin" \
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

    parent=${parent%/*}
    [[ -n $parent ]] || parent=/
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
  local source relative booted_root

  [[ -f /etc/gentoo-release && -d /etc/runlevels ]] || fail 'This installer requires Gentoo OpenRC.'
  portageq has_version / virtual/dist-kernel || fail 'Install and configure a Gentoo distribution kernel as part of the base installation.'
  gcc -march=znver5 -x c -fsyntax-only - <<<'int main(void){return 0;}' >/dev/null 2>&1 \
    || fail 'The installed gcc rejects -march=znver5; upgrade gcc before rerunning.'

  booted_root=$(stat -Lc '%d:%i' /proc/1/root 2>/dev/null || true)
  if [[ -n $booted_root && $(stat -Lc '%d:%i' /) != "$booted_root" ]]; then
    fail 'The target is not the booted root.'
  fi

  [[ $repo == "$target_home/"* && -d $repo/.git ]] || fail 'Keep a Git checkout inside the desktop user home before running this installer.'
  [[ $(stat -c %u "$repo") == "$target_uid" ]] || fail "The checkout must belong to $target_user."

  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    check_system_target "/$relative"
  done < <(find "$repo/etc" -type f -print0)

  dry_run=true link_dotfiles >/dev/null

  if [[ -e $config_home/emacs || -L $config_home/emacs ]]; then
    [[ -x $config_home/emacs/bin/doom && -d $config_home/emacs/.git ]] || fail "Incomplete or unrelated Emacs installation at $config_home/emacs; preserve it elsewhere before rerunning."
  fi

  check_network_services
}

packages=(
  # base system
  sys-kernel/linux-firmware
  x11-drivers/nvidia-drivers
  net-misc/networkmanager
  gnome-extra/nm-applet
  sys-apps/dbus
  sys-apps/pciutils
  sys-apps/usbutils
  sys-auth/elogind
  net-misc/openssh
  app-admin/doas
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
  media-libs/gst-plugins-base
  media-libs/gst-plugins-good
  media-libs/gst-plugins-bad
  media-libs/gst-plugins-ugly
  media-plugins/gst-plugins-libav
  media-libs/libpulse
  app-containers/docker
  app-containers/docker-cli
  app-containers/docker-compose

  # command line
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
  net-misc/rsync
  app-arch/zip
  app-shells/zoxide
  sys-apps/nvme-cli
  sys-process/btop
  app-misc/fastfetch
  net-misc/curl

  # desktop
  x11-wm/oxwm
  x11-base/xorg-server
  x11-misc/ly
  x11-misc/rofi
  media-libs/imlib2
  media-gfx/maim
  x11-misc/xclip
  x11-misc/xdotool
  x11-misc/xautolock
  x11-misc/xss-lock
  x11-misc/i3lock-color
  x11-misc/clipmenu
  x11-misc/xwallpaper
  x11-misc/slop
  x11-apps/xrandr
  x11-apps/xset
  x11-apps/xsetroot
  x11-apps/setxkbmap
  xkeyboard-config
  virtual/pkgconfig
  media-libs/fontconfig
  app-misc/yazi
  app-text/zathura
  app-text/zathura-pdf-mupdf
  app-text/zathura-cb
  app-text/zathura-djvu
  media-video/mpv
  mpv-plugin/mpv-mpris
  x11-misc/pcmanfm
  x11-misc/dunst
  media-sound/playerctl
  media-sound/wiremix
  media-video/pipewire
  media-video/wireplumber
  media-sound/cava
  sci-calculators/qalculate-gtk
  app-arch/file-roller
  sys-fs/ncdu
  media-gfx/imv
  gnome-extra/polkit-gnome
  sys-fs/udiskie
  xfce-base/tumbler
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
  app-text/tesseract
  app-text/tessdata_fast
  app-dicts/myspell-en
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
  dev-python/tldextract
  dev-python/pyperclip

  # applications
  app-misc/openrgb
  media-video/gpu-screen-recorder

  # development
  llvm-core/clang
  sys-devel/gcc
  dev-debug/gdb
  dev-build/make
  sys-apps/bubblewrap
  dev-build/cmake
  app-editors/emacs
  app-editors/neovim
  dev-libs/libvterm
  dev-java/openjdk-bin:21
  dev-java/google-java-format
  dev-lang/rust-bin
  dev-python/uv
  net-libs/nodejs
  dev-util/tree-sitter-cli
  dev-lang/zig-bin
  dev-util/github-cli
  dev-util/ccache

  # third-party binaries
  www-client/zen-browser-bin
  www-client/helium-bin
  net-im/signal-desktop-bin
  app-office/onlyoffice-bin
  app-admin/bitwarden-desktop-bin
  app-admin/bitwarden-cli-bin
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
    run install -d -m 700 -- "/var/backups/dotfiles/$stamp${target%/*}"
    run cp -a -- "$target" "/var/backups/dotfiles/$stamp$target"
  fi

  run install -D -o root -g root -m "$mode" -- "$source" "$target"
}

install_system_config() {
  local source relative xkb_root

  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    install_system_file "$source" "/$relative"
  done < <(find "$repo/etc" -type f -print0 | sort -z)

  while IFS= read -r -d '' source; do
    relative=${source#"$repo/overlay/"}
    install_system_file "$source" "/var/db/repos/aileks/$relative"
  done < <(find "$repo/overlay" -type f -print0 | sort -z)

  xkb_root=$(readlink -f /usr/share/X11/xkb)
  install_system_file "$repo/config/xkb/symbols/custom" "$xkb_root/symbols/custom"
}

emerge_options=(
  -vnU --autounmask=n
)

install_st() {
  if [[ -x /usr/local/bin/st ]]; then
    printf 'st already installed\n'
    return
  fi

  run as_user make -C "$repo/config/st" clean
  run as_user make -C "$repo/config/st"
  run make -C "$repo/config/st" PREFIX=/usr/local install
}

install_packages() {
  local repository location

  while read -r repository location; do
    if [[ ! -s $location/profiles/repo_name ]]; then
      run emaint sync -r "$repository"
    fi
  done < <(awk '/^\[/ { name=substr($0, 2, length($0)-2) } /^location = / { print name, $3 }' "$repo/etc/portage/repos.conf/desktop.conf")

  run emerge "${emerge_options[@]}" "${packages[@]}"

  run eix-update
}

configure_account() {
  local shell account

  shell=$(command -v bash || true)
  if "$dry_run"; then
    printf 'set %s login shell to Bash and add i2c and docker membership if missing\n' "$target_user"
  else
    [[ -n $shell ]] || fail 'Bash was not installed.'
    shell=$(readlink -f "$shell")
    grep -Fxq "$shell" /etc/shells || fail "Bash is not listed in /etc/shells: $shell"
    account=$(getent passwd "$target_user") || fail "No such account: $target_user"
    if [[ ${account##*:} != "$shell" ]]; then
      run usermod -s "$shell" "$target_user"
    fi

    if [[ " $(id -nG "$target_user") " != *' i2c '* ]]; then
      run usermod -aG i2c "$target_user"
    fi

    if [[ " $(id -nG "$target_user") " != *' docker '* ]]; then
      run usermod -aG docker "$target_user"
    fi
  fi
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

configure_inittab() {
  local target=/etc/inittab

  if "$dry_run"; then
    printf 'comment the tty2 agetty entry in /etc/inittab so ly owns tty2\n'
    return
  fi

  [[ -f $target ]] || fail "Expected an inittab at $target."
  awk '
    /^[^#]/ && /agetty/ && /(^|[[:space:]])tty2([^0-9]|$)/ { sub(/^/, "#") }
    { print }
  ' "$target" >"$work/inittab"
  if ! cmp -s -- "$work/inittab" "$target"; then
    install_system_file "$work/inittab" "$target"
    run telinit q
  fi
}

enable_services() {
  local service
  local services=(dbus elogind NetworkManager cronie bluetooth cupsd avahi-daemon docker ly)

  if ! "$dry_run"; then
    for service in "${services[@]}"; do
      [[ -x /etc/init.d/$service ]] || {
        echo "Missing OpenRC service: $service" >&2
        return 1
      }
    done
  fi

  check_network_services

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
  local config_dir desktop script

  for config_dir in bat btop cava dunst fastfetch fontconfig doom zathura yazi nvim rofi oxwm; do
    link "$repo/config/$config_dir" "$config_home/$config_dir"
  done

  link "$repo/config/qt6ct/colors" "$config_home/qt6ct/colors"
  link "$repo/config/qt6ct/qt6ct.conf" "$config_home/qt6ct/qt6ct.conf"
  link "$repo/config/mpv/mpv.conf" "$config_home/mpv/mpv.conf"
  link "$repo/config/mpv/script-opts" "$config_home/mpv/script-opts"
  link "$repo/config/bash/bashrc" "$target_home/.bashrc"
  link "$repo/config/bash/bash_profile" "$target_home/.bash_profile"
  link "$repo/config/x11/Xresources" "$target_home/.Xresources"
  link "$repo/config/rsync-home.excludes" "$config_home/rsync-home.excludes"
  link "$repo/config/postgres/config" "$config_home/postgres/config"
  link "$repo/config/OpenRGB/NRGB.orp" "$config_home/OpenRGB/NRGB.orp"
  link "$repo/config/television/cable/portage.toml" "$config_home/television/cable/portage.toml"

  for desktop in "$repo/config/applications/"*.desktop; do
    link "$desktop" "$data_home/applications/${desktop##*/}"
  done

  for script in "$repo/bin/"*; do
    link "$script" "$target_home/.local/bin/${script##*/}"
  done
}

install_user_tools() {
  local work=$work/user-tools
  local package name

  if "$dry_run"; then
    printf 'install missing pinned user tools\n'
    return
  fi

  mkdir -p "$work" "$HOME/.local/bin" "$data_home"

  if [[ ! -x $HOME/.local/bin/bemoji ]]; then
    curl -fL https://raw.githubusercontent.com/marty-oehme/bemoji/791c7748cf0236f691b1874e79ebe434469c20a9/bemoji -o "$work/bemoji"
    install -b -m 755 "$work/bemoji" "$HOME/.local/bin/bemoji"
  fi

  mkdir -p "$data_home/bemoji"
  if [[ ! -s $data_home/bemoji/emojis.txt ]]; then
    curl -fL https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt \
      -o "$work/emoji-test.txt"
    sed -n 's/^.*; fully-qualified.*# \([^[:space:]]*\) [^[:space:]]* \(.*$\)/\1 \2/p' \
      "$work/emoji-test.txt" >"$work/emojis.txt"
    [[ -s $work/emojis.txt ]]
    install -m 644 "$work/emojis.txt" "$data_home/bemoji/emojis.txt"
  fi

  if [[ ! -f $config_home/mpv/scripts/modernz.lua || ! -f $config_home/mpv/fonts/modernz-icons.ttf ]]; then
    mkdir -p "$config_home/mpv/scripts" "$config_home/mpv/fonts"
    for name in modernz.lua modernz-icons.ttf; do
      curl -fL "https://raw.githubusercontent.com/Samillion/ModernZ/579897e8c974c380caa5017dc7b27a69123c1333/$name" -o "$work/$name"
    done
    install -b -m 644 "$work/modernz.lua" "$config_home/mpv/scripts/modernz.lua"
    install -b -m 644 "$work/modernz-icons.ttf" "$config_home/mpv/fonts/modernz-icons.ttf"
  fi

  if [[ ! -x $HOME/.local/bin/resvg ]]; then
    curl -fL https://github.com/linebender/resvg/releases/download/v0.48.1/resvg-linux-x86_64.tar.gz -o "$work/resvg.tar.gz"
    tar xzf "$work/resvg.tar.gz" -C "$work"
    install -b -m 755 "$work/resvg" "$HOME/.local/bin/resvg"
  fi

  if [[ ! -x $HOME/.local/bin/sqlfluff ]]; then
    uv tool install --reinstall sqlfluff
  fi

  if [[ ! -x $HOME/.local/bin/ruff ]]; then
    uv tool install --reinstall ruff
  fi

  for package in pnpm@12.4.1 prettier@3.9.6; do
    if [[ ! -d $NPM_CONFIG_PREFIX/lib/node_modules/${package%@*} ]]; then
      npm install -g "$package"
    fi
  done
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
    printf 'prompt for Cinder Muted GTK theme and recolored Papirus icons\n'
    return
  fi

  printf 'Install Cinder Muted GTK theme and recolored Papirus icons? [y/N] '
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

  git clone --depth 1 https://github.com/aileks/cinder-muted "$work/cinder-muted"
  run "$work/cinder-muted/gtk/install.sh"

  git clone --depth 1 -b cinder-grove-folders \
    https://github.com/aileks/papirus-folders.git "$work/folders"
  mkdir -p "$work/icons" "$HOME/.local/bin"
  install -m 755 "$work/folders/papirus-folders-cg" "$work/papirus-folders-cg"
  for name in Papirus Papirus-Dark Papirus-Light; do
    cp -a -- "/usr/share/icons/$name" "$work/icons/$name"
    chmod -R u+w "$work/icons/$name"
  done
  USER_HOME="$work" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work" XDG_DATA_DIRS="$work" \
    "$work/papirus-folders-cg" --theme Papirus-Dark --color orange

  for name in Papirus Papirus-Dark Papirus-Light; do
    replace "$work/icons/$name" "$data_home/icons/$name"
  done

  replace "$work/papirus-folders-cg" "$HOME/.local/bin/papirus-folders-cg"
}

setup_mime() {
  local directory mime names name browser='' target existing backup found
  local -a desktop_ids

  if "$dry_run"; then
    printf 'merge defaults from config/xdg/mimeapps.list and preserve unmanaged associations\n'
    return
  fi

  while IFS='=' read -r mime names; do
    [[ $mime != '[Default Applications]' && -n $mime ]] || continue
    IFS=';' read -ra desktop_ids <<<"$names"
    for name in "${desktop_ids[@]}"; do
      found=false
      for directory in "$data_home/applications" /usr/local/share/applications /usr/share/applications; do
        [[ ! -f $directory/$name ]] || found=true
      done
      "$found" || fail "Missing desktop entry: $name"
    done
    [[ $mime != x-scheme-handler/https ]] || browser=${desktop_ids[0]}
  done <"$repo/config/xdg/mimeapps.list"
  [[ -n $browser ]] || fail 'MIME policy must select an HTTPS browser.'

  target=$config_home/mimeapps.list
  existing=/dev/null
  [[ -f $target ]] && existing=$target

  awk '
    function remaining( key) {
      for (key in defaults)
        if (!written[key]++) print key "=" defaults[key]
    }
    FILENAME == ARGV[1] {
      if ($0 ~ /^[#;\[]/ || !index($0, "=")) next
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
  ' "$repo/config/xdg/mimeapps.list" "$existing" >"$work/mimeapps.list.merged"
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
  export PATH="$target_home/.local/bin:$PATH"
  export NPM_CONFIG_PREFIX="$target_home/.local"

  if ! "$dry_run"; then
    install -d -m 700 "$work/runtime"
    export XDG_RUNTIME_DIR="$work/runtime"
  fi

  link_dotfiles
  install_user_tools
  install_doom
  install_appearance

  run dbus-run-session -- bash -e -c "
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
    gsettings set org.gnome.desktop.interface cursor-theme Adwaita
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'Iosevka Nerd Font 11'
    gsettings set org.gnome.desktop.interface clock-format 24h
    gsettings set org.gnome.desktop.wm.preferences button-layout ''
    gsettings set org.gnome.desktop.wm.preferences audible-bell false
    gsettings set org.gnome.desktop.sound event-sounds false
    gsettings set org.gnome.desktop.sound input-feedback-sounds false
  "

  run xdg-user-dirs-update
  setup_mime

  run fc-cache
  if "$dry_run"; then
    printf 'rebuild bat cache if its themes or bat version changed\n'
  else
    local theme_hash cache_directory
    cache_directory=$(bat --cache-dir)
    theme_hash=$({
      find -L "$config_home/bat" -type f -print0 | sort -z | xargs -0 sha256sum
      bat --version
    } | sha256sum)
    if [[ ! -f $cache_directory/dotfiles-themes || ! -f $cache_directory/themes.bin ]] \
      || [[ $(<"$cache_directory/dotfiles-themes") != "$theme_hash" ]]; then
      run bat cache --build
      printf '%s\n' "$theme_hash" >"$cache_directory/dotfiles-themes"
    fi
  fi

  install_crontab
}

main() {
  (($# <= 1)) || fail 'Usage: ./install.sh [--dry-run]'
  [[ ${1:-} == --dry-run ]] && dry_run=true

  if [[ ${DOTFILES_USER_SETUP:-} != 1 ]] && ((EUID != 0)) && ! "$dry_run"; then
    if command -v doas >/dev/null 2>&1; then
      exec doas -- "$repo/install.sh"
    elif command -v sudo >/dev/null 2>&1; then
      exec sudo -- "$repo/install.sh"
    else
      fail 'Not running as root and neither doas nor sudo is installed.'
    fi
  fi

  select_user

  if [[ ${DOTFILES_USER_SETUP:-} != 1 ]]; then
    preflight
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

  if [[ ${DOTFILES_USER_SETUP:-} == 1 ]]; then
    setup_user
    return
  fi

  run as_user git -C "$repo" submodule update --init --recursive

  if ! "$dry_run"; then
    [[ -r $repo/config/doom/init.el ]] || fail 'The Doom configuration submodule is incomplete.'
    chmod 711 "$work"
  fi

  install_system_config
  install_packages
  install_st
  install_system_file "$repo/config/oxwm/oxwm.desktop" /usr/share/xsessions/oxwm.desktop
  run oxwm --validate "$repo/config/oxwm/config.lua"
  configure_account
  configure_mdns
  configure_inittab

  if "$dry_run"; then
    setup_user
  else
    run as_user env DOTFILES_USER_SETUP=1 "$repo/install.sh"
  fi

  enable_services

  if "$dry_run"; then
    echo 'Dry run complete; no changes made.'
  else
    echo 'Installation complete.'
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
