#!/usr/bin/env bash
set -e

#######################################
# 提供编码时的代码补全功能.
# 该功能由 bashsupport pro 提供,
# 详情见(https://www.bashsupport.com/manual/navigation/sourced-files/)
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_context_setup_code_completion() {
  # shellcheck source=./compinit.sh
  __fw_source_scripts "$gr_fw_context_path"/compinit.sh
}

#######################################
# 上下文注入全局变量
# Globals:
#   None
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   None
#######################################
__fw_context_setup_global_vars() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  # shellcheck source=./vars/global_vars.sh
  __fw_source_scripts "$pwd"/vars/global_vars.sh "$@" || {
    local context_err_msg='Pre defined vars contains invalid value, please check your code.'
    radp_log_error "$context_err_msg" || echo "Warn: $context_err_msg" 2>&1
    return 1
  }
}

#######################################
# 上下文注入类库函数
# Globals:
#   gr_framework_libs_path - 库函数脚本所在绝对路径
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   1 - failed
#######################################
__fw_context_setup_libs() {
  # shellcheck source=./libs/libs.sh
  __fw_source_scripts "$gr_fw_context_libs_path"/libs.sh || {
    echo "Failed to setup logging, please check your code and config file" >&1
    return 1
  }
}

#######################################
# 自动配置
# Globals:
#   None
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   None
#######################################
__fw_context_setup() {
  __fw_context_setup_global_vars "$@"
  __fw_context_setup_libs
  __fw_context_setup_code_completion
}

__fw_context_finished() {
  # print banner with variable substitution
  if [[ "$gr_radp_fw_banner_mode" == "off" ]]; then
    return 0
  fi
  local banner
  banner="$(eval "printf '%s' \"$(cat "$gr_fw_banner_file")\"")"
  radp_log_raw "$banner"
  radp_log_info "${gra_command_line[*]}"
}

__main() {
  # 进一步幂等控制, 避免重复加载上下文
  if [[ "${gw_fw_context_initialized:-0}" == "1" ]]; then
    return 0
  fi
  gw_fw_context_initialized="1"
  readonly gw_fw_context_initialized

  __fw_context_setup "$@"
  __fw_context_finished
}

declare -g gw_fw_context_initialized="0"
__main "$@"
