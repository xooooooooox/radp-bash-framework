#!/usr/bin/env bash
set -e

#######################################
# 初始化日志框架
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
# Note:
#   - 文件描述符 3 被重定向到日志文件, 用于日志记录
#   - 文件描述符 4 根据脚本运行环境的不同, 可能被重定向到 /dev/tty, stdout 或 /dev/null
#     用于控制台输出. 以保证即使在脚本被重定向输出到文件时, 控制台日志仍然可被正确输出.
#   - 函数内部对重定向操作进行了错误检查，任何重定向失败都会导致脚本退出，
#######################################
__framework_setup_logger() {
  if [[ "${gw_framework_logger_initialized:-0}" == "1" ]]; then
    return 0
  fi
  declare -g gw_framework_logger_initialized="1"

  local log_path log_file
  :
}

__main() {
  declare -g gw_framework_logger_initialized=0
  __framework_setup_logger
}

__main
