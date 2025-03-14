#!/usr/bin/env bash

if playerctl --player=spotify status &>/dev/null; then
    artist=$(playerctl --player=spotify metadata artist)
    title=$(playerctl --player=spotify metadata title)

    if [ -n "$artist" ] && [ -n "$title" ]; then
        echo " %{F#9ccfd8} %{F-} ${artist} - ${title} "
    else
        echo "%{F#eb6f92}No song information%{F-}"
    fi
else
    echo " %{F#eb6f92}%{F-} %{F#908caa}Idle%{F-} "
fi
