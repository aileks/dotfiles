#!/usr/bin/env bash

if playerctl --player=spotify status &>/dev/null; then
    artist=$(playerctl --player=spotify metadata artist)
    title=$(playerctl --player=spotify metadata title)

    if [ -n "$artist" ] && [ -n "$title" ]; then
        echo "$artist - $title"
    else
        echo "No song information"
    fi
else
    echo "Idle "
fi
