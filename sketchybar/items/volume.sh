#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change
