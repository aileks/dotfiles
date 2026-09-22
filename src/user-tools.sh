install_user_tools() {
  local work=$work/user-tools
  local package name

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

  if [[ ! -r $data_home/java/google-java-format.jar ]]; then
    mkdir -p "$data_home/java"
    curl -fL https://github.com/google/google-java-format/releases/download/v1.36.1/google-java-format-1.36.1-all-deps.jar \
      -o "$work/google-java-format.jar"
    install -b -m 644 "$work/google-java-format.jar" "$data_home/java/google-java-format.jar"
  fi

  if [[ ! -x $HOME/.local/bin/sqlfluff ]]; then
    uv tool install --reinstall sqlfluff
  fi

  if [[ ! -x $HOME/.local/bin/ruff ]]; then
    uv tool install --reinstall ruff
  fi

  for package in pnpm@12 prettier; do
    if [[ ! -d $NPM_CONFIG_PREFIX/lib/node_modules/${package%@*} ]]; then
      npm install -g "$package"
    fi
  done
}
