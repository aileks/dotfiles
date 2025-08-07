#!/usr/bin/env bash

SERVICES=(
    "bluetooth"
    "fstrim.timer"
    "NetworkManager"
    "docker"
    "cups"
    "cups-browsed"
    "ufw"
)

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        if ! systemctl is-enabled --quiet "$service"; then
            sudo systemctl enable --now "$service"
        else
            echo "$service is already enabled."
        fi
    else
        echo "Service $service not found, skipping..."
    fi
done
