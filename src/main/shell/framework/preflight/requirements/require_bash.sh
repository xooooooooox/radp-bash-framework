#!/bin/sh

__fw_requirements_check_bash() {
  __req_ver=${1:-}
  __ok=0
  if [ -n "$BASH_VERSION" ]; then
    if [ -z "$__req_ver" ]; then
      __ok=1
    else
      __curr_major=$(echo "$BASH_VERSION" | cut -d. -f1)
      __curr_minor=$(echo "$BASH_VERSION." | cut -d. -f2)
      [ -z "$__curr_minor" ] && __curr_minor=0
      __req_major=$(echo "$__req_ver" | cut -d. -f1)
      __req_minor=$(echo "$__req_ver." | cut -d. -f2)
      [ -z "$__req_minor" ] && __req_minor=0
      if [ "$__curr_major" -gt "$__req_major" ] || { [ "$__curr_major" -eq "$__req_major" ] && [ "$__curr_minor" -ge "$__req_minor" ]; }; then
        __ok=1
      fi
    fi
  fi
  unset __curr_major __curr_minor __req_major __req_minor __req_ver
  if [ "$__ok" -eq 1 ]; then
    unset __ok
    return 0
  else
    unset __ok
    return 1
  fi
}

__fw_requirements_prepare_bash() {
  __req_ver=${1:-}
  __install_ver=${2:-}
  # TODO v1.0-2025/12/31: 待实现
}
