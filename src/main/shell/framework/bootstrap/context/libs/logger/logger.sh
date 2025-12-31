#!/usr/bin/env bash
set -e

#######################################
# 根据日志级别返回对应的颜色代码
# Globals:
#   gr_radp_log_color_debug - DEBUG 级别颜色配置(支持颜色名称或代码)
#   gr_radp_log_color_info - INFO 级别颜色配置(支持颜色名称或代码)
#   gr_radp_log_color_warn - WARN 级别颜色配置(支持颜色名称或代码)
#   gr_radp_log_color_error - ERROR 级别颜色配置(支持颜色名称或代码)
# Arguments:
#   1 - log_level: 日志级别 (DEBUG, INFO, WARN, ERROR)
# Outputs:
#   颜色代码字符串
# Returns:
#   0 - Success
#######################################
__fw_get_log_level_color() {
  local -u log_level=${1:-}
  local color_config color_code
  case "$log_level" in
  DEBUG) color_config="${gr_radp_log_color_debug:-faint}" ;;
  INFO) color_config="${gr_radp_log_color_info:-green}" ;;
  WARN) color_config="${gr_radp_log_color_warn:-yellow}" ;;
  ERROR) color_config="${gr_radp_log_color_error:-red}" ;;
  *)
    echo -e "\033[0m"
    return
    ;; # 默认/重置
  esac
  # 转换颜色名称或直接使用数字代码
  color_code=$(__fw_color_name_to_code "$color_config")
  echo -e "\033[${color_code}m"
}

#######################################
# 将颜色名称转换为 ANSI 颜色代码
# 支持的颜色名称:
#   black, red, green, yellow, blue, magenta, cyan, white
#   faint (灰色), default (默认色)
#   或直接使用数字颜色代码 (如 31, 32, 90 等)
# Arguments:
#   1 - color_name: 颜色名称或代码
# Outputs:
#   ANSI 颜色代码数字
#######################################
__fw_color_name_to_code() {
  local color_name=${1:-default}
  case "${color_name,,}" in
  black) echo "30" ;;
  red) echo "31" ;;
  green) echo "32" ;;
  yellow) echo "33" ;;
  blue) echo "34" ;;
  magenta) echo "35" ;;
  cyan) echo "36" ;;
  white) echo "37" ;;
  faint) echo "90" ;; # 亮黑/灰色
  default) echo "0" ;;
  # 如果是数字，直接返回
  [0-9]*) echo "$color_name" ;;
  *) echo "0" ;;
  esac
}

#######################################
# 为文本添加颜色
# Arguments:
#   1 - text: 要着色的文本
#   2 - color_code: ANSI 颜色代码
# Outputs:
#   带颜色的文本
#######################################
__fw_colorize() {
  local text=${1:-}
  local color_code=${2:-0}
  if [[ "$color_code" == "0" || -z "$color_code" ]]; then
    echo "$text"
  else
    echo -e "\033[${color_code}m${text}\033[0m"
  fi
}

#######################################
# 解析并处理 %clr(...){color} 语法
# 支持的语法:
#   %clr(text){color} - 为 text 应用指定颜色
#   %clr(text) - 为 text 应用日志级别对应的颜色
# Arguments:
#   1 - text: 包含 %clr 语法的文本
#   2 - log_level: 当前日志级别 (用于 %clr(text) 无颜色参数时)
#   3 - colorize: 是否着色 (true/false)
# Outputs:
#   处理后的文本
#######################################
__fw_parse_clr_syntax() {
  local text=${1:-}
  local log_level=${2:-INFO}
  local colorize=${3:-false}

  # 定义正则表达式
  local regex_with_color='%clr\(([^)]*)\)\{([^}]*)\}'
  local regex_without_color='%clr\(([^)]*)\)'

  if [[ "$colorize" != "true" ]]; then
    # 不着色时，移除所有 %clr 语法，只保留内容
    # 处理 %clr(content){color} 格式
    while [[ "$text" =~ $regex_with_color ]]; do
      local full_match="${BASH_REMATCH[0]}"
      local content="${BASH_REMATCH[1]}"
      text="${text//$full_match/$content}"
    done
    # 处理 %clr(content) 格式（无颜色参数）
    while [[ "$text" =~ $regex_without_color ]]; do
      local full_match="${BASH_REMATCH[0]}"
      local content="${BASH_REMATCH[1]}"
      text="${text//$full_match/$content}"
    done
    echo "$text"
    return
  fi

  # 着色模式
  # 获取日志级别对应的默认颜色（支持颜色名称或数字代码）
  local level_color_config level_color
  case "${log_level^^}" in
  DEBUG) level_color_config="${gr_radp_log_color_debug:-blue}" ;;
  INFO) level_color_config="${gr_radp_log_color_info:-green}" ;;
  WARN) level_color_config="${gr_radp_log_color_warn:-yellow}" ;;
  ERROR) level_color_config="${gr_radp_log_color_error:-red}" ;;
  *) level_color_config="default" ;;
  esac
  level_color=$(__fw_color_name_to_code "$level_color_config")

  # 处理 %clr(content){color} 格式
  while [[ "$text" =~ $regex_with_color ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local content="${BASH_REMATCH[1]}"
    local color_name="${BASH_REMATCH[2]}"
    local color_code
    color_code=$(__fw_color_name_to_code "$color_name")
    local colored_content
    colored_content=$(__fw_colorize "$content" "$color_code")
    text="${text//$full_match/$colored_content}"
  done

  # 处理 %clr(content) 格式（使用日志级别颜色）
  while [[ "$text" =~ $regex_without_color ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local content="${BASH_REMATCH[1]}"
    local colored_content
    colored_content=$(__fw_colorize "$content" "$level_color")
    text="${text//$full_match/$colored_content}"
  done

  echo "$text"
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
#   %clr(text){color} - 为 text 应用指定颜色
#   %clr(text) - 为 text 应用日志级别对应的颜色
# Globals:
#   None
# Arguments:
#   1 - pattern: 日志格式模式
#   2 - log_level: 日志级别
#   3 - message: 日志消息
#   4 - script_name: 脚本文件名
#   5 - func_name: 函数名
#   6 - line_no: 行号
#   7 - colorize: 是否着色 (true/false)，默认 false
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
  local colorize=${7:-false}

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

  # 处理 %clr 语法
  result=$(__fw_parse_clr_syntax "$result" "$log_level" "$colorize")

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
    # 控制台输出时着色 (colorize=true)，文件输出时不着色 (colorize=false)
    local formatted_console formatted_file
    formatted_console=$(__fw_format_log_message "$console_pattern" "$log_level" "$message" "$script_name" "$func_name" "$line_no" "true")
    formatted_file=$(__fw_format_log_message "$file_pattern" "$log_level" "$message" "$script_name" "$func_name" "$line_no" "false")

    # 输出到文件(fd3)和控制台(fd4)，不影响脚本返回值
    {
      echo -e "${formatted_file}" >&3 2>/dev/null || true
      echo -e "${formatted_console}" >&4 2>/dev/null || true
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
__fw_logger_setup() {
  local logfile="${gr_radp_log_file:?}"
  if [[ -z "$gr_log_file_path" ]]; then
    gr_log_file_path=$(dirname "$gr_radp_log_file")
    readonly gr_log_file_path
  fi
  if [[ -z "$gr_log_filename" ]]; then
    gr_log_filename=$(basename "$gr_radp_log_file")
    readonly gr_log_filename
  fi
  if [[ -z "$gr_log_rolling_path" ]]; then
    gr_log_rolling_path="$gr_log_file_path"/archived
    readonly gr_log_rolling_path
  fi
  local log_path="$gr_log_file_path"

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

#######################################
# 转换文件大小到字节
# 支持单位: B, KB, K, MB, M, GB, G
# Arguments:
#   1 - size_str: 带单位的文件大小字符串，如 '10M' 或 '1GB'
#   2 - target_unit: 目标单位（'B', 'KB', 'K', 'MB', 'M', 'GB', 'G'），默认为'B'
# Outputs:
#   转换后的文件大小
# Returns:
#   0 - Success
#   1 - Invalid unit
#######################################
__fw_transfer_filesize() {
  local size_str=${1:?'Missing size_str argument'}
  local target_unit=${2:-B}
  local base_size original_unit

  # 提取数字部分
  base_size=$(echo "$size_str" | sed -E 's/[^0-9]//g')
  # 提取并大写单位部分
  original_unit=$(echo "$size_str" | sed -E 's/[0-9]//g' | tr '[:lower:]' '[:upper:]')

  # 转换原始大小到字节
  local size_in_bytes
  case $original_unit in
  'K' | 'KB') size_in_bytes=$((base_size * 1024)) ;;
  'M' | 'MB') size_in_bytes=$((base_size * 1024 * 1024)) ;;
  'G' | 'GB') size_in_bytes=$((base_size * 1024 * 1024 * 1024)) ;;
  'B' | '') size_in_bytes=$base_size ;;
  *) return 1 ;;
  esac

  # 转换字节到目标单位
  local converted_size
  case $(echo "$target_unit" | tr '[:lower:]' '[:upper:]') in
  'B') converted_size=$size_in_bytes ;;
  'K' | 'KB') converted_size=$((size_in_bytes / 1024)) ;;
  'M' | 'MB') converted_size=$((size_in_bytes / 1024 / 1024)) ;;
  'G' | 'GB') converted_size=$((size_in_bytes / 1024 / 1024 / 1024)) ;;
  *) return 1 ;;
  esac

  echo "$converted_size"
}

#######################################
# 日志文件滚动归档
# 根据 rolling policy 配置，将日志文件归档到指定目录
# 归档路径格式:
#   - 支持 gzip 时: ${gr_log_rolling_path}/yyyyMMdd/${basename}.yyyyMMdd.i.log.gz
#   - 不支持 gzip 时: ${gr_log_rolling_path}/yyyyMMdd/${basename}.yyyyMMdd.i.log
# Globals:
#   gr_radp_log_rolling_policy_enabled - 是否启用滚动策略
#   gr_radp_log_rolling_policy_max_history - 最大保留天数
#   gr_radp_log_rolling_policy_total_size_cap - 总大小上限
#   gr_radp_log_rolling_policy_max_file_size - 单文件最大大小
#   gr_radp_log_file - 日志文件的绝对路径
#   gr_log_file_path - 日志文件所在目录
#   gr_log_filename - 日志文件名
#   gr_log_rolling_path - 归档日志根目录
# Arguments:
#   None
# Returns:
#   0 - Success
#######################################
__fw_logger_rolling() {
  # 检查是否启用滚动策略
  if [[ "${gr_radp_log_rolling_policy_enabled:-true}" != "true" ]]; then
    return 0
  fi

  local log_file="${gr_radp_log_file:?}"

  # 检查日志文件是否存在
  if [[ ! -f "$log_file" ]]; then
    return 0
  fi

  local log_basename="${gr_log_filename%.*}" # 去掉扩展名
  local log_ext="${gr_log_filename##*.}"     # 获取扩展名
  local rolling_path="$gr_log_rolling_path"
  local current_date
  current_date=$(date '+%Y%m%d')

  # 获取配置
  local max_file_size="${gr_radp_log_rolling_policy_max_file_size:-10MB}"
  local max_history="${gr_radp_log_rolling_policy_max_history:-7}"
  local total_size_cap="${gr_radp_log_rolling_policy_total_size_cap:-5GB}"

  # 转换文件大小为字节
  local max_size_bytes
  max_size_bytes=$(__fw_transfer_filesize "$max_file_size")

  # 获取当前日志文件大小和修改日期
  local file_size_bytes file_mod_date
  file_size_bytes=$(wc -c <"$log_file" 2>/dev/null | tr -d ' ')
  file_mod_date=$(date -r "$log_file" '+%Y%m%d' 2>/dev/null || stat -c '%Y' "$log_file" 2>/dev/null | xargs -I{} date -d @{} '+%Y%m%d' 2>/dev/null)

  # 判断是否需要归档
  local should_rotate=false
  if [[ $file_size_bytes -ge $max_size_bytes ]]; then
    should_rotate=true
  elif [[ -n "$file_mod_date" && "$file_mod_date" != "$current_date" ]]; then
    should_rotate=true
  fi

  # 执行归档
  if [[ "$should_rotate" == true ]]; then
    # 创建归档目录: archived/yyyyMMdd/
    local archive_dir="${rolling_path}/${current_date}"
    if [[ ! -d "$archive_dir" ]]; then
      mkdir -p "$archive_dir" 2>/dev/null || {
        radp_log_error "Failed to create archive directory '$archive_dir'."
        return 1
      }
    fi

    # 计算今天已经归档的日志文件数量来生成序号
    local count
    count=$(find "$archive_dir" -maxdepth 1 -type f -name "${log_basename}.${current_date}.*" 2>/dev/null | wc -l | tr -d ' ')
    ((count++)) || true

    # 检查 gzip 是否可用，决定是否压缩归档
    local archive_file archive_success=false
    if command -v gzip &>/dev/null; then
      # gzip 可用，压缩归档
      archive_file="${archive_dir}/${log_basename}.${current_date}.${count}.${log_ext}.gz"
      if gzip -c "$log_file" >"$archive_file" 2>/dev/null; then
        archive_success=true
      fi
    else
      # gzip 不可用，直接移动文件（不压缩）
      archive_file="${archive_dir}/${log_basename}.${current_date}.${count}.${log_ext}"
      if cp "$log_file" "$archive_file" 2>/dev/null; then
        archive_success=true
      fi
    fi

    # 归档成功后清空当前日志文件
    if [[ "$archive_success" == true ]]; then
      # 清空当前日志文件而不删除，保持文件描述符有效
      truncate -s 0 "$log_file" 2>/dev/null || : >"$log_file"
    fi
  fi

  # 清理超过 max-history 天数的旧日志目录
  __fw_cleanup_old_archives "$rolling_path" "$max_history"

  # 检查并清理超过 total-size-cap 的旧日志
  __fw_cleanup_by_size_cap "$rolling_path" "$total_size_cap"
}

#######################################
# 清理超过保留天数的旧归档日志
# Arguments:
#   1 - rolling_path: 归档根目录
#   2 - max_history: 最大保留天数
# Returns:
#   0 - Success
#######################################
__fw_cleanup_old_archives() {
  local rolling_path=${1:?'Missing rolling_path argument'}
  local max_history=${2:-7}

  if [[ ! -d "$rolling_path" ]]; then
    return 0
  fi

  # 查找并删除超过保留期限的旧日志目录(按日期目录)
  local cutoff_date
  # shellcheck disable=SC2086
  cutoff_date=$(date -v-${max_history}d '+%Y%m%d' 2>/dev/null || date -d "-${max_history} days" '+%Y%m%d' 2>/dev/null)

  if [[ -z "$cutoff_date" ]]; then
    return 0
  fi

  local dir_name dir_date
  for dir_name in "$rolling_path"/*/; do
    [[ -d "$dir_name" ]] || continue
    dir_date=$(basename "$dir_name")
    # 检查目录名是否为日期格式 (yyyyMMdd)
    if [[ "$dir_date" =~ ^[0-9]{8}$ && "$dir_date" < "$cutoff_date" ]]; then
      rm -rf "$dir_name" 2>/dev/null
    fi
  done
}

#######################################
# 根据总大小上限清理旧归档日志
# 从最旧的日志开始删除，直到总大小低于上限
# 支持清理压缩 (.gz) 和非压缩 (.log) 的归档文件
# Arguments:
#   1 - rolling_path: 归档根目录
#   2 - total_size_cap: 总大小上限 (如 5GB)
# Returns:
#   0 - Success
#######################################
__fw_cleanup_by_size_cap() {
  local rolling_path=${1:?'Missing rolling_path argument'}
  local total_size_cap=${2:-5GB}

  if [[ ! -d "$rolling_path" ]]; then
    return 0
  fi

  # 转换大小上限为字节
  local cap_bytes
  cap_bytes=$(__fw_transfer_filesize "$total_size_cap")

  # 计算当前归档目录总大小 (macOS 兼容)
  # macOS 的 du 不支持 -b 选项，使用 find + stat 来计算
  local current_size=0
  local file_size
  local file
  while IFS= read -r -d '' file; do
    file_size=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    ((current_size += file_size)) || true
  done < <(find "$rolling_path" -type f -print0 2>/dev/null)

  if [[ "$current_size" -le "$cap_bytes" ]]; then
    return 0
  fi

  # 获取所有归档文件，按修改时间排序（最旧的在前）
  # 同时匹配压缩 (.gz) 和非压缩 (.log) 的归档文件
  local -a old_files
  mapfile -t old_files < <(find "$rolling_path" -type f \( -name "*.gz" -o -name "*.log" \) -print0 2>/dev/null | xargs -0 ls -1tr 2>/dev/null)

  # 从最旧的文件开始删除，直到总大小低于上限
  local file
  for file in "${old_files[@]}"; do
    [[ -f "$file" ]] || continue
    if [[ "$current_size" -le "$cap_bytes" ]]; then
      break
    fi
    file_size=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    rm -f "$file" 2>/dev/null
    ((current_size -= file_size)) || true
  done

  # 清理空的日期目录
  find "$rolling_path" -type d -empty -delete 2>/dev/null || true
}

__main() {
  __fw_logger_setup
  __fw_logger_rolling
}

declare -g gr_log_file_path=${gr_log_file_path:-}
declare -g gr_log_filename=${gr_log_filename:-}
declare -g gr_log_rolling_path=${gr_log_rolling_path:-}
__main
