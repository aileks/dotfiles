#!/usr/bin/env bash

set -euo pipefail

repo=$(cd -- "$(dirname -- "$(readlink -f "$0")")/.." && pwd)
bash "$repo/scripts/preflight.sh"

[[ ${XDG_SESSION_TYPE:-} == wayland && ${XDG_CURRENT_DESKTOP:-} == mango ]]
nmcli networking connectivity check
getent hosts gentoo.org
wpctl status
wpctl inspect @DEFAULT_AUDIO_SINK@
nvidia-smi
timeout 5 mmsg -g

echo 'Runtime probes passed. Check audible playback and visible Mango rendering.'
echo 'After confirming this boot works: sudo update-limine --confirm-running'
