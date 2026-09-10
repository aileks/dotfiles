#!/usr/bin/env bash

set -u

umask 077
destination=${1:-$HOME/migration-gentoo/$(date -u +%Y%m%dT%H%M%SZ)}
[[ ! -e $destination ]] || {
  echo 'Choose a new evidence directory' >&2
  exit 1
}

mkdir -p "$destination"

capture() {
  local name=$1
  shift
  "$@" >"$destination/$name.txt" 2>&1 || printf 'Unavailable: %s\n' "$name" >&2
}

capture lsblk lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,PARTUUID,MOUNTPOINTS
capture findmnt findmnt -R /
capture proc-cmdline cat /proc/cmdline
capture lspci lspci -nnk
capture lsusb lsusb
capture ip-link ip -br link
capture ip-addr ip -br addr
capture nm-connections nmcli connection show
capture wpctl-status wpctl status
capture bluetooth bluetoothctl show
capture nvidia-smi nvidia-smi
capture nvidia-smi-q nvidia-smi -q
capture vulkan-summary vulkaninfo --summary
capture vainfo vainfo
capture ddcutil ddcutil detect
capture mango-state mmsg -g
capture lsmod lsmod
capture modinfo-nvidia modinfo nvidia
capture nvidia-params cat /proc/driver/nvidia/params
capture dconf dconf dump /
capture default-browser xdg-settings get default-web-browser
capture http-handler xdg-mime query default x-scheme-handler/http
capture https-handler xdg-mime query default x-scheme-handler/https
capture html-handler xdg-mime query default text/html
capture crontab crontab -l
echo "Private evidence saved to $destination"
echo 'Also record sudo blkid, sudo efibootmgr -v and sudo crontab -l there.'
echo 'Copy evidence to the verified external backup, never the public repository.'
