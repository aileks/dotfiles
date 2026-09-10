export WEZTERM_HOSTNAME="$(hostname)"

if [[ -r /etc/profile.d/wezterm.sh ]]; then
  source /etc/profile.d/wezterm.sh
fi
