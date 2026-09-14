#!/usr/bin/env bash
set -u
exec </dev/null

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
runtime_directory=${XDG_RUNTIME_DIR:?}
children=()

start() {
  setsid -- "$@" </dev/null &
  children+=("$!")
}
cleanup() {
  trap - EXIT TERM INT HUP
  if screenrecord status >/dev/null 2>&1; then
    timeout 7 screenrecord stop >/dev/null 2>&1 || true
  fi
  if ((${#children[@]})); then
    for child in "${children[@]}"; do
      kill -TERM -- "-$child" 2>/dev/null || true
    done
    sleep 2
    for child in "${children[@]}"; do
      kill -KILL -- "-$child" 2>/dev/null || true
    done
    wait 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 0' TERM INT HUP

activation_variables=(WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE)
[[ -z ${DISPLAY:-} ]] || activation_variables+=(DISPLAY)
dbus-update-activation-environment "${activation_variables[@]}"

pgrep -u "$UID" -x pipewire >/dev/null || start gentoo-pipewire-launcher
pgrep -u "$UID" -x gnome-keyring-d >/dev/null || start gnome-keyring-daemon --foreground --components=secrets,pkcs11
start /usr/libexec/polkit-gnome-authentication-agent-1
start swaybg -i "$data_home/backgrounds/fantasy-woods.jpg" -m fill
start dunst
start playerctld daemon
start udiskie --tray
start blueman-applet
start wl-paste --watch cliphist store
pgrep -u "$UID" -x wezterm-mux-ser >/dev/null || start wezterm-mux-server --config-file "$config_home/wezterm/wezterm.lua"
pgrep -u "$UID" -x emacs >/dev/null || start emacs --fg-daemon
start kanshi
start swayidle -w -C "$config_home/swayidle/config"
pgrep -u "$UID" -x bitwarden-app >/dev/null || start /opt/Bitwarden/bitwarden
pgrep -u "$UID" -x localsend >/dev/null || start localsend
pgrep -u "$UID" -x openrgb >/dev/null || start openrgb --noautoconnect -p NRGB
mkdir -p "$runtime_directory/podman"
pgrep -u "$UID" -f 'podman system service' >/dev/null || start podman system service --time=0 "unix://$runtime_directory/podman/podman.sock"
start flock -n "$runtime_directory/reminder-loop.lock" sh -c 'while :; do reminder dispatch || true; sleep 60; done'
: >"${DWL_SESSION_DIR:?}/ready"
wait
