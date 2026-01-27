#!/bin/sh
set -e
# shellcheck source=../init.sh

#######################################
# 声明框架能正常运行的依赖和版本要求(requirements)
# Globals:
#   gr_fw_preflight_path
#   gr_fw_requirements_path
#   gr_fw_requirements
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_requirements_declare() {
  if [ -z "$gr_fw_requirements_path" ]; then
    gr_fw_requirements_path="$gr_fw_preflight_path"/requirements
    readonly gr_fw_requirements_path
  fi

  # 声明 requirements
  if [ -z "$gr_fw_requirements" ]; then
  # format name:required_version:installed_version
  gr_fw_requirements="bash:4.3:5.3.9 yq:4.44.1:4.50.1"
  readonly gr_fw_requirements
fi

  # 导入 require scripts
  __fw_req=${__fw_req:-}
  __req_name=${__req_name:-}
  for __fw_req in $gr_fw_requirements; do
    __req_name=${__fw_req%%:*}
    __temp=${__fw_req#*:} # 暂存子串
    if [ "$__temp" = "$__fw_req" ]; then
      __req_ver=""
      __install_ver=""
    else
      __req_ver=${__temp%%:*}
      __install_ver=${__temp#*:}
      [ "$__install_ver" = "$__temp" ] && __install_ver=""
    fi

    __req_name_safe=${__req_name_safe:-}
    __req_name_safe=$(echo "$__req_name" | tr '-' '_')
    __require_script="$gr_fw_requirements_path/require_${__req_name_safe}.sh"
    if [ -f "$__require_script" ]; then
      # shellcheck source=./requirements/require_bash.sh
      # shellcheck source=./requirements/require_yq.sh
      . "$__require_script"
    fi
  done
  unset __fw_req __req_name __req_ver __install_ver __temp __req_name_safe __require_script
}

#######################################
# 检查 requirements 是否满足(并记录不满足项)
# Globals:
#   gr_fw_requirements
#   gw_fw_requirements_not_satisfied
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_requirements_check() {
  __fw_req=${__fw_req:-}
  __req_name=${__req_name:-}
  __req_ver=${__req_ver:-}
  for __fw_req in $gr_fw_requirements; do
    __req_name=${__fw_req%%:*}
    __temp=${__fw_req#*:}
    if [ "$__temp" = "$__fw_req" ]; then
      __req_ver=""
      __install_ver=""
    else
      __req_ver=${__temp%%:*}
      __install_ver=${__temp#*:}
      [ "$__install_ver" = "$__temp" ] && __install_ver=""
    fi

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
  if [ -n "${gw_fw_requirements_not_satisfied:-}" ]; then
    echo "Preflight: checking requirements..."
    echo "Preflight: missing requirements:${gw_fw_requirements_not_satisfied}"
  fi
  unset __req_name __req_ver __install_ver __temp __req_name_safe __fw_req
  return 0
}

#######################################
# 安装/准备未满足的 requirements
# Globals:
#   gw_fw_requirements_not_satisfied
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_prepare() {
  if [ -z "${gw_fw_requirements_not_satisfied:-}" ]; then
    return 0
  fi
  echo "Preflight: preparing requirements..."
  __fw_req=${__fw_req:-}
  __req_name=${__req_name:-}
  __req_ver=${__req_ver:-}
  for __fw_req in $gw_fw_requirements_not_satisfied; do
    __req_name=${__fw_req%%:*}
    __temp=${__fw_req#*:}
    if [ "$__temp" = "$__fw_req" ]; then
      __req_ver=""
      __install_ver=""
    else
      __req_ver=${__temp%%:*}
      __install_ver=${__temp#*:}
      [ "$__install_ver" = "$__temp" ] && __install_ver=""
    fi

    __req_name_safe=$(echo "$__req_name" | tr '-' '_')
    if command -v "__fw_requirements_prepare_$__req_name_safe" >/dev/null 2>&1; then
      if ! "__fw_requirements_prepare_$__req_name_safe" "$__req_ver" "$__install_ver"; then
        return 1
      fi
    else
      echo "Error: $__fw_req is required. Please install it manually." >&2
      return 1
    fi
  done
  unset __req_name __req_ver __install_ver __temp __req_name_safe __fw_req gw_fw_requirements_not_satisfied
}

#######################################
# 如安装了新 bash，则使用新 bash 重新执行当前命令
# Globals:
#   gw_fw_requirements_bash_reexec
#   gw_fw_requirements_bash_required_ver
#   GW_FW_REQUIREMENTS_REEXECED
# Arguments:
#   @ - 原始命令行参数
# Outputs:
#   None
# Returns:
#   0 - 无需重启或已完成重启
#   1 - 重启前校验失败
#######################################
__fw_requirements_reexec_bash_if_needed() {
  __bash_bin=${gw_fw_requirements_bash_reexec:-}
  if [ -z "$__bash_bin" ]; then
    return 0
  fi
  if [ "${GW_FW_REQUIREMENTS_REEXECED:-0}" = "1" ]; then
    return 0
  fi

  if ! __fw_requirements_check_bash "${gw_fw_requirements_bash_required_ver:-}" "$__bash_bin"; then
    echo "Error: Installed bash does not meet required version." >&2
    return 1
  fi

  export GW_FW_REQUIREMENTS_REEXECED=1
  echo "Preflight: re-exec with $__bash_bin"
  exec "$__bash_bin" "$0" "$@"
}

#######################################
# 预检入口：声明、检查并准备 requirements
# Globals:
#   None
# Arguments:
#   @ - 原始命令行参数
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__main() {
  __fw_requirements_declare
  __fw_requirements_check || return 1
  __fw_requirements_prepare || return 1
  __fw_requirements_reexec_bash_if_needed "$@" || return 1
}

#----------------------------------------------------------------------------------------------------------------------#
gr_fw_requirements=${gr_fw_requirements:-}
gr_fw_requirements_path=${gr_fw_requirements_path:-}
gw_fw_requirements_not_satisfied=${gw_fw_requirements_not_satisfied:-}
gw_fw_requirements_bash_reexec=${gw_fw_requirements_bash_reexec:-}
gw_fw_requirements_bash_required_ver=${gw_fw_requirements_bash_required_ver:-}
__main "$@"
