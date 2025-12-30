#!/usr/bin/env bash
set -e
# shellcheck source=../bootstrap.sh

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
__framework_context_autoconfigure_global_vars() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  # shellcheck source=./vars/global_vars.sh
  __framework_source_scripts "$pwd"/vars/global_vars.sh "$@" || {
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
__framework_context_autoconfigure_libs() {
  # shellcheck source=./libs/libs.sh
  __framework_source_scripts "$gr_framework_context_libs_path"/libs/libs.sh || {
    echo "Failed to setup logging, please check your code and config file" >&1
    return 1
  }
}

__main() {
  __framework_context_autoconfigure_global_vars "$@" || return 1
  __framework_context_autoconfigure_libs || return 1
}

__main "$@"
