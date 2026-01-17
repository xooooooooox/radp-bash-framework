#!/usr/bin/env bash
# toolkit module: os/01_distro.sh

radp_os_get_distro_arch() {
  local distro_arch
  IFS=':' read -r distro_arch _ _ _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_arch"
}

radp_os_get_distro_os() {
  local distro_os
  IFS=':' read -r _ distro_os _ _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_os"
}

radp_os_get_distro_id() {
  local distro_id
  IFS=':' read -r _ _ distro_id _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_id"
}

radp_os_get_distro_name() {
  local distro_name
  IFS=':' read -r _ _ _ distro_name _ _ < <(__fw_os_get_distro_info)
  echo "$distro_name"
}

radp_os_get_distro_version() {
  local distro_version
  IFS=':' read -r _ _ _ _ distro_version _ < <(__fw_os_get_distro_info)
  echo "$distro_version"
}

radp_os_get_distro_pm() {
  local distro_pm
  IFS=':' read -r _ _ _ _ _ distro_pm < <(__fw_os_get_distro_info)
  echo "$distro_pm"
}
