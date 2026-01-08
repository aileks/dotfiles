#!/bin/sh

xrdb -merge ~/.Xresources &

xset r rate 300 50 &

feh --bg-fill ~/wallpaper.jpg &

picom -b &

dunst &

dwmblocks &
