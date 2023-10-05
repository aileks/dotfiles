#!/bin/bash

# Important
/usr/bin/lxpolkit &
/usr/bin/xss-lock --transfer-sleep-lock -- ~/.config/scripts/lock.sh --nofork &
/usr/bin/dunst >/dev/null 2>&1 &
/usr/bin/picom --config ~/.config/picom/picom.conf -b &

# Personal
feh --no-fehbg --bg-scale ~/.bg.png &
flameshot &
setxkbmap -option numpad:mac &
nm-applet &
exec ~/.config/scripts/keyboard.sh &
emacs --daemon &
