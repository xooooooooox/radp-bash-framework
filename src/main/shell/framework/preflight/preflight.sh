#!/bin/sh
set -e
# shellcheck source=../run.sh

__fw_requirements_declare() {
  if [ -z "$gr_fw_requirements_path" ]; then
    gr_fw_requirements_path="$gr_fw_preflight_path"/requirements
    readonly gr_fw_requirements_path
  fi

  # 声明 requirements
  if [ -z "$gr_fw_requirements" ]; then
    gr_fw_requirements="bash:4.3 yq:4.44.1"
    readonly gr_fw_requirements
  fi

  # 导入 require scripts
  __fw_req=${__fw_req:-}
  for __fw_req in $gr_fw_requirements; do
    __req_name=${__fw_req%%:*}
    __req_ver=${__fw_req#*:}
    [ "$__req_name" = "$__req_ver" ] && __req_ver=""

    __req_name_safe=${__req_name_safe:-}
    __req_name_safe=$(echo "$__req_name" | tr '-' '_')
    __require_script="$gr_fw_requirements_path/require_${__req_name_safe}.sh"
    if [ -f "$__require_script" ]; then
      # shellcheck source=./requirements/require_bash.sh
      # shellcheck source=./requirements/require_yq.sh
      . "$__require_script"
    fi
  done
  unset __fw_req __req_name __req_ver __req_name_safe __require_script __fw_preflight_dir
}

__fw_requirements_check() {
  __fw_req=${__fw_req:-}
  for __fw_req in $gr_fw_requirements; do
    __req_name=${__fw_req%%:*}
    __req_ver=${__fw_req#*:}
    [ "$__req_name" = "$__req_ver" ] && __req_ver=""

    __req_name_safe=${__req_name_safe:-}
    __req_name_safe=$(echo "$__req_name" | tr '-' '_')
    if command -v "__fw_requirements_check_$__req_name_safe" >/dev/null 2>&1; then
      if ! "__fw_requirements_check_$__req_name_safe" "$__req_ver"; then
        gw_fw_requirements_not_satisfied="$gw_fw_requirements_not_satisfied $__fw_req"
      fi
    else
      if ! command -v "$__req_name" >/dev/null 2>&1; then
        gw_fw_requirements_not_satisfied="$gw_fw_requirements_not_satisfied $__fw_req"
      fi
    fi
  done
  unset __req_name __req_ver __req_name_safe __fw_req
  return 0
}

__fw_requirements_prepare() {
  for __fw_req in $gw_fw_requirements_not_satisfied; do
    __req_name=${__fw_req%%:*}
    __req_ver=${__fw_req#*:}
    [ "$__req_name" = "$__req_ver" ] && __req_ver=""

    __req_name_safe=$(echo "$__req_name" | tr '-' '_')
    if command -v "__fw_requirements_prepare_$__req_name_safe" >/dev/null 2>&1; then
      if ! "__fw_requirements_prepare_$__req_name_safe" "$__req_ver"; then
        return 1
      fi
    else
      echo "Error: $__fw_req is required. Please install it manually." >&2
      return 1
    fi
  done
  unset __req_name __req_ver __req_name_safe __fw_req gw_fw_requirements_not_satisfied
}

__main() {
  __fw_requirements_declare
  __fw_requirements_check || return 1
  __fw_requirements_prepare
}

gr_fw_requirements_path=${gr_fw_requirements_path:-}
gr_fw_requirements=${gr_fw_requirements:-}
gw_fw_requirements_not_satisfied=${gw_fw_requirements_not_satisfied:-}
__main
