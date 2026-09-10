#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=config/session/processes.sh
source "${XDG_CONFIG_HOME:-$HOME/.config}/session/processes.sh"
session_is_live || exit 1

variables=(WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE XDG_DATA_DIRS)
[[ -v DISPLAY ]] && variables+=(DISPLAY)
dbus-update-activation-environment "${variables[@]}"

temporary=$(mktemp "$RUNTIME_DIR/session.env.XXXXXX")
trap 'rm -f "$temporary"' EXIT

for variable in DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE; do
  [[ -v $variable ]] && printf 'export %s=%q\n' "$variable" "${!variable}" >>"$temporary"
done

mv -f "$temporary" "$RUNTIME_DIR/session.env"

start_session_process pipewire gentoo-pipewire-launcher
# D-Bus activates the secrets service; do not take over the SSH agent.
start_session_process keyring gnome-keyring-daemon --foreground --components=secrets,pkcs11
start_session_process polkit /usr/libexec/polkit-gnome-authentication-agent-1
start_session_process wallpaper swaybg -i "${XDG_DATA_HOME:-$HOME/.local/share}/backgrounds/fantasy-woods.jpg" -m fill
start_session_process dunst dunst
start_session_process playerctld playerctld daemon
start_session_process network nm-applet --indicator
start_session_process udiskie udiskie --tray

if [[ ! -f $RUNTIME_DIR/private-clipboard/restore-history ]] && ! record_is_live "$RUNTIME_DIR/private-clipboard.pid"; then
  start_session_process cliphist wl-paste --type text --watch cliphist -max-items 50 -max-dedupe-search 50 store
fi

mkdir -p "$XDG_RUNTIME_DIR/podman"
start_session_process podman podman system service --time=0 "unix://$XDG_RUNTIME_DIR/podman/podman.sock"
start_session_process wezterm wezterm-mux-server --config-file "${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/wezterm.lua"
start_session_process idle session-idle

for _ in {1..50}; do
  if mmsg -g >/dev/null 2>&1 && wpctl status >/dev/null 2>&1; then
    start_session_process waybar waybar
    exit 0
  fi
  sleep 0.2
done

echo 'Mango IPC or audio unavailable; Waybar startup withheld' >&2
exit 1
