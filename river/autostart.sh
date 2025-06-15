#!/usr/bin/env bash

# set bg
killall -q swaybg
while pgrep -x swaybg >/dev/null; do sleep 1; done
exec swaybg -m fill -i ~/.config/river/backgrounds/background.jpg

# autostart apps
killall -q waybar
killall -q dunst
killall -q nm-applet
killall -q rescrobbled
waybar &
dunst &
nm-applet &
rescrobbled &
