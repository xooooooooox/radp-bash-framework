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
# 解析 YAML 内部引用，将 ${yaml.path.key} 格式的引用展开为实际值
# 例如: ${radp.fw.user.extend.path}/lib -> ../../extend/lib
# Globals:
#   None
# Arguments:
#   1 - vars_map_name: 包含所有 YAML 变量的关联数组名(会被原地修改)
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_resolve_yaml_references() {
  local -n __vars__=${1:?'Missing vars_map_name argument'}

  local max_iterations=10
  local iteration=0
  local has_unresolved=true

  # 多次迭代以处理嵌套引用
  while [[ "$has_unresolved" == true && $iteration -lt $max_iterations ]]; do
    has_unresolved=false
    iteration=$((iteration + 1))

    local key value
    for key in "${!__vars__[@]}"; do
      value="${__vars__[$key]}"

      # 检查是否包含 ${...} 格式的引用(YAML 内部引用格式)
      if [[ "$value" =~ \$\{([a-zA-Z0-9._-]+)\} ]]; then
        local new_value="$value"

        # 使用循环处理同一个值中的多个引用
        while [[ "$new_value" =~ \$\{([a-zA-Z0-9._-]+)\} ]]; do
          local ref_path="${BASH_REMATCH[1]}"
          # 将点分隔的路径转换为 YAML_* 变量名格式
          # 例如: radp.fw.user.extend.path -> YAML_RADP_FW_USER_EXTEND_PATH
          local ref_var_name
          ref_var_name="YAML_$(echo "$ref_path" | tr '[:lower:].' '[:upper:]_' | tr '-' '_')"

          # 查找引用的值
          if [[ -n "${__vars__[$ref_var_name]:-}" ]]; then
            local ref_value="${__vars__[$ref_var_name]}"
            # 替换引用为实际值
            new_value="${new_value//\$\{$ref_path\}/$ref_value}"
          else
            # 引用的变量不存在，跳出循环避免无限循环
            break
          fi
        done

        # 如果值发生了变化，更新并标记可能还有未解析的引用
        if [[ "$new_value" != "$value" ]]; then
          __vars__["$key"]="$new_value"
          # 检查新值是否还包含引用
          if [[ "$new_value" =~ \$\{([a-zA-Z0-9._-]+)\} ]]; then
            has_unresolved=true
          fi
        fi
      fi
    done
  done
}

#######################################
# 将关联数组中的变量导出为全局只读变量
# 支持环境变量展开，例如 $HOME 会被替换为实际路径
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

  local key value expanded_value
  for key in "${!__vars_map__[@]}"; do
    value="${__vars_map__[$key]}"
    # 展开环境变量，例如 $HOME -> /Users/username
    # 使用 eval echo 安全地展开变量引用
    expanded_value=$(eval echo "\"$value\"" 2>/dev/null) || expanded_value="$value"
    # 使用 declare -g 声明全局变量
    # shellcheck disable=SC2086
    declare -g $key="$expanded_value"
  done
}

#######################################
# 从 YAML 变量名生成对应的 shell 变量名
# 例如: YAML_RADP_USER_CONFIG_EXTEND_MY_VAR -> gr_radp_user_config_extend_my_var
# Globals:
#   None
# Arguments:
#   1 - yaml_var_name: YAML 变量名 (如 YAML_RADP_USER_CONFIG_EXTEND_MY_VAR)
# Outputs:
#   转换后的 shell 变量名
# Returns:
#   0 - Success
#######################################
__fw_yaml_var_to_shell_var() {
  local yaml_var_name=${1:?'Missing yaml_var_name argument'}
  # 移除 YAML_ 前缀，转换为小写，添加 gr_ 前缀
  echo "gr_$(echo "${yaml_var_name#YAML_}" | tr '[:upper:]' '[:lower:]')"
}

#######################################
# 从 YAML 变量名生成对应的环境变量名
# 例如: YAML_RADP_USER_CONFIG_EXTEND_MY_VAR -> GX_RADP_USER_CONFIG_EXTEND_MY_VAR
# Globals:
#   None
# Arguments:
#   1 - yaml_var_name: YAML 变量名 (如 YAML_RADP_USER_CONFIG_EXTEND_MY_VAR)
# Outputs:
#   转换后的环境变量名
# Returns:
#   0 - Success
#######################################
__fw_yaml_var_to_env_var() {
  local yaml_var_name=${1:?'Missing yaml_var_name argument'}
  # 将 YAML_ 前缀替换为 GX_ 前缀
  echo "GX_${yaml_var_name#YAML_}"
}

#######################################
# 生成用户配置文件 config.sh 的内容
# 当 radp.user.config.automap=true 时，自动将 radp.extend.*
# 下的 YAML 配置映射为 shell 变量声明 YAML_RADP_EXTEND_*
# Globals:
#   gr_fw_user_config_file - 用户配置文件路径
# Arguments:
#   1 - vars_map_name: 包含所有 YAML 变量的关联数组名
# Outputs:
#   None (直接写入 config.sh 文件)
# Returns:
#   0 - Success
#######################################
__fw_generate_user_config() {
  local -n __all_vars__=${1:?'Missing vars_map_name argument'}

  local config_content="#!/usr/bin/env bash
set -e

########################################################################################################################
###
# User configurable vars (auto-generated from YAML)
# 优先级: 环境变量(GX_*) > YAML(YAML_*) > 默认值
# 此文件由 automap 功能自动生成，请勿手动编辑
########################################################################################################################
"

  local key shell_var env_var value
  local has_extend_vars=false

  # 遍历所有变量，筛选出 YAML_RADP_EXTEND_* 前缀的变量
  for key in "${!__all_vars__[@]}"; do
    if [[ "$key" == YAML_RADP_EXTEND_* ]]; then
      has_extend_vars=true
      shell_var=$(__fw_yaml_var_to_shell_var "$key")
      env_var=$(__fw_yaml_var_to_env_var "$key")
      value="${__all_vars__[$key]}"

      # 生成 declare 语句，格式与 framework_config.sh 一致
      config_content+="declare -gr ${shell_var}=\"\${${env_var}:-\${${key}:-${value}}}\""
      config_content+=$'\n'
    fi
  done

  # 写入文件：有 extend 变量时写入完整内容，否则写入空模板
  if [[ "$has_extend_vars" == true ]]; then
    echo "$config_content" >"$gr_fw_user_config_file"
  else
    # 没有 extend 变量时，重置为空模板(清空之前可能存在的内容)
    cat >"$gr_fw_user_config_file" <<'EOF'
#!/usr/bin/env bash
set -e

########################################################################################################################
###
# User configurable vars (auto-generated from YAML)
# 优先级: 环境变量(GX_*) > YAML(YAML_*) > 默认值
# 此文件由 automap 功能自动生成，请勿手动编辑
########################################################################################################################
EOF
  fi
}

__fw_autoconfigure() {
  # shellcheck source=../../../../config/framework_config.sh
  __fw_source_scripts "$gr_fw_config_file"

  # 当 automap 启用时，自动生成 config.sh
  if [[ "${gr_radp_fw_user_config_automap:-false}" == "true" ]]; then
    # 需要传入最终合并后的变量，这里使用全局变量 gw_final_yaml_vars
    if [[ ${#gw_final_yaml_vars[@]} -gt 0 ]]; then
      if [[ "$gr_fw_user_config_path_exists" == "true" ]]; then
        __fw_generate_user_config gw_final_yaml_vars
        # include use config.sh
        __fw_source_scripts "$gr_fw_user_config_file"
        if [[ "$gr_radp_fw_log_console_enabled" == 'true' && "$gr_radp_fw_log_debug" == 'true' && "$gr_radp_fw_log_level" == 'debug' ]]; then
          echo "User config path '$gr_fw_user_config_path'"
        fi
      fi
    fi
  fi
}

#######################################
# 初始化用户配置路径状态
# 检查 user config path 是否存在，设置 gr_fw_user_config_path_exists 标志
# Globals:
#   gr_fw_user_config_path - 用户配置路径
#   gr_fw_user_config_path_exists - (写入) 用户配置路径是否存在的标志
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_init_user_config_path_status() {
  if [[ -d "$gr_fw_user_config_path" ]]; then
    gr_fw_user_config_path_exists=true
    readonly gr_fw_user_config_path_exists
  fi
}

#######################################
# 加载并合并基础配置(framework + user)
# 1) 解析 framework_config.yaml
# 2) 如果用户配置路径存在，解析 user config.yaml 并合并
# 3) 解析 YAML 内部引用并导出变量
# Globals:
#   gr_fw_yaml_config_file - framework yaml 配置文件路径
#   gr_fw_user_yaml_config_file - user yaml 配置文件路径
#   gr_fw_user_config_path_exists - 用户配置路径是否存在
# Arguments:
#   1 - result_var_name: 用于存储合并结果的关联数组变量名
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_load_and_merge_base_configs() {
  local -n __result__=${1:?'Missing result_var_name argument'}

  # step1: framework_config.yaml -> YAML_* var
  local -A fw_yaml_vars=()
  __fw_yaml_to_env_vars "$gr_fw_yaml_config_file" fw_yaml_vars

  if [[ "$gr_fw_user_config_path_exists" == true ]]; then
    # step2: user config.yaml -> YAML_* var
    local -A user_yaml_vars=()
    __fw_yaml_to_env_vars "$gr_fw_user_yaml_config_file" user_yaml_vars

    # step3: merge(fw_yaml union user_yaml), user_yaml override fw_yaml
    __fw_merge_env_vars fw_yaml_vars user_yaml_vars __result__
  else
    # user config path 不存在，直接使用 framework 配置
    local key
    for key in "${!fw_yaml_vars[@]}"; do
      __result__["$key"]="${fw_yaml_vars[$key]}"
    done
  fi

  # 解析 YAML 内部引用，如 ${radp.fw.user.extend.path}
  __fw_resolve_yaml_references __result__

  # 导出合并后的变量，以便后续可以使用 YAML_RADP_ENV
  __fw_export_yaml_vars __result__
}

#######################################
# 初始化环境变量 gr_radp_env
# 优先级: GX_RADP_ENV > YAML_RADP_ENV > 空
# Globals:
#   gr_radp_env - (写入) 当前环境标识
#   GX_RADP_ENV - 环境变量覆盖
#   YAML_RADP_ENV - YAML 配置中的环境标识
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_init_radp_env() {
  gr_radp_env="${GX_RADP_ENV:-${YAML_RADP_ENV:-}}"
  readonly gr_radp_env
}

#######################################
# 加载环境特定配置并合并到最终配置
# 根据 gr_radp_env 加载对应的 config-{env}.yaml 文件
# 如果 env=default, 则无需加载 env 配置
# Globals:
#   gr_fw_user_config_path - 用户配置路径
#   gr_fw_user_config_filename - 用户配置文件名
#   gr_fw_user_config_path_exists - 用户配置路径是否存在
#   gr_radp_env - 当前环境标识
#   gw_final_yaml_vars - (写入) 最终合并后的 YAML 变量
# Arguments:
#   1 - merged_vars_name: 已合并的基础配置关联数组变量名
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_load_env_specific_config() {
  local -n __merged__=${1:?'Missing merged_vars_name argument'}

  # 使用全局关联数组，以便 __fw_autoconfigure 可以访问
  declare -gA gw_final_yaml_vars=()

  if [[ "$gr_fw_user_config_path_exists" == true && -n "$gr_radp_env" && "$gr_radp_env" != "default" ]]; then
    # 构建环境特定配置文件路径: config-dev.yaml, config-prod.yaml 等
    local env_config_file="${gr_fw_user_config_path}/${gr_fw_user_config_filename}-${gr_radp_env}.yaml"

    local -A env_yaml_vars=()
    __fw_yaml_to_env_vars "$env_config_file" env_yaml_vars

    # merge(merged union env), env override merged
    __fw_merge_env_vars __merged__ env_yaml_vars gw_final_yaml_vars

    # 解析 YAML 内部引用
    __fw_resolve_yaml_references gw_final_yaml_vars

    # 导出最终合并后的变量
    __fw_export_yaml_vars gw_final_yaml_vars
  else
    # user config path 不存在或没有环境特定配置，直接使用 merged_vars 作为最终配置
    local key
    for key in "${!__merged__[@]}"; do
      gw_final_yaml_vars["$key"]="${__merged__[$key]}"
    done
    # merged_vars 已经导出过了，gw_final_yaml_vars 内容相同，无需再次导出
  fi
}

#######################################
# 解析 yaml 配置文件, 并注入全局变量
# 1) 使用 yq 解析 framework/user yaml，按优先级合并为最终配置
# 2) 将 yaml 配置转换为 `YAML_*` 形式的变量(类似 Spring Boot ENVIRONMENT)
# 3) YAML配置文件优先级: config-[env].yaml > config.yaml > framework_config.yaml
# Globals:
#   gr_fw_yaml_config_file - framework yaml config
#   gr_fw_config_file - finally framework config
#   gr_fw_user_yaml_config_file - user yaml config
#   gr_fw_user_config_file - finally user config
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__main() {
  # 1. 初始化用户配置路径状态
  __fw_init_user_config_path_status

  # 2. 加载并合并基础配置(framework + user)
  local -A merged_vars=()
  __fw_load_and_merge_base_configs merged_vars

  # 3. 初始化环境变量
  __fw_init_radp_env

  # 4. 加载环境特定配置并生成最终配置
  __fw_load_env_specific_config merged_vars

  # 5. 执行自动配置
  __fw_autoconfigure
}

declare -g gr_radp_env=${gr_radp_env:-}
declare -g gr_fw_user_config_path_exists=${gr_fw_user_config_path_exists:-false}
#----------------------------------------------------------------------------------------------------------------------#
declare -gr gr_fw_config_path="$gr_fw_root_path"/config
declare -gr gr_fw_config_filename=framework_config
declare -gr gr_fw_config_file="$gr_fw_config_path"/"$gr_fw_config_filename".sh
declare -gr gr_fw_yaml_config_file="$gr_fw_config_path"/"$gr_fw_config_filename".yaml
declare -gr gr_fw_banner_file="$gr_fw_config_path"/banner.txt

declare -g gr_fw_user_config_path
gr_fw_user_config_path="$(
  path=""
  if [[ -n "${GX_RADP_FW_USER_CONFIG_PATH:-}" ]]; then
    path="$GX_RADP_FW_USER_CONFIG_PATH"
  elif [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    path="${XDG_CONFIG_HOME%/}/radp_bash"
  else
    # Fallback to user's home config directory (always writable)
    path="$HOME/.config/radp_bash"
  fi
  if [[ "$path" == "~" || "$path" == "~/"* ]]; then
    path="${path/#\~/$HOME}"
  fi
  if [[ "$path" != /* ]]; then
    path="$(pwd)/$path"
  fi
  __fw_normalize_path "$path"
)"
readonly gr_fw_user_config_path
declare -gr gr_fw_user_config_filename="${GX_RADP_FW_USER_CONFIG_FILENAME:-config}"
declare -gr gr_fw_user_config_file="$gr_fw_user_config_path"/"$gr_fw_user_config_filename".sh
declare -gr gr_fw_user_yaml_config_file="$gr_fw_user_config_path"/"$gr_fw_user_config_filename".yaml

__main "$@"
