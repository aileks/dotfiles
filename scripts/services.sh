#!/usr/bin/env bash

SERVICES=(
    "bluetooth"
    "fstrim.timer"
    "NetworkManager"
    "docker"
)

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        if ! systemctl is-enabled --quiet "$service"; then
            info "Enabling and starting $service..."
            sudo systemctl enable --now "$service"
        else
            info "$service is already enabled."
        fi
    else
        echo "WARN: Service $service not found, skipping."
    fi
done
