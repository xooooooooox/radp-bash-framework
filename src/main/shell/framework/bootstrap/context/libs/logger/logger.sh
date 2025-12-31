#!/usr/bin/env bash
set -e

radp_log_debug() {
  :
}

radp_log_info() {
  :
}

radp_log_warn() {
  :
}

radp_log_error() {
  :
}

#----------------------------------------------------------------------------------------------------------------------#
#######################################
# 初始化日志框架.
# 为了避免日志输出影响函数返回值:
# 1) 将 fd3 重定向到日志文件
# 2) 将 fd4 重定向到控制台输出
#
# Globals:
#   gr_radp_log_debug - 是否为 debug 模式
#   gr_radp_log_file - 日志文件绝对路径
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
  local log_path logfile
  logfile="${gr_radp_log_file:?}"
  log_path=$(dirname "$logfile")

  if [[ ! -d "$log_path" ]]; then
    if ! mkdir -p "$log_path"; then
      # TODO v1.0-2025/12/31: 不应该直接使用 sudo 应该根据实际情况来决定是否需要sudo,如果当前用户已经是 root 了, sudo 就没必要了
      sudo mkdir -p "$log_path" 2>/dev/null || {
        echo "Error: Failed to log path '$log_path'."
        exit 1
      }
      # TODO v1.0-2025/12/31: owner:group
      sudo chown -Rv "":"" "$log_path"
    fi
  fi

  if [[ -f "$logfile" && ! -w "$logfile" ]]; then
    echo "Give write permission to $logfile"
    sudo chmod u+w,g+w "$logfile"
  fi

  exec 3>>"$logfile" || {
    echo "Error: Failed to open logfile '$logfile' for writing."
    exit 1
  }
  [[ "$gr_radp_log_debug" == 'true' ]] && echo "Redirect fd3 to '$logfile'"

  # 检测是否在交互式终端中运行
  # 如果是则重定向到 stdout
  # fall back to /dev/null if not available
  if [[ -t 1 ]]; then
    if [[ -e /dev/tty ]]; then
      if exec 4>/dev/tty; then
        if [[ "$g_debug" == 'true' ]]; then
          echo "Redirect fd4 to /dev/tty"
        fi
      else
        exec 4>&1
        echo "Fallback to redirecting fd4 to stdout because '/dev/tty' is not available or not writable."
      fi
    else
      exec 4>&1
      echo "Fallback to redirecting fd4 to stdout because /dev/tty is not available."
    fi
  else
    if exec 4>&1; then
      if [[ "$g_debug" == 'true' ]]; then
        echo "In non-interactive terminal, redirecting fd4 to stdout"
      fi
    else
      exec 4>/dev/null
      echo "Fallback to redirecting fd4 to /dev/null"
    fi
  fi
}

__main() {
  __framework_setup_logger
}

__main
