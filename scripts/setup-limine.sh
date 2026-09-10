#!/usr/bin/env bash

set -euo pipefail

[[ $EUID == 0 && -d /sys/firmware/efi/efivars ]] || exit 1
[[ $(findmnt -n -o FSTYPE --mountpoint /boot) == vfat ]] || exit 1
[[ -s /boot/EFI/limine/limine.conf ]] || exit 1

loader=/usr/share/limine/BOOTX64.EFI
[[ -s $loader ]] || {
  echo "Missing packaged UEFI loader: $loader" >&2
  exit 1
}

esp=$(findmnt -n -o SOURCE --mountpoint /boot)
disk=/dev/$(lsblk -n -o PKNAME "$esp")
partition=$(cat "/sys/class/block/${esp##*/}/partition")
partuuid=$(blkid -s PARTUUID -o value "$esp")

[[ -b $disk && $partition =~ ^[0-9]+$ && -n $partuuid ]] || exit 1

install -m 644 "$loader" /boot/EFI/limine/BOOTX64.EFI

has_entry() {
  efibootmgr -v | grep -iF "$partuuid" | grep -iF '\EFI\limine\BOOTX64.EFI' | grep -q '^Boot[0-9A-Fa-f]\{4\}\*'
}

if ! has_entry; then
  efibootmgr --create --disk "$disk" --part "$partition" \
    --label 'Gentoo Limine' --loader '\EFI\limine\BOOTX64.EFI'
fi

has_entry || {
  echo 'The active Limine EFI entry could not be verified.' >&2
  exit 1
}
