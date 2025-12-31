#!/usr/bin/env bash
set -e
# shellcheck source=../vars/global_vars.sh

__main() {
  # 加载日志组件
  # shellcheck source=./logger/logger.sh
  __fw_source_scripts "$gr_fw_context_libs_path"/logger/logger.sh
  # 如果日志组件成功加载, 后续便可以使用 radp_log_xx 进行日志打印了

  __fw_source_scripts "$gr_fw_context_libs_path"/toolkit || {
    local msg='Failed to load framework libs, please check your code.'
    radp_log_error "$msg"
    return 1
  }
}

__main
