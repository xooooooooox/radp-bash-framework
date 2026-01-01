#!/usr/bin/env bash
set -e
# shellcheck source=../vars/global_vars.sh

__fw_include_lib_internal() {
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

__fw_include_lib_external() {
  # TODO v1.0-2026/1/1: log debug sourced scripts
  __fw_source_scripts "$gr_radp_fw_user_lib_path"
}

__main() {
  __fw_include_lib_internal
  __fw_include_lib_external
}

__main
