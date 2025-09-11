#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --add event aerospace_workspace_change
sketchybar --add event window_destroyed
sketchybar --add event window_created
sketchybar --add event front_app_switched
sketchybar --add event space_windows_change
sketchybar --add event window_focus
sketchybar --add event window_title_changed
sketchybar --add event forced

for sid in $(aerospace list-workspaces --all); do
  sketchybar --add item space.$sid left \
             --set space.$sid \
             background.height=24 \
             label.font="sketchybar-app-font:Regular:14" \
             icon.font="AdwaitaMono Nerd Font Propo:Bold:14" \
             icon="$sid" \
             icon.padding_left=8 \
             icon.padding_right=4 \
             label.padding_left=4 \
             label.padding_right=8 \
             drawing=off \
             click_script="aerospace workspace $sid"
done

sketchybar --add item aerospace_controller left \
           --set aerospace_controller drawing=off \
           script="$PLUGIN_DIR/aerospace.sh" \
           --subscribe aerospace_controller aerospace_workspace_change front_app_switched space_windows_change window_destroyed window_created window_focus window_title_changed forced

sketchybar --trigger aerospace_controller forced
