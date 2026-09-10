#!/usr/bin/env bash

set -euo pipefail

repo=$(cd -- "$(dirname -- "$(readlink -f "$0")")/.." && pwd)
root=/
dry_run=false

while (($#)); do
  case $1 in
    --root)
      root=${2:?--root needs a target directory}
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --help | -h)
      echo 'Usage: install-system-config.sh [--root DIRECTORY] [--dry-run]'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

root=$(realpath -e -- "$root")

if ! "$dry_run"; then
  [[ $EUID == 0 ]] || {
    echo 'Run as root, or use --dry-run' >&2
    exit 1
  }
  [[ -f $root/etc/gentoo-release ]] || {
    echo 'Target must contain /etc/gentoo-release' >&2
    exit 1
  }
fi

stamp=$(date -u +%Y%m%dT%H%M%SZ)-$$
temporary=
scratch=$(mktemp -d)
trap '[[ -z $temporary ]] || rm -f -- "$temporary"; rm -rf -- "$scratch"' EXIT

refuse_symlinks() {
  local path=$1

  while [[ $path != "$root" && $path != / ]]; do
    if [[ -L $path ]]; then
      echo "Refusing symlink: $path" >&2
      exit 1
    fi
    path=$(dirname -- "$path")
  done
}

install_file() {
  local source=$1 relative=$2 mode=${3:-644} target backup
  target=${root%/}/$relative
  refuse_symlinks "$target"

  if [[ -f $target ]] && cmp -s -- "$source" "$target" \
    && [[ $(stat -c '%u:%g:%a' "$target") == "0:0:$mode" ]]; then
    return
  fi

  printf 'install %s\n' "$target"
  "$dry_run" && return

  mkdir -p -- "$(dirname -- "$target")"

  if [[ -e $target ]]; then
    [[ -f $target ]] || {
      echo "Not a regular file: $target" >&2
      exit 1
    }
    backup=${root%/}/var/backups/dotfiles/$stamp/$relative
    refuse_symlinks "$backup"
    [[ ! -e $backup ]] || {
      echo "Backup already exists: $backup" >&2
      exit 1
    }
    mkdir -p -- "$(dirname -- "$backup")"
    cp -p -- "$target" "$backup"
  fi

  temporary=$(mktemp "$(dirname -- "$target")/.dotfiles.XXXXXXXX")
  command install -o 0 -g 0 -m "$mode" -- "$source" "$temporary"
  sync -f "$temporary"
  mv -T -- "$temporary" "$target"
  temporary=
}

make_conf=${root%/}/etc/portage/make.conf
refuse_symlinks "$make_conf"
[[ ! -d $make_conf ]] || {
  echo 'Review the existing make.conf directory manually' >&2
  exit 1
}

for base in etc rootfs; do
  [[ -d $repo/$base ]] || {
    echo "Missing source directory: $base" >&2
    exit 1
  }

  while IFS= read -r -d '' source; do
    relative=${source#"$repo/$base/"}
    [[ $base == etc ]] && relative=etc/$relative
    mode=644
    [[ $relative == *.install || /$relative/ == */bin/* || /$relative/ == */sbin/* ]] && mode=755
    install_file "$source" "$relative" "$mode"
  done < <(find "$repo/$base" -type f -print0 | sort -z)
done

install_file "$repo/config/wmenu/center.patch" etc/portage/patches/gui-apps/wmenu/center.patch

directive='source /etc/portage/make.conf.dotfiles'

if [[ ! -f $make_conf ]] || ! grep -Fxq -- "$directive" "$make_conf"; then
  [[ ! -f $make_conf ]] || cat -- "$make_conf" >"$scratch/make.conf"
  printf '\n%s\n' "$directive" >>"$scratch/make.conf"
  install_file "$scratch/make.conf" etc/portage/make.conf
fi
