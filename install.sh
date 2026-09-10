#!/usr/bin/env bash

set -euo pipefail

repo=$(cd -- "$(dirname -- "$(readlink -f "$0")")" && pwd)
target=/
check_only=false
while (($#)); do
  case $1 in
    --root)
      target=${2:?--root needs a mounted Gentoo root}
      shift 2
      ;;
    --check-only)
      check_only=true
      shift
      ;;
    --help | -h)
      echo 'Usage: sudo ./install.sh [--root /mnt/gentoo] [--check-only]'
      echo 'Install tracked system configuration into an extracted Gentoo system.'
      echo 'Prepare storage and verify stage3 manually before running this script.'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

target=$(realpath -e -- "$target")
[[ -f $target/etc/gentoo-release ]] || {
  echo 'Extract a verified Gentoo desktop OpenRC stage3 first.' >&2
  exit 1
}

profile=$(readlink "$target/etc/portage/make.profile")
[[ $profile == *default/linux/amd64/23.0/desktop && $profile != *systemd* ]] || {
  echo "Select the amd64 23.0 desktop OpenRC profile first: $profile" >&2
  exit 1
}

arguments=(--root "$target")
"$check_only" && arguments+=(--dry-run)
bash "$repo/scripts/install-system-config.sh" "${arguments[@]}"
if ! "$check_only"; then
  chroot "$target" /bin/bash -ec '
if ! eselect repository list >/dev/null 2>&1; then
  getuto
  emerge --ask --getbinpkg app-eselect/eselect-repository
fi

eselect repository enable guru
eselect repository enable waffle-builds
eselect repository enable spikyatlinux
eselect repository enable gentoo-zh
emaint sync -a
'
fi

echo 'System configuration processed; repositories enabled on installation.'
echo 'No partitions or services changed.'
echo 'Run getuto, then probe package sets with emerge -pv --getbinpkg --usepkgonly.'
