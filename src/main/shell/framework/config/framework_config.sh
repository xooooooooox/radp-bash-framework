#!/usr/bin/env bash
set -e
########################################################################################################################
###
# framework predefined configurable vars
# 优先级: 环境变量（GX_*） > YAML（YAML_*） > 默认值
########################################################################################################################

# shellcheck source=../bootstrap/context/vars/global_vars.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#--------------------------------------------- logger config ----------------------------------------------------------#
declare -gr gr_radp_log_debug="${GX_RADP_LOG_DEBUG:-${YAML_RADP_LOG_DEBUG:-false}}"
declare -gr gr_radp_log_level="${GX_RADP_LOG_LEVEL:-${YAML_RADP_LOG_LEVEL:-info}}"
declare -gr gr_radp_log_file="${GX_RADP_LOG_FILE:-${YAML_RADP_LOG_FILE:-"${HOME}/logs/radp/${gra_command_line[0]:-radp_bash}.log"}}"
declare -gr gr_radp_log_rolling_policy_enabled="${GX_RADP_LOG_ROLLING_POLICY_ENABLED:-${YAML_RADP_LOG_ROLLING_POLICY_ENABLED:-true}}"
declare -gr gr_radp_log_rolling_policy_max_history="${GX_RADP_LOG_ROLLING_POLICY_MAX_HISTORY:-${YAML_RADP_LOG_ROLLING_POLICY_MAX_HISTORY:-7}}"
declare -gr gr_radp_log_rolling_policy_total_size_cap="${GX_RADP_LOG_ROLLING_POLICY_TOTAL_SIZE_CAP:-${YAML_RADP_LOG_ROLLING_POLICY_TOTAL_SIZE_CAP:-5GB}}"
declare -gr gr_radp_log_rolling_policy_max_file_size="${GX_RADP_LOG_ROLLING_POLICY_MAX_FILE_SIZE:-${YAML_RADP_LOG_ROLLING_POLICY_MAX_FILE_SIZE:-10MB}}"
declare -gr gr_radp_log_pattern_console="${GX_RADP_LOG_PATTERN_CONSOLE:-${YAML_RADP_LOG_PATTERN_CONSOLE:-}}"
declare -gr gr_radp_log_pattern_file="${GX_RADP_LOG_PATTERN_FILE:-${YAML_RADP_LOG_PATTERN_FILE:-}}"
# 日志级别颜色配置 (ANSI 颜色代码)
declare -gr gr_radp_log_color_debug="${GX_RADP_LOG_COLOR_DEBUG:-${YAML_RADP_LOG_COLOR_DEBUG:-faint}}"
declare -gr gr_radp_log_color_info="${GX_RADP_LOG_COLOR_INFO:-${YAML_RADP_LOG_COLOR_INFO:-green}}"
declare -gr gr_radp_log_color_warn="${GX_RADP_LOG_COLOR_WARN:-${YAML_RADP_LOG_COLOR_WARN:-yellow}}"
declare -gr gr_radp_log_color_error="${GX_RADP_LOG_COLOR_ERROR:-${YAML_RADP_LOG_COLOR_ERROR:-red}}"
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#--------------------------------------------- user config ------------------------------------------------------------#
declare -gr gr_radp_user_config_automap="${GX_RADP_USER_CONFIG_AUTOMAP:-${YAML_RADP_USER_CONFIG_AUTOMAP:-false}}"
