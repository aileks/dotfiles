#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --add event brew_update

sketchybar --add item brew right \
           --set brew update_freq=14400 \
           script="$PLUGIN_DIR/brew.sh" \
           background.color=$BG1 \
           --subscribe brew brew_update
