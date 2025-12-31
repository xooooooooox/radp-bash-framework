#!/usr/bin/env bash
set -e

#######################################
# 根据日志级别返回对应的颜色代码
# Globals:
#   gr_radp_log_color_debug - DEBUG 级别颜色代码
#   gr_radp_log_color_info - INFO 级别颜色代码
#   gr_radp_log_color_warn - WARN 级别颜色代码
#   gr_radp_log_color_error - ERROR 级别颜色代码
# Arguments:
#   1 - log_level: 日志级别 (DEBUG, INFO, WARN, ERROR)
# Outputs:
#   颜色代码字符串
# Returns:
#   0 - Success
#######################################
__fw_get_log_level_color() {
  local -u log_level=${1:-}
  local color_code
  case "$log_level" in
    DEBUG) color_code="${gr_radp_log_color_debug:-36}" ;;
    INFO)  color_code="${gr_radp_log_color_info:-32}" ;;
    WARN)  color_code="${gr_radp_log_color_warn:-33}" ;;
    ERROR) color_code="${gr_radp_log_color_error:-31}" ;;
    *)     echo -e "\033[0m"; return ;;  # 默认/重置
  esac
  echo -e "\033[${color_code}m"
}

#######################################
# 根据 pattern 格式化日志消息
# 支持的占位符:
#   %d - 日期时间 (yyyy-MM-dd HH:mm:ss.SSS)
#   %p - 日志级别
#   %P - 进程ID
#   %t - 线程名/主脚本名
#   %F - 文件名
#   %M - 函数名
#   %L - 行号
#   %m - 日志消息
#   %n - 换行符
# Globals:
#   None
# Arguments:
#   1 - pattern: 日志格式模式
#   2 - log_level: 日志级别
#   3 - message: 日志消息
#   4 - script_name: 脚本文件名
#   5 - func_name: 函数名
#   6 - line_no: 行号
# Outputs:
#   格式化后的日志消息
# Returns:
#   0 - Success
#######################################
__fw_format_log_message() {
  local pattern=${1:?'Missing pattern argument'}
  local log_level=${2:?'Missing log_level argument'}
  local message=${3:-}
  local script_name=${4:-}
  local func_name=${5:-}
  local line_no=${6:-}

  local timestamp thread_name pid
  # macOS 的 date 不支持 %N，使用兼容方式
  if command -v gdate &>/dev/null; then
    timestamp=$(gdate +'%Y-%m-%d %H:%M:%S.%3N')
  else
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  fi
  # TODO v1.0-2025/12/31: 这里是否有必要从 gr_command_line[0] 中获取 thread_name
  thread_name=$(basename "$0")
  pid=$$

  # 格式化各字段
  local formatted_level formatted_pid formatted_position
  formatted_level=$(printf "%-5s" "${log_level^^}")
  formatted_pid=$(printf "%-5s" "$pid")
  formatted_position=$(printf "%-50s" "${line_no}:${script_name}#${func_name}")

  local result="$pattern"
  # 替换占位符
  result="${result//%d/$timestamp}"
  result="${result//%p/$formatted_level}"
  result="${result//%P/$formatted_pid}"
  result="${result//%t/$thread_name}"
  result="${result//%F/$script_name}"
  result="${result//%M/$func_name}"
  result="${result//%L/$line_no}"
  result="${result//%m/$message}"
  result="${result//%n/$'\n'}"

  echo "$result"
}

#######################################
# 核心日志记录函数
# 根据日志级别、消息和上下文信息，构造并输出格式化的日志消息
# 支持日志级别过滤，只有高于或等于配置日志级别的消息才会被记录
# 日志消息将同时输出到控制台(fd4)和日志文件(fd3)
# Globals:
#   gr_radp_log_debug - 是否为 debug 模式
#   gr_radp_log_level - 配置的日志级别
#   gr_radp_log_pattern_console - 控制台日志格式
#   gr_radp_log_pattern_file - 文件日志格式
# Arguments:
#   1 - log_level: 日志级别 (DEBUG, INFO, WARN, ERROR)
#   2 - message: 日志消息
#   3 - script_name: 脚本文件名
#   4 - func_name: 函数名
#   5 - line_no: 行号
# Outputs:
#   格式化的日志到 fd3(文件) 和 fd4(控制台)
# Returns:
#   0 - Success
#######################################
__fw_logger() {
  local -u log_level=${1:?'Missing log_level argument'}
  local message=${2:-}
  local script_name=${3:-}
  local func_name=${4:-}
  local line_no=${5:-}

  # 日志级别映射
  local -A log_level_id=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
  )

  # 获取配置的日志级别, 默认为 INFO
  local configured_level="${gr_radp_log_level:-info}"
  configured_level="${configured_level^^}"

  # 判断是否需要输出日志
  local current_level_id=${log_level_id[$log_level]:-1}
  local configured_level_id=${log_level_id[$configured_level]:-1}

  if [[ "${gr_radp_log_debug:-false}" == "true" || $current_level_id -ge $configured_level_id ]]; then
    # 获取日志格式 pattern
    local console_pattern="${gr_radp_log_pattern_console:-%d | %p %P | %t | %L:%F#%M | %m}"
    local file_pattern="${gr_radp_log_pattern_file:-%d | %p %P | %t | %L:%F#%M | %m}"

    # 格式化日志消息
    local formatted_console formatted_file
    formatted_console=$(__fw_format_log_message "$console_pattern" "$log_level" "$message" "$script_name" "$func_name" "$line_no")
    formatted_file=$(__fw_format_log_message "$file_pattern" "$log_level" "$message" "$script_name" "$func_name" "$line_no")

    # 获取颜色代码
    local log_color no_color
    log_color=$(__fw_get_log_level_color "$log_level")
    no_color=$(__fw_get_log_level_color "default")

    # 输出到文件(fd3)和控制台(fd4)，不影响脚本返回值
    {
      echo -e "${formatted_file}" >&3 2>/dev/null || true
      echo -e "${log_color}${formatted_console}${no_color}" >&4 2>/dev/null || true
    } &>/dev/null
  fi
}

#######################################
# 打印 debug 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息
#   2 - script_name (可选): 脚本名称，未提供则自动推断
#   3 - func_name (可选): 函数名称，未提供则自动推断
#   4 - line_no (可选): 行号，未提供则自动推断
# Returns:
#   0 - Success
#######################################
radp_log_debug() {
  local msg=${1:-}
  local script_name func_name line_no
  script_name=${2:-$(basename "${BASH_SOURCE[2]:-${BASH_SOURCE[1]:-unknown}}")}
  func_name=${3:-${FUNCNAME[1]:-main}}
  line_no=${4:-${BASH_LINENO[0]:-0}}
  __fw_logger "DEBUG" "$msg" "$script_name" "$func_name" "$line_no"
}

#######################################
# 打印 info 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息
#   2 - script_name (可选): 脚本名称，未提供则自动推断
#   3 - func_name (可选): 函数名称，未提供则自动推断
#   4 - line_no (可选): 行号，未提供则自动推断
# Returns:
#   0 - Success
#######################################
radp_log_info() {
  local msg=${1:-}
  local script_name func_name line_no
  script_name=${2:-$(basename "${BASH_SOURCE[2]:-${BASH_SOURCE[1]:-unknown}}")}
  func_name=${3:-${FUNCNAME[1]:-main}}
  line_no=${4:-${BASH_LINENO[0]:-0}}
  __fw_logger "INFO" "$msg" "$script_name" "$func_name" "$line_no"
}

#######################################
# 打印 warn 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息
#   2 - script_name (可选): 脚本名称，未提供则自动推断
#   3 - func_name (可选): 函数名称，未提供则自动推断
#   4 - line_no (可选): 行号，未提供则自动推断
# Returns:
#   0 - Success
#######################################
radp_log_warn() {
  local msg=${1:-}
  local script_name func_name line_no
  script_name=${2:-$(basename "${BASH_SOURCE[2]:-${BASH_SOURCE[1]:-unknown}}")}
  func_name=${3:-${FUNCNAME[1]:-main}}
  line_no=${4:-${BASH_LINENO[0]:-0}}
  __fw_logger "WARN" "$msg" "$script_name" "$func_name" "$line_no"
}

#######################################
# 打印 error 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息
#   2 - script_name (可选): 脚本名称，未提供则自动推断
#   3 - func_name (可选): 函数名称，未提供则自动推断
#   4 - line_no (可选): 行号，未提供则自动推断
# Returns:
#   0 - Success
#######################################
radp_log_error() {
  local msg=${1:-}
  local script_name func_name line_no
  script_name=${2:-$(basename "${BASH_SOURCE[2]:-${BASH_SOURCE[1]:-unknown}}")}
  func_name=${3:-${FUNCNAME[1]:-main}}
  line_no=${4:-${BASH_LINENO[0]:-0}}
  __fw_logger "ERROR" "$msg" "$script_name" "$func_name" "$line_no"
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
        if [[ "$gr_radp_log_debug" == 'true' ]]; then
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
      if [[ "$gr_radp_log_debug" == 'true' ]]; then
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
