#!/usr/bin/env bats
# Test cases for logger.sh

setup() {
  # 获取项目根目录 - BATS_TEST_FILENAME 是相对于运行目录的路径
  # 当从项目根目录运行时，BATS_TEST_FILENAME = src/test/shell/logger.bats
  # 需要获取绝对路径
  local test_dir
  test_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$test_dir/../../.." && pwd)"
  LOGGER_FILE="$PROJECT_ROOT/src/main/shell/framework/bootstrap/context/libs/logger/logger.sh"

  # 创建临时目录
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_LOG_FILE="$TEST_TEMP_DIR/test.log"

  # 设置必要的全局变量
  export gr_radp_log_file="$TEST_LOG_FILE"
  export gr_radp_log_debug="false"
  export YAML_RADP_LOG_LEVEL="info"
  export YAML_RADP_LOG_PATTERN_CONSOLE="%d | %p %P | %t | %L:%F#%M | %m"
  export YAML_RADP_LOG_PATTERN_FILE="%d | %p %P | %t | %L:%F#%M | %m"

  # 只 source 日志函数部分，不执行 __main
  # 我们需要手动定义函数(增加行数以包含更多代码)
  # 文件现在有 731 行，source 到 720 行以包含所有函数定义(不包含 __main 及之后的代码)
  source <(sed -n '1,720p' "$LOGGER_FILE")
}

teardown() {
  # 清理临时目录
  if [[ -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# 辅助函数：在子 shell 中运行日志函数并捕获文件输出
run_logger_to_file() {
  local log_file="$1"
  shift
  (
    exec 3>"$log_file"
    exec 4>/dev/null
    "$@"
  )
}

#----------------------------------------------------------------------------------------------------------------------#
# __fw_get_log_level_color tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_get_log_level_color returns blue for DEBUG" {
  result=$(__fw_get_log_level_color "DEBUG")
  [[ "$result" == $'\033[34m' ]]
}

@test "__fw_get_log_level_color returns green for INFO" {
  result=$(__fw_get_log_level_color "INFO")
  [[ "$result" == $'\033[32m' ]]
}

@test "__fw_get_log_level_color returns yellow for WARN" {
  result=$(__fw_get_log_level_color "WARN")
  [[ "$result" == $'\033[33m' ]]
}

@test "__fw_get_log_level_color returns red for ERROR" {
  result=$(__fw_get_log_level_color "ERROR")
  [[ "$result" == $'\033[31m' ]]
}

@test "__fw_get_log_level_color returns reset for unknown level" {
  result=$(__fw_get_log_level_color "UNKNOWN")
  [[ "$result" == $'\033[0m' ]]
}

@test "__fw_get_log_level_color is case insensitive" {
  result=$(__fw_get_log_level_color "debug")
  [[ "$result" == $'\033[34m' ]]
}

@test "__fw_get_log_level_color uses custom color for DEBUG" {
  gr_radp_log_color_debug="35" # 紫色
  result=$(__fw_get_log_level_color "DEBUG")
  [[ "$result" == $'\033[35m' ]]
}

@test "__fw_get_log_level_color uses custom color for INFO" {
  gr_radp_log_color_info="34" # 蓝色
  result=$(__fw_get_log_level_color "INFO")
  [[ "$result" == $'\033[34m' ]]
}

@test "__fw_get_log_level_color uses custom color for WARN" {
  gr_radp_log_color_warn="31" # 红色
  result=$(__fw_get_log_level_color "WARN")
  [[ "$result" == $'\033[31m' ]]
}

@test "__fw_get_log_level_color uses custom color for ERROR" {
  gr_radp_log_color_error="35" # 紫色
  result=$(__fw_get_log_level_color "ERROR")
  [[ "$result" == $'\033[35m' ]]
}

@test "__fw_get_log_level_color falls back to default when custom color is empty" {
  gr_radp_log_color_debug=""
  result=$(__fw_get_log_level_color "DEBUG")
  [[ "$result" == $'\033[34m' ]]
}

@test "__fw_get_log_level_color supports color name 'red' for DEBUG" {
  gr_radp_log_color_debug="red"
  result=$(__fw_get_log_level_color "DEBUG")
  [[ "$result" == $'\033[31m' ]]
}

@test "__fw_get_log_level_color supports color name 'faint' for INFO" {
  gr_radp_log_color_info="faint"
  result=$(__fw_get_log_level_color "INFO")
  [[ "$result" == $'\033[90m' ]]
}

@test "__fw_get_log_level_color supports color name 'cyan' for WARN" {
  gr_radp_log_color_warn="cyan"
  result=$(__fw_get_log_level_color "WARN")
  [[ "$result" == $'\033[36m' ]]
}

@test "__fw_get_log_level_color supports color name 'magenta' for ERROR" {
  gr_radp_log_color_error="magenta"
  result=$(__fw_get_log_level_color "ERROR")
  [[ "$result" == $'\033[35m' ]]
}

@test "__fw_get_log_level_color supports mixed case color name" {
  gr_radp_log_color_debug="RED"
  result=$(__fw_get_log_level_color "DEBUG")
  [[ "$result" == $'\033[31m' ]]
}

@test "__fw_parse_clr_syntax uses color name config for level color" {
  gr_radp_log_color_info="cyan"
  result=$(__fw_parse_clr_syntax "%clr(hello)" "INFO" "true")
  [[ "$result" == $'\033[36mhello\033[0m' ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# __fw_format_log_message tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_format_log_message replaces %p with log level" {
  result=$(__fw_format_log_message "%p" "INFO" "test message" "test.sh" "test_func" "10")
  [[ "$result" == "INFO "* ]]
}

@test "__fw_format_log_message replaces %m with message" {
  result=$(__fw_format_log_message "%m" "INFO" "hello world" "test.sh" "test_func" "10")
  [[ "$result" == "hello world" ]]
}

@test "__fw_format_log_message replaces %F with script name" {
  result=$(__fw_format_log_message "%F" "INFO" "test" "my_script.sh" "test_func" "10")
  [[ "$result" == "my_script.sh" ]]
}

@test "__fw_format_log_message replaces %M with function name" {
  result=$(__fw_format_log_message "%M" "INFO" "test" "test.sh" "my_function" "10")
  [[ "$result" == "my_function" ]]
}

@test "__fw_format_log_message replaces %L with line number" {
  result=$(__fw_format_log_message "%L" "INFO" "test" "test.sh" "test_func" "42")
  [[ "$result" == "42" ]]
}

@test "__fw_format_log_message replaces %P with PID" {
  result=$(__fw_format_log_message "%P" "INFO" "test" "test.sh" "test_func" "10")
  # PID should be a number (formatted with padding)
  [[ "$result" =~ ^[0-9]+[[:space:]]*$ ]]
}

@test "__fw_format_log_message replaces %d with timestamp" {
  result=$(__fw_format_log_message "%d" "INFO" "test" "test.sh" "test_func" "10")
  # Timestamp format: YYYY-MM-DD HH:MM:SS (with optional .mmm for GNU date)
  [[ "$result" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{3})?$ ]]
}

@test "__fw_format_log_message handles complex pattern" {
  result=$(__fw_format_log_message "%p | %m" "ERROR" "something failed" "test.sh" "test_func" "10")
  [[ "$result" == "ERROR | something failed" ]]
}

@test "__fw_format_log_message handles empty message" {
  result=$(__fw_format_log_message "%p: %m" "INFO" "" "test.sh" "test_func" "10")
  [[ "$result" == "INFO : " ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# Log level filtering tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_logger filters DEBUG when level is INFO" {
  export gr_radp_log_level="info"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" __fw_logger "DEBUG" "debug message" "test.sh" "test_func" "10"

  # DEBUG 消息不应该被记录
  [[ ! -s "$TEST_LOG_FILE" ]]
}

@test "__fw_logger allows INFO when level is INFO" {
  export gr_radp_log_level="info"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" __fw_logger "INFO" "info message" "test.sh" "test_func" "10"

  # INFO 消息应该被记录
  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == *"info message"* ]]
}

@test "__fw_logger allows ERROR when level is INFO" {
  export gr_radp_log_level="info"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" __fw_logger "ERROR" "error message" "test.sh" "test_func" "10"

  # ERROR 消息应该被记录
  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == *"error message"* ]]
}

@test "__fw_logger allows DEBUG when gr_radp_log_debug is true" {
  export gr_radp_log_level="error"
  export gr_radp_log_debug="true"

  run_logger_to_file "$TEST_LOG_FILE" __fw_logger "DEBUG" "debug message" "test.sh" "test_func" "10"

  # DEBUG 消息应该被记录(因为 debug 模式开启)
  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == *"debug message"* ]]
}

@test "__fw_logger filters INFO when level is WARN" {
  export gr_radp_log_level="warn"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" __fw_logger "INFO" "info message" "test.sh" "test_func" "10"

  # INFO 消息不应该被记录
  [[ ! -s "$TEST_LOG_FILE" ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# Custom pattern tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_logger uses custom console pattern" {
  export gr_radp_log_level="info"
  export gr_radp_log_pattern_file="[%p] %m"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" __fw_logger "INFO" "custom pattern test" "test.sh" "test_func" "10"

  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == "[INFO ] custom pattern test" ]]
}

@test "__fw_logger uses simple pattern with only message" {
  export gr_radp_log_level="info"
  export gr_radp_log_pattern_file="%m"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" __fw_logger "INFO" "simple message" "test.sh" "test_func" "10"

  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == "simple message" ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# Public API tests
#----------------------------------------------------------------------------------------------------------------------#

@test "radp_log_info logs message correctly" {
  export gr_radp_log_level="info"
  export gr_radp_log_pattern_file="%p: %m"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" radp_log_info "test info message"

  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == "INFO : test info message" ]]
}

@test "radp_log_error logs message correctly" {
  export gr_radp_log_level="info"
  export gr_radp_log_pattern_file="%p: %m"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" radp_log_error "test error message"

  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == "ERROR: test error message" ]]
}

@test "radp_log_warn logs message correctly" {
  export gr_radp_log_level="info"
  export gr_radp_log_pattern_file="%p: %m"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" radp_log_warn "test warn message"

  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == "WARN : test warn message" ]]
}

@test "radp_log_debug is filtered when level is INFO" {
  export gr_radp_log_level="info"
  export gr_radp_log_pattern_file="%p: %m"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" radp_log_debug "test debug message"

  # DEBUG 消息不应该被记录
  [[ ! -s "$TEST_LOG_FILE" ]]
}

@test "radp_log_debug logs when level is DEBUG" {
  export gr_radp_log_level="debug"
  export gr_radp_log_pattern_file="%p: %m"
  export gr_radp_log_debug="false"

  run_logger_to_file "$TEST_LOG_FILE" radp_log_debug "test debug message"

  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == "DEBUG: test debug message" ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# %clr syntax tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_color_name_to_code converts color names correctly" {
  [[ $(__fw_color_name_to_code "black") == "30" ]]
  [[ $(__fw_color_name_to_code "red") == "31" ]]
  [[ $(__fw_color_name_to_code "green") == "32" ]]
  [[ $(__fw_color_name_to_code "yellow") == "33" ]]
  [[ $(__fw_color_name_to_code "blue") == "34" ]]
  [[ $(__fw_color_name_to_code "magenta") == "35" ]]
  [[ $(__fw_color_name_to_code "cyan") == "36" ]]
  [[ $(__fw_color_name_to_code "white") == "37" ]]
  [[ $(__fw_color_name_to_code "faint") == "90" ]]
  [[ $(__fw_color_name_to_code "default") == "0" ]]
}

@test "__fw_color_name_to_code handles numeric codes" {
  [[ $(__fw_color_name_to_code "31") == "31" ]]
  [[ $(__fw_color_name_to_code "90") == "90" ]]
}

@test "__fw_color_name_to_code is case insensitive" {
  [[ $(__fw_color_name_to_code "RED") == "31" ]]
  [[ $(__fw_color_name_to_code "Green") == "32" ]]
  [[ $(__fw_color_name_to_code "FAINT") == "90" ]]
}

@test "__fw_colorize adds color codes" {
  result=$(__fw_colorize "test" "31")
  [[ "$result" == $'\033[31mtest\033[0m' ]]
}

@test "__fw_colorize returns plain text for default color" {
  result=$(__fw_colorize "test" "0")
  [[ "$result" == "test" ]]
}

@test "__fw_parse_clr_syntax removes %clr when colorize is false" {
  result=$(__fw_parse_clr_syntax "%clr(hello){red} world" "INFO" "false")
  [[ "$result" == "hello world" ]]
}

@test "__fw_parse_clr_syntax removes %clr without color when colorize is false" {
  result=$(__fw_parse_clr_syntax "%clr(hello) world" "INFO" "false")
  [[ "$result" == "hello world" ]]
}

@test "__fw_parse_clr_syntax applies color when colorize is true" {
  result=$(__fw_parse_clr_syntax "%clr(hello){red}" "INFO" "true")
  [[ "$result" == $'\033[31mhello\033[0m' ]]
}

@test "__fw_parse_clr_syntax applies level color when no color specified" {
  # INFO level uses green (32)
  result=$(__fw_parse_clr_syntax "%clr(hello)" "INFO" "true")
  [[ "$result" == $'\033[32mhello\033[0m' ]]
}

@test "__fw_parse_clr_syntax handles multiple %clr in pattern" {
  result=$(__fw_parse_clr_syntax "%clr(a){red} %clr(b){blue}" "INFO" "false")
  [[ "$result" == "a b" ]]
}

@test "__fw_format_log_message handles %clr syntax with colorize true" {
  export gr_radp_log_level="info"
  result=$(__fw_format_log_message "%clr(%p){green}: %m" "INFO" "test message" "test.sh" "test_func" "10" "true")
  # 应该包含绿色的 INFO 和普通的消息
  [[ "$result" == *$'\033[32m'*"INFO"*$'\033[0m'*": test message" ]]
}

@test "__fw_format_log_message strips %clr syntax with colorize false" {
  export gr_radp_log_level="info"
  result=$(__fw_format_log_message "%clr(%p){green}: %m" "INFO" "test message" "test.sh" "test_func" "10" "false")
  [[ "$result" == "INFO : test message" ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# __fw_transfer_filesize tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_transfer_filesize converts KB to bytes" {
  result=$(__fw_transfer_filesize "10KB")
  [[ "$result" == "10240" ]]
}

@test "__fw_transfer_filesize converts MB to bytes" {
  result=$(__fw_transfer_filesize "10MB")
  [[ "$result" == "10485760" ]]
}

@test "__fw_transfer_filesize converts GB to bytes" {
  result=$(__fw_transfer_filesize "1GB")
  [[ "$result" == "1073741824" ]]
}

@test "__fw_transfer_filesize converts M shorthand to bytes" {
  result=$(__fw_transfer_filesize "5M")
  [[ "$result" == "5242880" ]]
}

@test "__fw_transfer_filesize converts K shorthand to bytes" {
  result=$(__fw_transfer_filesize "100K")
  [[ "$result" == "102400" ]]
}

@test "__fw_transfer_filesize handles lowercase units" {
  result=$(__fw_transfer_filesize "10mb")
  [[ "$result" == "10485760" ]]
}

@test "__fw_transfer_filesize converts bytes to KB" {
  result=$(__fw_transfer_filesize "10240B" "KB")
  [[ "$result" == "10" ]]
}

@test "__fw_transfer_filesize converts MB to KB" {
  result=$(__fw_transfer_filesize "1MB" "KB")
  [[ "$result" == "1024" ]]
}

@test "__fw_transfer_filesize handles plain number as bytes" {
  result=$(__fw_transfer_filesize "1024")
  [[ "$result" == "1024" ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# __fw_logger_rolling tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_logger_rolling does nothing when disabled" {
  export gr_radp_log_rolling_policy_enabled="false"
  export gr_radp_log_file="$TEST_LOG_FILE"
  export gr_log_file_path="$TEST_TEMP_DIR"
  export gr_log_filename="test.log"

  echo "test log content" >"$TEST_LOG_FILE"

  __fw_logger_rolling

  # 日志文件应该保持不变
  [[ -f "$TEST_LOG_FILE" ]]
  content=$(cat "$TEST_LOG_FILE")
  [[ "$content" == "test log content" ]]
}

@test "__fw_logger_rolling does nothing when log file does not exist" {
  export gr_radp_log_rolling_policy_enabled="true"
  export gr_radp_log_file="$TEST_TEMP_DIR/nonexistent.log"
  export gr_log_file_path="$TEST_TEMP_DIR"
  export gr_log_filename="nonexistent.log"

  # 不应该报错
  __fw_logger_rolling
}

@test "__fw_logger_rolling rotates file when size exceeds max" {
  export gr_radp_log_rolling_policy_enabled="true"
  export gr_radp_log_file="$TEST_LOG_FILE"
  export gr_log_file_path="$TEST_TEMP_DIR"
  export gr_log_filename="test.log"
  export gr_log_rolling_path="$TEST_TEMP_DIR/archived"
  export gr_radp_log_rolling_policy_max_file_size="100B"
  export gr_radp_log_rolling_policy_max_history="7"
  export gr_radp_log_rolling_policy_total_size_cap="5GB"

  # 创建一个超过 100 字节的日志文件
  dd if=/dev/zero bs=150 count=1 2>/dev/null | tr '\0' 'x' >"$TEST_LOG_FILE"

  __fw_logger_rolling

  # 日志文件应该被清空
  file_size=$(wc -c <"$TEST_LOG_FILE" | tr -d ' ')
  [[ "$file_size" == "0" ]]

  # 应该创建归档目录和文件
  local current_date
  current_date=$(date '+%Y%m%d')
  [[ -d "$TEST_TEMP_DIR/archived/$current_date" ]]

  # 应该有一个 .gz 归档文件
  archive_count=$(find "$TEST_TEMP_DIR/archived/$current_date" -name "*.gz" | wc -l | tr -d ' ')
  [[ "$archive_count" == "1" ]]
}

@test "__fw_logger_rolling creates correct archive filename format" {
  export gr_radp_log_rolling_policy_enabled="true"
  export gr_radp_log_file="$TEST_LOG_FILE"
  export gr_log_file_path="$TEST_TEMP_DIR"
  export gr_log_filename="test.log"
  export gr_log_rolling_path="$TEST_TEMP_DIR/archived"
  export gr_radp_log_rolling_policy_max_file_size="50B"
  export gr_radp_log_rolling_policy_max_history="7"
  export gr_radp_log_rolling_policy_total_size_cap="5GB"

  # 创建一个超过 50 字节的日志文件
  dd if=/dev/zero bs=100 count=1 2>/dev/null | tr '\0' 'x' >"$TEST_LOG_FILE"

  __fw_logger_rolling

  local current_date
  current_date=$(date '+%Y%m%d')

  # 检查归档文件名格式: test.yyyyMMdd.1.log.gz
  archive_file=$(find "$TEST_TEMP_DIR/archived/$current_date" -name "test.${current_date}.1.log.gz" -type f)
  [[ -n "$archive_file" ]]
}

@test "__fw_logger_rolling increments sequence number for multiple rotations" {
  export gr_radp_log_rolling_policy_enabled="true"
  export gr_radp_log_file="$TEST_LOG_FILE"
  export gr_log_file_path="$TEST_TEMP_DIR"
  export gr_log_filename="test.log"
  export gr_log_rolling_path="$TEST_TEMP_DIR/archived"
  export gr_radp_log_rolling_policy_max_file_size="50B"
  export gr_radp_log_rolling_policy_max_history="7"
  export gr_radp_log_rolling_policy_total_size_cap="5GB"

  local current_date
  current_date=$(date '+%Y%m%d')

  # 第一次归档
  dd if=/dev/zero bs=100 count=1 2>/dev/null | tr '\0' 'a' >"$TEST_LOG_FILE"
  __fw_logger_rolling

  # 第二次归档
  dd if=/dev/zero bs=100 count=1 2>/dev/null | tr '\0' 'b' >"$TEST_LOG_FILE"
  __fw_logger_rolling

  # 应该有两个归档文件
  archive_count=$(find "$TEST_TEMP_DIR/archived/$current_date" -name "*.gz" | wc -l | tr -d ' ')
  [[ "$archive_count" == "2" ]]

  # 检查序号
  [[ -f "$TEST_TEMP_DIR/archived/$current_date/test.${current_date}.1.log.gz" ]]
  [[ -f "$TEST_TEMP_DIR/archived/$current_date/test.${current_date}.2.log.gz" ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# __fw_cleanup_old_archives tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_cleanup_old_archives does nothing when directory does not exist" {
  __fw_cleanup_old_archives "$TEST_TEMP_DIR/nonexistent" 7
  # 不应该报错
}

@test "__fw_cleanup_old_archives removes old date directories" {
  local rolling_path="$TEST_TEMP_DIR/archived"
  mkdir -p "$rolling_path"

  # 创建一些日期目录
  local old_date new_date
  # 使用 macOS 兼容的日期计算
  old_date=$(date -v-10d '+%Y%m%d' 2>/dev/null || date -d "-10 days" '+%Y%m%d')
  new_date=$(date '+%Y%m%d')

  mkdir -p "$rolling_path/$old_date"
  mkdir -p "$rolling_path/$new_date"
  touch "$rolling_path/$old_date/test.log.gz"
  touch "$rolling_path/$new_date/test.log.gz"

  # 清理超过 7 天的归档
  __fw_cleanup_old_archives "$rolling_path" 7

  # 旧目录应该被删除
  [[ ! -d "$rolling_path/$old_date" ]]
  # 新目录应该保留
  [[ -d "$rolling_path/$new_date" ]]
}

@test "__fw_cleanup_old_archives keeps directories within retention period" {
  local rolling_path="$TEST_TEMP_DIR/archived"
  mkdir -p "$rolling_path"

  # 创建一个 3 天前的目录(在 7 天保留期内)
  local recent_date
  recent_date=$(date -v-3d '+%Y%m%d' 2>/dev/null || date -d "-3 days" '+%Y%m%d')

  mkdir -p "$rolling_path/$recent_date"
  touch "$rolling_path/$recent_date/test.log.gz"

  __fw_cleanup_old_archives "$rolling_path" 7

  # 目录应该保留
  [[ -d "$rolling_path/$recent_date" ]]
}

#----------------------------------------------------------------------------------------------------------------------#
# __fw_cleanup_by_size_cap tests
#----------------------------------------------------------------------------------------------------------------------#

@test "__fw_cleanup_by_size_cap does nothing when directory does not exist" {
  __fw_cleanup_by_size_cap "$TEST_TEMP_DIR/nonexistent" "5GB"
  # 不应该报错
}

@test "__fw_cleanup_by_size_cap does nothing when under size cap" {
  local rolling_path="$TEST_TEMP_DIR/archived"
  local current_date
  current_date=$(date '+%Y%m%d')
  mkdir -p "$rolling_path/$current_date"

  # 创建一个小文件
  echo "small content" | gzip >"$rolling_path/$current_date/test.log.gz"

  __fw_cleanup_by_size_cap "$rolling_path" "1MB"

  # 文件应该保留
  [[ -f "$rolling_path/$current_date/test.log.gz" ]]
}

@test "__fw_cleanup_by_size_cap removes old files when over size cap" {
  local rolling_path="$TEST_TEMP_DIR/archived"
  local current_date
  current_date=$(date '+%Y%m%d')
  mkdir -p "$rolling_path/$current_date"

  # 创建多个较大的文件(使用随机数据避免 gzip 压缩太多)
  # 每个文件约 1KB
  dd if=/dev/urandom bs=1024 count=1 2>/dev/null >"$rolling_path/$current_date/test1.log.gz"
  sleep 1 # 确保文件有不同的修改时间
  dd if=/dev/urandom bs=1024 count=1 2>/dev/null >"$rolling_path/$current_date/test2.log.gz"
  sleep 1
  dd if=/dev/urandom bs=1024 count=1 2>/dev/null >"$rolling_path/$current_date/test3.log.gz"

  # 设置一个较小的大小上限 (1.5KB，应该只能保留 1-2 个文件)
  __fw_cleanup_by_size_cap "$rolling_path" "1536B"

  # 应该删除一些文件(总大小约 3KB，上限 1.5KB，应该删除至少 1 个)
  remaining_count=$(find "$rolling_path" -name "*.gz" -type f | wc -l | tr -d ' ')
  [[ "$remaining_count" -lt "3" ]]
}
