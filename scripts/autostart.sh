#!/bin/sh

xrdb -merge ~/.Xresources &

xset r rate 250 45 &

feh --bg-fill ~/Pictures/wallpaper.jpg &

picom -b &

dunst &

blueman-applet &

dwmblocks &
