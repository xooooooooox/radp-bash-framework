#!/usr/bin/env bash
set -e

__fw_autoconfigure() {
  # shellcheck source=../../../../config/framework_config.sh
  __fw_source_scripts "$gr_fw_config_file"

  # shellcheck source=../../../../../config/config.sh
  __fw_source_scripts "$gr_user_config_file"
}

#######################################
# 解析 yaml 配置文件, 并注入全局变量
# 1) 使用 yq 解析 framework/user yaml，按优先级合并为最终配置
# 2) 将 yaml 配置转换为 `YAML_*` 形式的变量(类似 Spring Boot ENVIRONMENT)
# 3) YAML配置文件优先级: config-[env].yaml > config.yaml > framework_config.yaml
# Globals:
#   gr_fw_yaml_config_file - framework yaml config
#   gr_fw_config_file - finally framework config
#   gr_user_yaml_config_file - user yaml config
#   gr_user_config_file - finally user config
# Arguments:
#
# Outputs:
#
# Returns:
#
#######################################
__main() {
  # step1: framework_config.yaml -> global readonly YAML_* var

  # step2: user config.yaml -> global readonly YAML_* var

  # step3: merge(step1 union step2), if conflict step2 override step1 -> merged YAML_* var

  # step4: config-$YAML_RADP_ENV.yaml -> global readonly YAML_* var
  gr_radp_env="${GX_RADP_ENV:-${YAML_RADP_ENV:-}}"
  readonly gr_radp_env

  # step5: merge(step3 union step4), if conflict step4 override step3

  # step6:
  __fw_autoconfigure
}

declare -g gr_radp_env=${gr_radp_env:-}
declare -gr gr_fw_config_path="$gr_fw_root_path"/config
declare -gr gr_fw_config_filename=framework_config
declare -gr gr_fw_config_file="$gr_fw_config_path"/"$gr_fw_config_filename".sh
declare -gr gr_fw_yaml_config_file="$gr_fw_config_path"/"$gr_fw_config_filename".yaml
declare -gr gr_user_config_path="${GX_RADP_USER_CONFIG_PATH:-"$(dirname "${gr_fw_root_path}")/config"}"
declare -gr gr_user_config_filename="${GX_RADP_USER_CONFIG_FILENAME:-config.yaml}"
declare -gr gr_user_config_file="$gr_user_config_path"/"$gr_user_config_filename".sh
declare -gr gr_user_yaml_config_file="$gr_user_config_path"/"$gr_user_config_filename".yaml
__main "$@"
