#!/usr/bin/env bash

set -euo pipefail

[[ $(id -un) == aileks ]] || {
  echo 'Run as aileks.' >&2
  exit 1
}

repo=$(cd -- "$(dirname -- "$(readlink -f "$0")")/.." && pwd)
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
mkdir -p "$data_home/dotfiles" "$HOME/.local/bin"

checkout() {
  local url=$1 revision=$2 destination=$3

  if [[ ! -e $destination && ! -L $destination ]]; then
    git clone --no-checkout "$url" "$destination"
    git -C "$destination" checkout --detach "$revision"
  fi

  [[ ! -L $destination && -O $destination ]] || exit 1
  [[ $(git -C "$destination" rev-parse HEAD) == "$revision" ]] || {
    echo "Review the existing checkout before updating: $destination" >&2
    exit 1
  }
}

checkout https://github.com/mattmc3/antidote.git \
  db19ea3aa9ad83dbe6ac465ecce0a0afc5a752a5 "$HOME/.antidote"

checkout https://github.com/aileks/cinder-grove-gtk.git \
  a1a74295d6dcc235623a72fc024bdeff3134c5a9 "$data_home/dotfiles/cinder-grove-gtk"

checkout https://github.com/aileks/papirus-folders.git \
  e76cc8b2a7e3139c500622dac2c9653042cfccb5 "$data_home/dotfiles/papirus-folders"

checkout https://github.com/marty-oehme/bemoji.git \
  791c7748cf0236f691b1874e79ebe434469c20a9 "$data_home/dotfiles/bemoji"

mkdir -p "$data_home/themes"
theme=$data_home/themes/Cinder-Grove-Dark
theme_source=$data_home/dotfiles/cinder-grove-gtk/Cinder-Grove-Dark

if [[ -e $theme || -L $theme ]]; then
  [[ -L $theme && $(readlink "$theme") == "$theme_source" ]] || {
    echo "Review the existing theme before linking: $theme" >&2
    exit 1
  }
else
  ln -s "$theme_source" "$theme"
fi

install -m 755 "$data_home/dotfiles/bemoji/bemoji" "$HOME/.local/bin/bemoji"
mkdir -p "$data_home/bemoji"

if [[ ! -s $data_home/bemoji/emojis.txt ]]; then
  emoji_source=$(mktemp)
  trap 'rm -f -- "$emoji_source"' EXIT
  curl --fail --location https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt >"$emoji_source"
  sed -n 's/^.*; fully-qualified.*# \([^[:space:]]*\) [^[:space:]]* \(.*$\)/\1 \2/p' \
    "$emoji_source" >"$data_home/bemoji/emojis.txt"
  [[ -s $data_home/bemoji/emojis.txt ]]
fi

bash "$repo/bin/link-dotfiles"
bash "$repo/scripts/setup-icons.sh"

export PATH="$HOME/.local/bin:$PATH"
xdg-user-dirs-update
dbus-run-session -- bash "$repo/bin/setup-gtk"
bash "$repo/bin/setup-mime"
fc-cache -f

existing=$(mktemp)
merged=$(mktemp)
trap 'rm -f -- "$existing" "$merged" "${emoji_source:-}"' EXIT

if ! crontab -l >"$existing"; then
  [[ ! -s $existing ]] || exit 1
fi

# Replace only our marked block, preserving unrelated jobs.
sed '/^# BEGIN dotfiles$/,/^# END dotfiles$/d' "$existing" >"$merged"
{
  echo '# BEGIN dotfiles'
  sed "s|/run/user/1000|/run/user/$(id -u)|g" "$repo/config/cron/crontab"
  echo '# END dotfiles'
} >>"$merged"

crontab "$merged"
