#!/usr/bin/env bash

set -euo pipefail

[[ $EUID == 0 && -d /etc/runlevels ]] || exit 1

services=(dbus elogind NetworkManager cronie bluetooth cupsd avahi-daemon ivpn ly)

for service in "${services[@]}"; do
  [[ -x /etc/init.d/$service ]] || {
    echo "Missing OpenRC service: $service" >&2
    exit 1
  }
done

# Ly owns tty2. Leave the other gettys available for recovery.
if grep -q '^c2:' /etc/inittab; then
  cp -an /etc/inittab /etc/inittab.before-ly
  sed -i '/^c2:/s/^/#/' /etc/inittab
fi

for service in "${services[@]}"; do
  rc-update add "$service" default
done
