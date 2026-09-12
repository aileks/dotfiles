#!/usr/bin/env bash
set -u

dbus-update-activation-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE

pgrep -x pipewire >/dev/null || gentoo-pipewire-launcher &
pgrep -x gnome-keyring-d >/dev/null || gnome-keyring-daemon --start --components=secrets,pkcs11 &
pgrep -f polkit-gnome-authentication >/dev/null || /usr/libexec/polkit-gnome-authentication-agent-1 &
pgrep -x xwallpaper >/dev/null || xwallpaper --zoom ~/.local/share/backgrounds/fantasy-woods.jpg &
pgrep -x picom >/dev/null || picom --config ~/.config/picom/picom.conf &
pgrep -x dunst >/dev/null || dunst &
pgrep -x playerctld >/dev/null || playerctld daemon &
pgrep -x udiskie >/dev/null || udiskie --tray &
pgrep -x blueman-applet >/dev/null || blueman-applet &
pgrep -x clipmenud >/dev/null || clipmenud &
pgrep -x wezterm-mux-server >/dev/null || wezterm-mux-server --config-file ~/.config/wezterm/wezterm.lua &
pgrep -x emacs >/dev/null || emacs --daemon &
pgrep -x xss-lock >/dev/null || xss-lock --transfer-sleep-lock -- lock-session &
pgrep -x xautolock >/dev/null || {
  xautolock -time 10 -locker lock-session -notify 30 -notifier 'notify-send -t 2000 -a xautolock "Locking in 30 seconds"' &
  xautolock -time 30 -locker 'sh -c "lock-session; loginctl suspend"' &
}
xset dpms 0 0 900
pgrep -x dwmblocks >/dev/null || dwmblocks &
pgrep -x bitwarden >/dev/null || /opt/Bitwarden/bitwarden &
pgrep -x localsend >/dev/null || localsend &

mkdir -p "$XDG_RUNTIME_DIR/podman"
pgrep -f 'podman system service' >/dev/null || podman system service --time=0 "unix://$XDG_RUNTIME_DIR/podman/podman.sock" &

flock -n "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/reminder-loop.lock" \
  sh -c 'while pgrep -x dwm >/dev/null; do reminder dispatch || true; sleep 60; done' &
