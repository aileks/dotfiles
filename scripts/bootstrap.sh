#!/usr/bin/env bash

set -euo pipefail

[[ $EUID == 0 && -f /etc/gentoo-release ]] || exit 1

repo=$(cd -- "$(dirname -- "$(readlink -f "$0")")/.." && pwd)
hostname=${1:?hostname required}
timezone=${2:?timezone required}

mkdir -p /var/db/repos/dotfiles
cp -a "$repo/overlay/." /var/db/repos/dotfiles/

getuto
emerge --sync

eselect profile set default/linux/amd64/23.0/desktop
[[ $(readlink /etc/portage/make.profile) == *default/linux/amd64/23.0/desktop ]] || exit 1

emerge --getbinpkg --noreplace app-eselect/eselect-repository dev-vcs/git

for overlay in guru waffle-builds spikyatlinux gentoo-zh; do
  eselect repository enable "$overlay"
done

emaint sync -a

sets=(@base @cli @desktop @apps @dev)
emerge --pretend --getbinpkg "${sets[@]}"
emerge --getbinpkg --update --deep --newuse "${sets[@]}"

# Reapply tracked policy after packages supply their defaults.
bash "$repo/scripts/install-system-config.sh"

[[ -f /usr/share/zoneinfo/$timezone ]] || {
  echo "Unknown timezone: $timezone" >&2
  exit 1
}

printf '%s\n' "$timezone" >/etc/timezone
ln -sfn "/usr/share/zoneinfo/$timezone" /etc/localtime

grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >>/etc/locale.gen
locale-gen
eselect locale set en_US.utf8

printf 'hostname="%s"\n' "$hostname" >/etc/conf.d/hostname
printf '%s\n' "$hostname" >/etc/hostname
env-update

if ! id aileks >/dev/null 2>&1; then
  useradd -m -s /bin/zsh aileks
fi

for group in wheel audio video input plugdev; do
  getent group "$group" >/dev/null || groupadd "$group"
  usermod -aG "$group" aileks
done

usermod -s /bin/zsh aileks

install -d -m 750 /etc/sudoers.d
echo '%wheel ALL=(ALL:ALL) ALL' >/etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
visudo -cf /etc/sudoers

if [[ $(passwd -S aileks | awk '{print $2}') != P ]]; then
  passwd aileks
fi

user_home=$(getent passwd aileks | cut -d: -f6)
destination=$user_home/Projects/dotfiles

if [[ ! -e $destination ]]; then
  install -d -o aileks -g "$(id -gn aileks)" "$user_home/Projects"
  cp -a "$repo" "$destination"
  chown -R aileks:"$(id -gn aileks)" "$destination"
else
  [[ ! -L $destination ]] || exit 1
  diff -qr --exclude=.git --exclude=__pycache__ "$repo" "$destination" || {
    echo "Existing checkout differs; update it before resuming: $destination" >&2
    exit 1
  }

  echo "Using existing checkout: $destination"
fi

runuser -u aileks -- env -i HOME="$user_home" USER=aileks LOGNAME=aileks \
  PATH=/usr/local/bin:/usr/bin:/bin bash "$destination/scripts/setup-user.sh"

# Use the installed kernel, never uname -r from the install medium.
mapfile -t kernels < <(find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V)
((${#kernels[@]})) || {
  echo 'No installed kernels.' >&2
  exit 1
}

version=${kernels[-1]}
dracut --force --no-hostonly "/boot/initramfs-$version.img" "$version"
bash /usr/local/sbin/update-limine "$version" "/boot/vmlinuz-$version"

bash "$repo/scripts/setup-limine.sh"
bash "$repo/scripts/setup-services.sh"

runuser -u aileks -- env -i HOME="$user_home" USER=aileks LOGNAME=aileks \
  PATH="$user_home/.local/bin:/usr/local/bin:/usr/bin:/bin" bash "$destination/scripts/preflight.sh"
