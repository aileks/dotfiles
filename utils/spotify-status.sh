#!/usr/bin/env bash

if playerctl --player=spotify status &>/dev/null; then
    # Set artist & title via exposed spotify data
    artist=$(playerctl --player=spotify metadata artist)
    title=$(playerctl --player=spotify metadata title)

    if [ -n "$artist" ] && [ -n "$title" ]; then
    	# Format what's currently playing
        echo " %{F#9ccfd8} %{F-} ${artist} - ${title} "
    else
    	# Failsafe
        echo "%{F#eb6f92}No song information%{F-}"
    fi
else
    # Default state
    echo " %{F#eb6f92}%{F-} %{F#908caa}Idle%{F-} "
fi
