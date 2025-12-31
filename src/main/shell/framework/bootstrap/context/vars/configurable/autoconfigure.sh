#!/usr/bin/env bash
set -e

#######################################
# 将 YAML 文件解析为 YAML_* 形式的环境变量
# 使用 yq 将嵌套的 YAML 键转换为大写下划线分隔的变量名
# 例如: radp.log.debug -> YAML_RADP_LOG_DEBUG
# Globals:
#   None
# Arguments:
#   1 - yaml_file: YAML 配置文件绝对路径
#   2 - result_var_name: 用于存储结果的关联数组变量名
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed (file not found or yq error)
#######################################
__fw_yaml_to_env_vars() {
  local yaml_file=${1:?'Missing yaml_file argument'}
  local -n __result_map__=${2:?'Missing result_var_name argument'}

  if [[ ! -f "$yaml_file" ]]; then
    return 0 # 文件不存在时静默返回，不报错
  fi

  local key value
  # 使用 yq 将 YAML 转换为扁平化的 key=value 格式
  # 输出格式: path.to.key=value
  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    # 将点分隔的路径转换为大写下划线分隔，并添加 YAML_ 前缀
    # 例如: radp.log.debug -> YAML_RADP_LOG_DEBUG
    local var_name
    var_name="YAML_$(echo "$key" | tr '[:lower:].' '[:upper:]_' | tr '-' '_')"
    __result_map__["$var_name"]="$value"
  done < <(yq eval '.. | select(tag != "!!map" and tag != "!!seq") | (path | join(".")) + "=" + (. | tostring)' "$yaml_file" 2>/dev/null)
}

#######################################
# 合并两个关联数组，后者覆盖前者
# Globals:
#   None
# Arguments:
#   1 - base_var_name: 基础关联数组变量名
#   2 - override_var_name: 覆盖关联数组变量名
#   3 - result_var_name: 结果关联数组变量名
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_merge_env_vars() {
  local -n __base__=${1:?'Missing base_var_name argument'}
  local -n __override__=${2:?'Missing override_var_name argument'}
  local -n __merged__=${3:?'Missing result_var_name argument'}

  # 先复制 base 到 merged
  local key
  for key in "${!__base__[@]}"; do
    __merged__["$key"]="${__base__[$key]}"
  done

  # 用 override 覆盖
  for key in "${!__override__[@]}"; do
    __merged__["$key"]="${__override__[$key]}"
  done
}

#######################################
# 将关联数组中的变量导出为全局只读变量
# Globals:
#   None
# Arguments:
#   1 - vars_map_name: 关联数组变量名
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_export_yaml_vars() {
  local -n __vars_map__=${1:?'Missing vars_map_name argument'}

  local key value
  for key in "${!__vars_map__[@]}"; do
    value="${__vars_map__[$key]}"
    # 使用 declare -g 声明全局变量
    # shellcheck disable=SC2086
    declare -g $key="$value"
  done
}

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
  local -A fw_yaml_vars=()
  __fw_yaml_to_env_vars "$gr_fw_yaml_config_file" fw_yaml_vars

  # step2: user config.yaml -> global readonly YAML_* var
  local -A user_yaml_vars=()
  __fw_yaml_to_env_vars "$gr_user_yaml_config_file" user_yaml_vars

  # step3: merge(step1 union step2), if conflict step2 override step1 -> merged YAML_* var
  local -A merged_vars=()
  __fw_merge_env_vars fw_yaml_vars user_yaml_vars merged_vars

  # 先导出合并后的变量，以便 step4 可以使用 YAML_RADP_ENV
  __fw_export_yaml_vars merged_vars

  # step4: config-$YAML_RADP_ENV.yaml -> global readonly YAML_* var
  gr_radp_env="${GX_RADP_ENV:-${YAML_RADP_ENV:-}}"
  readonly gr_radp_env

  local -A env_yaml_vars=()
  if [[ -n "$gr_radp_env" ]]; then
    # 构建环境特定配置文件路径: config-dev.yaml, config-prod.yaml 等
    local env_config_file="${gr_user_config_path}/${gr_user_config_filename}-${gr_radp_env}.yaml"
    __fw_yaml_to_env_vars "$env_config_file" env_yaml_vars
  fi

  # step5: merge(step3 union step4), if conflict step4 override step3
  local -A final_vars=()
  __fw_merge_env_vars merged_vars env_yaml_vars final_vars

  # 导出最终合并后的变量
  __fw_export_yaml_vars final_vars

  # step6:
  __fw_autoconfigure
}

#----------------------------------------------------------------------------------------------------------------------#
declare -g gr_radp_env=${gr_radp_env:-}
declare -gr gr_fw_config_path="$gr_fw_root_path"/config
declare -gr gr_fw_config_filename=framework_config
declare -gr gr_fw_config_file="$gr_fw_config_path"/"$gr_fw_config_filename".sh
declare -gr gr_fw_yaml_config_file="$gr_fw_config_path"/"$gr_fw_config_filename".yaml

declare -gr gr_user_config_path="${GX_RADP_USER_CONFIG_PATH:-"$(dirname "${gr_fw_root_path}")/config"}"
declare -gr gr_user_config_filename="${GX_RADP_USER_CONFIG_FILENAME:-config}"
declare -gr gr_user_config_file="$gr_user_config_path"/"$gr_user_config_filename".sh
declare -gr gr_user_yaml_config_file="$gr_user_config_path"/"$gr_user_config_filename".yaml

__main "$@"
