#!/usr/bin/env bash
set -e
########################################################################################################################
###
# framework predefined configurable vars
# 优先级: 环境变量(GX_*) > YAML(YAML_*) > 默认值
########################################################################################################################

# shellcheck source=../bootstrap/context/vars/global_vars.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
declare -gr gr_radp_fw_banner_mode="${GX_RADP_FW_BANNER_MODE:-${YAML_RADP_FW_BANNER_MODE:-on}}"
#--------------------------------------------- logger config ----------------------------------------------------------#
declare -gr gr_radp_fw_log_debug="${GX_RADP_FW_LOG_DEBUG:-${YAML_RADP_FW_LOG_DEBUG:-false}}"
declare -gr gr_radp_fw_log_level="${GX_RADP_FW_LOG_LEVEL:-${YAML_RADP_FW_LOG_LEVEL:-info}}"
declare -gr gr_radp_fw_log_console_enabled="${GX_RADP_FW_LOG_CONSOLE_ENABLED:-${YAML_RADP_FW_LOG_CONSOLE_ENABLED:-true}}"
declare -gr gr_radp_fw_log_file_enabled="${GX_RADP_FW_LOG_FILE_ENABLED:-${YAML_RADP_FW_LOG_FILE_ENABLED:-true}}"
declare -gr gr_radp_fw_log_file_name="${GX_RADP_FW_LOG_FILE_NAME:-${YAML_RADP_FW_LOG_FILE_NAME:-"${HOME}/logs/radp/${gra_command_line[0]:-radp_bash}.log"}}"
# rolling policy
declare -gr gr_radp_fw_log_rolling_policy_enabled="${GX_RADP_FW_LOG_ROLLING_POLICY_ENABLED:-${YAML_RADP_FW_LOG_ROLLING_POLICY_ENABLED:-true}}"
declare -gr gr_radp_fw_log_rolling_policy_max_history="${GX_RADP_FW_LOG_ROLLING_POLICY_MAX_HISTORY:-${YAML_RADP_FW_LOG_ROLLING_POLICY_MAX_HISTORY:-7}}"
declare -gr gr_radp_fw_log_rolling_policy_total_size_cap="${GX_RADP_FW_LOG_ROLLING_POLICY_TOTAL_SIZE_CAP:-${YAML_RADP_FW_LOG_ROLLING_POLICY_TOTAL_SIZE_CAP:-5GB}}"
declare -gr gr_radp_fw_log_rolling_policy_max_file_size="${GX_RADP_FW_LOG_ROLLING_POLICY_MAX_FILE_SIZE:-${YAML_RADP_FW_LOG_ROLLING_POLICY_MAX_FILE_SIZE:-10MB}}"
declare -gr gr_radp_fw_log_pattern_console="${GX_RADP_FW_LOG_PATTERN_CONSOLE:-${YAML_RADP_FW_LOG_PATTERN_CONSOLE:-}}"
declare -gr gr_radp_fw_log_pattern_file="${GX_RADP_FW_LOG_PATTERN_FILE:-${YAML_RADP_FW_LOG_PATTERN_FILE:-}}"
# 日志级别颜色配置 (ANSI 颜色代码)
declare -gr gr_radp_fw_log_color_debug="${GX_RADP_FW_LOG_COLOR_DEBUG:-${YAML_RADP_FW_LOG_COLOR_DEBUG:-faint}}"
declare -gr gr_radp_fw_log_color_info="${GX_RADP_FW_LOG_COLOR_INFO:-${YAML_RADP_FW_LOG_COLOR_INFO:-green}}"
declare -gr gr_radp_fw_log_color_warn="${GX_RADP_FW_LOG_COLOR_WARN:-${YAML_RADP_FW_LOG_COLOR_WARN:-yellow}}"
declare -gr gr_radp_fw_log_color_error="${GX_RADP_FW_LOG_COLOR_ERROR:-${YAML_RADP_FW_LOG_COLOR_ERROR:-red}}"
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#--------------------------------------------- user config ------------------------------------------------------------#
declare -gr gr_radp_fw_user_config_automap="${GX_RADP_FW_USER_CONFIG_AUTOMAP:-${YAML_RADP_FW_USER_CONFIG_AUTOMAP:-false}}"
declare -g gr_radp_fw_user_lib_path
gr_radp_fw_user_lib_path="${GX_RADP_FW_USER_LIB_PATH:-${YAML_RADP_FW_USER_LIB_PATH:-}}"
[[ -n "$gr_radp_fw_user_lib_path" ]] && gr_radp_fw_user_lib_path="$(__fw_normalize_path "$gr_radp_fw_user_lib_path")"
readonly gr_radp_fw_user_lib_path
