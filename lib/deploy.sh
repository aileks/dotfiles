# shellcheck shell=bash
# Deployment facts shared by setup.sh and bin/doctor: the installer and the
# verifier must agree on them, so they are defined exactly once here. The
# constants are the consumers' interface, not dead assignments.
# shellcheck disable=SC2034

readonly -a ENABLED_SYSTEM_UNITS=(
  NetworkManager.service
  avahi-daemon.service
  bluetooth.service
  cups.service
  systemd-timesyncd.service
)

readonly MDNS_HOSTS_REGEX='^hosts:.*[[:space:]]mdns(_minimal)?([[:space:]]|$)'

user_in_group() {
  local user="$1" group="$2"
  id -nG "$user" | tr ' ' '\n' | grep -qx "$group"
}
