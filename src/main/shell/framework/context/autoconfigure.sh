#!/usr/bin/env bash
set -e

__framework_context_autoconfigure_global_vars() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  # shellcheck source=./vars/global_vars.sh
  __framework_source_scripts "$pwd"/vars/global_vars.sh || {
    local context_err_msg='Pre defined vars contains invalid value, please check your code.'
    radp_log_error "$context_err_msg" || echo "Warn: $context_err_msg" 2>&1
    return 1
  }
}

__framework_context_autoconfigure_libs() {
  # 加载日志组件
  # shellcheck source=./libs/libs.sh
  __framework_source_scripts "$gr_framework_libs_path"/libs/libs.sh || {
    echo "Failed to setup logging, please check your code and config file" >&1
    return 1
  }

  # 如果日志组件成功加载, 后续便可以使用 radp_log_xx 进行日志打印了
  # TODO v1.0-2025/12/29: 接下来加载工具库
}

__main() {
  __framework_context_autoconfigure_global_vars "$@" || return 1
  __framework_context_autoconfigure_libs || return 1
}

__main "$@"
