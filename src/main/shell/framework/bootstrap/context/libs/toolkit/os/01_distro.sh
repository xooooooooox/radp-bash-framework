#!/usr/bin/env bash
# toolkit module: os/01_distro.sh

radp_os_get_distro_arch() {
  if [[ -n "${gr_distro_arch:-}" ]]; then
    echo "$gr_distro_arch"
    return 0
  fi
  local distro_arch
  IFS=':' read -r distro_arch _ _ _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_arch"
}

radp_os_get_distro_os() {
  if [[ -n "${gr_distro_os:-}" ]]; then
    echo "$gr_distro_os"
    return 0
  fi
  local distro_os
  IFS=':' read -r _ distro_os _ _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_os"
}

radp_os_get_distro_id() {
  if [[ -n "${gr_distro_id:-}" ]]; then
    echo "$gr_distro_id"
    return 0
  fi
  local distro_id
  IFS=':' read -r _ _ distro_id _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_id"
}

radp_os_get_distro_name() {
  if [[ -n "${gr_distro_name:-}" ]]; then
    echo "$gr_distro_name"
    return 0
  fi
  local distro_name
  IFS=':' read -r _ _ _ distro_name _ _ < <(__fw_os_get_distro_info)
  echo "$distro_name"
}

radp_os_get_distro_version() {
  if [[ -n "${gr_distro_version:-}" ]]; then
    echo "$gr_distro_version"
    return 0
  fi
  local distro_version
  IFS=':' read -r _ _ _ _ distro_version _ < <(__fw_os_get_distro_info)
  echo "$distro_version"
}

radp_os_get_distro_pm() {
  if [[ -n "${gr_distro_pm:-}" ]]; then
    echo "$gr_distro_pm"
    return 0
  fi
  local distro_pm
  IFS=':' read -r _ _ _ _ _ distro_pm < <(__fw_os_get_distro_info)
  echo "$distro_pm"
}
