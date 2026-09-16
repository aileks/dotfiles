#!/usr/bin/env bash

set -u
exec </dev/null

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
runtime_directory=${XDG_RUNTIME_DIR:?}
children=()
umask 077
mkdir -p "${CLIPHIST_DB_PATH%/*}"
compositor_pid=$PPID
[[ ${MANGO_INSTANCE_SIGNATURE:-} == "$runtime_directory/mango-$compositor_pid.sock" ]] || exit 1

start() {
  setsid -- "$@" </dev/null &
  children+=("$!")
}

cleanup() {
  trap - EXIT TERM INT HUP
  timeout 10 screenrecord stop >/dev/null 2>&1 || true
  for child in "${children[@]}"; do
    kill -TERM -- "-$child" 2>/dev/null || true
  done
  sleep 2
  for child in "${children[@]}"; do
    kill -KILL -- "-$child" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' TERM INT HUP

activation_variables=(WAYLAND_DISPLAY MANGO_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
  XDG_SESSION_DESKTOP XDG_SESSION_TYPE SSH_AUTH_SOCK PATH)
[[ -z ${DISPLAY:-} ]] || activation_variables+=(DISPLAY)
dbus-update-activation-environment "${activation_variables[@]}"

start /usr/libexec/polkit-gnome-authentication-agent-1
start swaybg -i "$data_home/backgrounds/fantasy-woods.jpg" -m fill
start dunst
start swayosd-server
start waybar
start playerctld daemon
start udiskie --tray
start blueman-applet
start wl-paste --watch cliphist store
start swayidle -w -C "$config_home/swayidle/config"

mkdir -p "$runtime_directory/podman"
pgrep -u "$UID" -f 'podman system service' >/dev/null || start podman system service --time=0 "unix://$runtime_directory/podman/podman.sock"
pgrep -u "$UID" -x pipewire >/dev/null || start gentoo-pipewire-launcher
pgrep -u "$UID" -x gnome-keyring-d >/dev/null || start gnome-keyring-daemon --foreground --components=secrets,pkcs11
pgrep -u "$UID" -x wezterm-mux-ser >/dev/null || start wezterm-mux-server --config-file "$config_home/wezterm/wezterm.lua"
pgrep -u "$UID" -x emacs >/dev/null || start emacs --daemon
pgrep -u "$UID" -x bitwarden-app >/dev/null || start /opt/Bitwarden/bitwarden
pgrep -u "$UID" -x localsend >/dev/null || start localsend
pgrep -u "$UID" -x openrgb >/dev/null || start openrgb --noautoconnect -p NRGB

pidwait -p "$compositor_pid" &
wait "$!"
