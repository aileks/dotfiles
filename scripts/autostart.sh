#!/bin/sh

export XCURSOR_SIZE=48 &
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS &
systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

xrdb -merge ~/.Xresources &
xset r rate 250 50 &

picom -b &
dunst &
feh --bg-fill ~/Pictures/wallpaper.jpg &

dwmblocks &
blueman-applet &

sleep 5 && nm-applet &
