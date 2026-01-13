#!/bin/sh

xrdb -merge ~/.Xresources &

xset r rate 250 50 &

feh --bg-fill ~/Pictures/wallpaper.jpg &

picom -b &

dunst &

/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

blueman-applet &

dwmblocks &
