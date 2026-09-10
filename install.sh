#!/usr/bin/env bash

set -euo pipefail

repo=$(cd -- "$(dirname -- "$(readlink -f "$0")")" && pwd)
target=/mnt/gentoo
check_only=false
hostname=hexghost
timezone=America/New_York

while (($#)); do
  case $1 in
    --root)
      target=${2:?}
      shift 2
      ;;
    --hostname)
      hostname=${2:?}
      shift 2
      ;;
    --timezone)
      timezone=${2:?}
      shift 2
      ;;
    --check-only)
      check_only=true
      shift
      ;;
    --help | -h)
      echo 'Usage: sudo ./install.sh [--root /mnt/gentoo] [--hostname hexghost] [--timezone America/New_York] [--check-only]'
      echo 'After verified OpenRC Stage 3 and genfstab; requires a VFAT ESP mounted at /boot.'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

target=$(realpath -e -- "$target")
[[ ! -L $target/etc && ! -L $target/var && ! -L $target/var/lib ]] || exit 1

[[ $target != / && -f $target/etc/gentoo-release && -s $target/etc/fstab ]] || {
  echo 'Use a mounted Gentoo target with Stage 3 and fstab, never the running root.' >&2
  exit 1
}

[[ $hostname =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ && $timezone != /* && $timezone != *..* ]] || exit 2

[[ $(findmnt -n -o FSTYPE --mountpoint "$target/boot") == vfat ]] || {
  echo 'Mount the VFAT ESP at target/boot first.' >&2
  exit 1
}

mountpoint -q "$target"

root_type=$(findmnt -n -o FSTYPE --mountpoint "$target")
[[ $root_type == ext4 || $root_type == xfs ]] || {
  echo 'Supported root filesystems: ext4 or XFS on an unencrypted partition.' >&2
  exit 1
}

for mount in / /boot; do
  source=$(findmnt -n -o SOURCE --mountpoint "${target%/}${mount%/}")
  declared=$(findmnt --tab-file "$target/etc/fstab" --evaluate -n -o SOURCE --mountpoint "$mount")

  [[ -b $source && -b $declared && $(lsblk -dn -o TYPE "$source") == part ]] || {
    echo "Expected a plain partition for $mount in fstab and the mounted target." >&2
    exit 1
  }

  [[ $(blkid -s UUID -o value "$source") == "$(blkid -s UUID -o value "$declared")" ]] || {
    echo "fstab does not match the mounted $mount partition." >&2
    exit 1
  }
done

profile=$(readlink "$target/etc/portage/make.profile")
[[ $profile != *systemd* && -d $target/etc/init.d ]] || {
  echo 'Use an OpenRC Stage 3.' >&2
  exit 1
}

[[ -d /sys/firmware/efi/efivars ]] || {
  echo 'Boot the install media in UEFI mode.' >&2
  exit 1
}

if "$check_only"; then
  bash "$repo/scripts/install-system-config.sh" --root "$target" --dry-run
  echo "Plan: prepare chroot, install packages, configure $hostname ($timezone), aileks, Limine and OpenRC."
  exit 0
fi

[[ $EUID == 0 ]] || {
  echo 'Run as root.' >&2
  exit 1
}

[[ -f $repo/config/nvim/init.lua ]] || {
  echo 'Run git submodule update --init --recursive first.' >&2
  exit 1
}

# Isolate propagation and mount lifetime from the live environment.
if [[ ${DOTFILES_MOUNT_NAMESPACE:-0} != 1 ]]; then
  exec unshare --mount --propagation private env DOTFILES_MOUNT_NAMESPACE=1 \
    bash "$0" --root "$target" --hostname "$hostname" --timezone "$timezone"
fi

mounts=()
dns_backup=$(mktemp -d)
dns_changed=false
staging=$target/var/lib/dotfiles-installer
staging_created=false

cleanup() {
  local index

  if "$dns_changed"; then
    rm -f -- "$target/etc/resolv.conf"
    if [[ -e $dns_backup/resolv.conf || -L $dns_backup/resolv.conf ]]; then
      cp -a -- "$dns_backup/resolv.conf" "$target/etc/resolv.conf"
    fi
  fi

  rm -rf -- "$dns_backup"

  for ((index = ${#mounts[@]} - 1; index >= 0; index--)); do
    umount -R -- "${mounts[index]}" || true
  done

  if "$staging_created"; then
    rmdir "$staging" 2>/dev/null || true
  fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for name in proc sys dev run; do
  [[ ! -L $target/$name ]] || exit 1
  mkdir -p "$target/$name"

  if ! mountpoint -q "$target/$name"; then
    if [[ $name == proc ]]; then
      mount -t proc proc "$target/proc"
    else
      mount --rbind "/$name" "$target/$name"
      mount --make-rslave "$target/$name"
    fi
    mounts+=("$target/$name")
  fi
done

[[ ! -d $target/etc/resolv.conf ]] || exit 1

if [[ -e $target/etc/resolv.conf || -L $target/etc/resolv.conf ]]; then
  cp -a -- "$target/etc/resolv.conf" "$dns_backup/resolv.conf"
fi

dns_changed=true
rm -f -- "$target/etc/resolv.conf"
cp -L /etc/resolv.conf "$target/etc/resolv.conf"

bash "$repo/scripts/install-system-config.sh" --root "$target"

[[ ! -e $staging && ! -L $staging ]] || {
  echo "Staging path already exists: $staging" >&2
  exit 1
}

mkdir -p "$staging"
staging_created=true
mount --bind "$repo" "$staging"
mounts+=("$staging")
mount -o remount,bind,ro "$staging"

chroot "$target" /usr/bin/env -i HOME=/root TERM="${TERM:-linux}" \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /bin/bash /var/lib/dotfiles-installer/scripts/bootstrap.sh "$hostname" "$timezone"

echo 'Installation completed. Reboot manually, then run scripts/verify-desktop.sh from Mango.'
