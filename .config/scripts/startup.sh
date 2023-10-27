#!/bin/bash

# Important
/usr/bin/xss-lock --transfer-sleep-lock -- ~/.config/scripts/lock.sh --nofork &
/usr/bin/dunst >/dev/null 2>&1 &
/usr/bin/picom --config ~/.config/picom/picom.conf -b &
/usr/bin/xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rate 144.00 --output HDMI-1-0 --primary --mode 1920x1080 --pos 1920x0 --rate 75.00

# Personal
nm-applet &
feh --no-fehbg --bg-scale ~/.bg.png --bg-scale ~/.bg.png
flameshot &
setxkbmap -option numpad:mac
