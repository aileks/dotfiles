source "${BASH_SOURCE[0]%/*}/lib.sh"

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

rebuild_caches() {
  run fc-cache
  if "$dry_run"; then
    printf 'rebuild bat cache if its themes or bat version changed\n'
    return
  fi

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

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  common_setup "$@"
  init_user_env
  install_doom
  install_appearance
  apply_gsettings
  run xdg-user-dirs-update
  setup_mime
  rebuild_caches
  install_crontab
fi
