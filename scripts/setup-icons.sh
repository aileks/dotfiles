#!/usr/bin/env bash

set -euo pipefail

[[ $UID != 0 ]] || {
  echo 'Run as aileks' >&2
  exit 1
}

data_home=${XDG_DATA_HOME:-$HOME/.local/share}
mkdir -p "$data_home/icons"
for theme in Papirus Papirus-Dark Papirus-Light; do
  target=$data_home/icons/$theme
  [[ -d /usr/share/icons/$theme ]] || {
    echo "Install Papirus first: $theme" >&2
    exit 1
  }
  if [[ ! -e $target ]]; then
    cp -a "/usr/share/icons/$theme" "$target"
    chmod -R u+w "$target"
  fi
  [[ ! -L $target && -O $target ]] || {
    echo "Refusing non-owned icon tree: $target" >&2
    exit 1
  }
done

# Limit the upstream tool's theme search to the user-owned copies.
XDG_DATA_DIRS="$data_home" bash "$data_home/dotfiles/papirus-folders/papirus-folders-cg" --once --theme Papirus-Dark --color grove
for theme in Papirus Papirus-Dark Papirus-Light; do
  gtk-update-icon-cache -f "$data_home/icons/$theme"
done
