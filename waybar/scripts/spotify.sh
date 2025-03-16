#!/bin/sh

playerctl -p spotify -F metadata --format \
'{{emoji(status)}} {{artist}} - {{title}}' 2>/dev/null | while read -r line; do
    echo "{\"text\":\"$line\",\"class\":\"$([ $(playerctl status) = Playing ] && echo playing || echo paused)\"}"
done
