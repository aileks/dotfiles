#!/usr/bin/env bash

pkill swayidle
sleep 1s

exec swayidle -w \
	timeout 900 "swaylock -f -i $HOME/Pictures/Wallpapers/diamond.jpg" \
	timeout 1800 "wlr-randr --output DP-2 --off" \
	before-sleep "swaylock -f -i $HOME/Pictures/Wallpapers/diamond.jpg" \
	resume 'wlr-randr --output DP-2 --on' &

disown
