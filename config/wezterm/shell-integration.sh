export WEZTERM_HOSTNAME="$(hostname)"

if [[ -r ${XDG_DATA_HOME:-$HOME/.local/share}/nixdots/wezterm-shell-integration.sh ]]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/nixdots/wezterm-shell-integration.sh"
fi
