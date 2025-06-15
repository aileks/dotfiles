#!/usr/bin/env bash

# general
riverctl map normal Super Q close
riverctl map normal Super Return spawn alacritty
riverctl map normal Super W spawn brave
riverctl map normal Super space spawn 'rofi -show drun'
riverctl map normal Super E spawn thunar
riverctl map normal Super+Shift X spawn wlogout
riverctl map normal Super U spawn 'rofi -show emoji'
riverctl map normal Super Escape spawn swaylock
riverctl map normal Super F toggle-fullscreen

# screenshots and recording
riverctl map normal Print spawn 'grim -g "$(slurp)" - | wl-copy'
riverctl map normal Super Print spawn 'grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png'
riverctl map normal Super+Shift R spawn 'bash -c '\''wf-recorder -g "$(slurp)" -f ~/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4 &> /dev/null & echo $! > /tmp/wf-recorder.pid'\'''
riverctl map normal Super+Shift Escape spawn 'bash -c "kill -SIGINT $(cat /tmp/wf-recorder.pid 2>/dev/null) || pkill wf-recorder; rm -f /tmp/wf-recorder.pid"'

# tag management
for i in $(seq 1 9); do
	tags=$((1 << ($i - 1)))
	riverctl map normal Super $i set-focused-tags $tags
	riverctl map normal Super+Shift $i set-view-tags $tags
	riverctl map normal Super+Control $i toggle-focused-tags $tags
	riverctl map normal Super+Shift+Control $i toggle-view-tags $tags
done

# window management
riverctl map-pointer normal Super BTN_LEFT move-view
riverctl map-pointer normal Super BTN_RIGHT resize-view
riverctl map normal Super J focus-view next
riverctl map normal Super K focus-view previous
riverctl map normal Super+Control H send-layout-cmd rivertile "main-ratio -0.05"
riverctl map normal Super+Control L send-layout-cmd rivertile "main-ratio +0.05"
riverctl map normal Super+Shift J swap next
riverctl map normal Super+Shift K swap previous
riverctl map normal Super+Shift Space toggle-float

# media
for mode in normal locked; do
	riverctl map $mode None XF86AudioRaiseVolume spawn 'pamixer -i 5'
	riverctl map $mode None XF86AudioLowerVolume spawn 'pamixer -d 5'
	riverctl map $mode None XF86AudioMute spawn 'pamixer --toggle-mute'
	riverctl map $mode None XF86AudioMedia spawn 'playerctl play-pause'
	riverctl map $mode None XF86AudioPlay spawn 'playerctl play-pause'
	riverctl map $mode None XF86AudioPrev spawn 'playerctl previous'
	riverctl map $mode None XF86AudioNext spawn 'playerctl next'
done
