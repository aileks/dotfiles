#!/usr/bin/env bash

sudo pacman -S --noconfirm cups cups-pdf cups-filters cups-browsed system-config-printer avahi nss-mdns
sudo systemctl enable --now cups.service

sudo mkdir -p /etc/systemd/resolved.conf.d
echo -e "[Resolve]\nMulticastDNS=no" | sudo tee /etc/systemd/resolved.conf.d/10-disable-multicast.conf
sudo systemctl enable --now avahi-daemon.service

if ! grep -q '^CreateRemotePrinters Yes' /etc/cups/cups-browsed.conf; then
  echo 'CreateRemotePrinters Yes' | sudo tee -a /etc/cups/cups-browsed.conf
fi

sudo systemctl enable --now cups-browsed.service
