source "${BASH_SOURCE[0]%/*}/lib.sh"

install_doom() {
  local emacs_dir=${XDG_CONFIG_HOME:-$HOME/.config}/emacs

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
    mkdir -p -- "$(dirname "$target")"
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

apply_gsettings() {
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
}

setup_mime() {
  local target=$config_home/mimeapps.list

  if [[ -f $target ]] && cmp -s -- "$repo/config/xdg/mimeapps.list" "$target"; then
    return
  fi

  if [[ -e $target || -L $target ]]; then
    mv -T -- "$target" "$target.backup.$stamp"
  fi
  install -m 600 -- "$repo/config/xdg/mimeapps.list" "$target"
}

rebuild_caches() {
  run fc-cache
  run bat cache --build
}

install_crontab() {
  local state_directory=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
  local current

  current=$(crontab -l 2>/dev/null) || true
  [[ $current != "$(<"$repo/config/cron/crontab")" ]] || return

  if [[ -n $current ]]; then
    mkdir -p "$state_directory"
    printf '%s\n' "$current" >"$state_directory/crontab-$stamp"
  fi
  crontab "$repo/config/cron/crontab"
}

setup_user_phase() {
  init_user_env

  install_stow
  install_user_tools
  install_doom
  install_appearance
  apply_gsettings

  run xdg-user-dirs-update
  setup_mime
  rebuild_caches
  install_crontab
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  common_setup "$@"
  setup_user_phase
fi
