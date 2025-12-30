#!/usr/bin/env bash
set -e
########################################################################################################################
###
# framework predefined configurable vars
# 优先级: 环境变量（GX_*） > YAML（YAML_*） > 默认值
########################################################################################################################

# shellcheck source=../context/vars/global_vars.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
declare -gr gr_radp_env="${GX_RADP_ENV:-${YAML_RADP_ENV:-default}}"
#--------------------------------------------- framework config -------------------------------------------------------#
declare -gr gr_radp_framework_config_path="${GX_RADP_FRAMEWORK_CONFIG_PATH:-${YAML_RADP_FRAMEWORK_CONFIG_PATH:-"${gr_fw_root_path}/config"}}"
declare -gr gr_radp_framework_config_filename="${GX_RADP_FRAMEWORK_CONFIG_FILENAME:-${YAML_RADP_FRAMEWORK_CONFIG_FILENAME:-framework_config.yaml}}"

#--------------------------------------------- logger config -------------------------------------------------------#
declare -gr gr_radp_log_debug="${GX_RADP_LOG_DEBUG:-${YAML_RADP_LOG_DEBUG:-false}}"
declare -gr gr_radp_log_level="${GX_RADP_LOG_LEVEL:-${YAML_RADP_LOG_LEVEL:-info}}"
declare -gr gr_radp_log_file="${GX_RADP_LOG_FILE:-${YAML_RADP_LOG_FILE:-"${HOME}/logs/radp_bash.log"}}"
declare -gr gr_radp_log_rolling_policy_enabled="${GX_RADP_LOG_ROLLING_POLICY_ENABLED:-${YAML_RADP_LOG_ROLLING_POLICY_ENABLED:-true}}"
declare -gr gr_radp_log_rolling_policy_max_history="${GX_RADP_LOG_ROLLING_POLICY_MAX_HISTORY:-${YAML_RADP_LOG_ROLLING_POLICY_MAX_HISTORY:-7}}"
declare -gr gr_radp_log_rolling_policy_total_size_cap="${GX_RADP_LOG_ROLLING_POLICY_TOTAL_SIZE_CAP:-${YAML_RADP_LOG_ROLLING_POLICY_TOTAL_SIZE_CAP:-5GB}}"
declare -gr gr_radp_log_rolling_policy_max_file_size="${GX_RADP_LOG_ROLLING_POLICY_MAX_FILE_SIZE:-${YAML_RADP_LOG_ROLLING_POLICY_MAX_FILE_SIZE:-10MB}}"
declare -gr gr_radp_log_pattern_console="${GX_RADP_LOG_PATTERN_CONSOLE:-${YAML_RADP_LOG_PATTERN_CONSOLE:-}}"
declare -gr gr_radp_log_pattern_file="${GX_RADP_LOG_PATTERN_FILE:-${YAML_RADP_LOG_PATTERN_FILE:-}}"

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#--------------------------------------------- user config ------------------------------------------------------------#
declare -gr gr_radp_user_config_automap="${GX_RADP_USER_CONFIG_AUTOMAP:-${YAML_RADP_USER_CONFIG_AUTOMAP:-false}}"
declare -gr gr_radp_user_config_path="${GX_RADP_USER_CONFIG_PATH:-${YAML_RADP_USER_CONFIG_PATH:-"$(dirname "${gr_fw_root_path}")/config"}}"
declare -gr gr_radp_user_config_filename="${GX_RADP_USER_CONFIG_FILENAME:-${YAML_RADP_USER_CONFIG_FILENAME:-config.yaml}}"
