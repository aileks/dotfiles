#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item chevron left \
           --set chevron icon= \
           icon.font="AdwaitaMono Nerd Font Propo:Bold:14" \
           icon.color=$ORANGE \
           label.drawing=off \
           background.drawing=off
