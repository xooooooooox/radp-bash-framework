#!/usr/bin/env bash
set -e

# TODO v1.0-2025/12/31: refactor

# auto_configurable 的职责：
# 1) 使用 yq 解析 framework/user yaml，按优先级合并为最终配置
# 2) 将配置转换为 `YAML_*` 形式的变量（类似 Spring Boot ENVIRONMENT）
# 3) source `framework_config.sh` 完成预定义 `gr_*` 声明
# 4) 处理 user 扩展：存在 `config.sh` 则 source；否则在 automap=true 时按 user yaml 生成

__fw_auto_configurable_warn() {
  local msg=${1:?}
  if command -v radp_log_warn >/dev/null 2>&1; then
    radp_log_warn "$msg"
  else
    echo "Warn: $msg" >&2
  fi
}

__fw_auto_configurable_error() {
  local msg=${1:?}
  if command -v radp_log_error >/dev/null 2>&1; then
    radp_log_error "$msg"
  else
    echo "Error: $msg" >&2
  fi
}

__fw_auto_configurable_require_cmd() {
  local cmd=${1:?}
  if ! command -v "$cmd" >/dev/null 2>&1; then
    __fw_auto_configurable_error "Required command '$cmd' not found. Please install it first. (macOS: brew install $cmd)"
    return 1
  fi
}

__fw_auto_configurable_key_to_yaml_var_name() {
  local key=${1:?}
  local s
  s=${key//./_}
  s=${s//-/_}
  s=${s^^}
  echo "YAML_${s}"
}

__fw_auto_configurable_key_to_gr_var_name() {
  local key=${1:?}
  local s
  s=${key//./_}
  s=${s//-/_}
  s=${s,,}
  # 确保变量名不以数字开头
  if [[ "$s" =~ ^[0-9] ]]; then
    s="cfg_${s}"
  fi
  echo "gr_${s}"
}

__fw_auto_configurable_parse_yaml_to_map() {
  local yaml_file=${1:?}
  local -n __nr_out_map__=${2:?}

  if [[ ! -f "$yaml_file" ]]; then
    return 0
  fi

  # 解析所有标量节点为 key\tvalue 的 TSV 行
  local key value
  while IFS=$'\t' read -r key value; do
    [[ -z "${key:-}" ]] && continue
    if [[ "${value:-}" == "null" ]]; then
      value=""
    fi
    __nr_out_map__["$key"]="$value"
  done < <(
    yq -r '.. | select(tag != "!!map" and tag != "!!seq") | [ (path | join(".")), (. | tostring) ] | @tsv' "$yaml_file"
  )
}

__fw_auto_configurable_apply_base_defaults() {
  local -n __nr_map__=${1:?}

  : "${gr_fw_root_path:?}"

  # 这些默认值用于：
  # 1) 占位符解析（例如 ${radp.framework.config.path}）
  # 2) 在 yaml 未给出时，仍能生成合理的 YAML_* 变量
  __nr_map__['radp.env']=${__nr_map__['radp.env']:-default}

  __nr_map__['radp.framework.config.path']=${__nr_map__['radp.framework.config.path']:-"${gr_fw_root_path}/config"}
  __nr_map__['radp.framework.config.filename']=${__nr_map__['radp.framework.config.filename']:-framework_config.yaml}

  __nr_map__['radp.user.config.automap']=${__nr_map__['radp.user.config.automap']:-false}
  __nr_map__['radp.user.config.path']=${__nr_map__['radp.user.config.path']:-"$(dirname "${gr_fw_root_path}")/config"}
  __nr_map__['radp.user.config.filename']=${__nr_map__['radp.user.config.filename']:-config.yaml}
}

__fw_auto_configurable_resolve_placeholders_in_value() {
  local value=${1-}
  local -n __nr_props__=${2:?}

  # 支持 $HOME 与 ${HOME}
  value=${value//\$HOME/${HOME}}

  # 支持 ${a.b.c} 形式的属性占位符（优先取 map，其次取环境变量）
  # 迭代替换，最多 20 次以避免循环引用导致死循环
  local i=0
  while [[ "$value" =~ \$\{([^}]+)\} ]]; do
    ((++i))
    if (( i > 20 )); then
      break
    fi
    local placeholder="${BASH_REMATCH[1]}"
    local token="${BASH_REMATCH[0]}"
    local repl=""

    if [[ -n "${__nr_props__["$placeholder"]+x}" ]]; then
      repl="${__nr_props__["$placeholder"]}"
    else
      # 仅当 placeholder 是合法环境变量名时才尝试间接展开
      if [[ "$placeholder" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        repl="${!placeholder-}"
      else
        repl=""
      fi
    fi

    value=${value/"$token"/"$repl"}
  done

  echo "$value"
}

__fw_auto_configurable_resolve_placeholders_in_map() {
  local map_name=${1:?}
  local -n __nr_map__=$map_name

  local changed=1 iter=0
  while (( changed )); do
    changed=0
    ((++iter))
    if (( iter > 20 )); then
      break
    fi

    local k old new
    for k in "${!__nr_map__[@]}"; do
      old=${__nr_map__["$k"]}
      new=$(__fw_auto_configurable_resolve_placeholders_in_value "$old" "$map_name")
      if [[ "$new" != "$old" ]]; then
        __nr_map__["$k"]="$new"
        changed=1
      fi
    done
  done
}

__fw_auto_configurable_export_yaml_vars() {
  local -n __nr_map__=${1:?}

  local key var_name
  for key in "${!__nr_map__[@]}"; do
    var_name=$(__fw_auto_configurable_key_to_yaml_var_name "$key")
    # 设置为全局变量（不要 local）
    printf -v "$var_name" '%s' "${__nr_map__["$key"]}"
    export "$var_name"
  done
}

__fw_auto_configurable_extract_predefined_yaml_vars() {
  local framework_config_sh=${1:?}
  local -n __nr_out_set__=${2:?}

  if [[ ! -f "$framework_config_sh" ]]; then
    return 0
  fi

  local token
  while IFS= read -r token; do
    [[ -z "${token:-}" ]] && continue
    __nr_out_set__["$token"]=1
  done < <(grep -oE 'YAML_[A-Z0-9_]+' "$framework_config_sh" | sort -u)
}

__fw_auto_configurable_yaml_filename_to_sh_filename() {
  local yaml_filename=${1:?}
  if [[ "$yaml_filename" == *.yaml ]]; then
    echo "${yaml_filename%.yaml}.sh"
  elif [[ "$yaml_filename" == *.yml ]]; then
    echo "${yaml_filename%.yml}.sh"
  else
    echo "${yaml_filename}.sh"
  fi
}

__fw_auto_configurable_generate_user_config_sh_if_needed() {
  local user_yaml_file=${1:?}
  local user_config_dir=${2:?}
  local user_config_filename=${3:?}
  local -n __nr_user_map__=${4:?}

  local user_config_sh_filename
  user_config_sh_filename=$(__fw_auto_configurable_yaml_filename_to_sh_filename "$user_config_filename")
  local user_config_sh_file="$user_config_dir/$user_config_sh_filename"

  # 如果用户已经提供了 config.sh，则框架不覆盖
  if [[ -f "$user_config_sh_file" ]]; then
    # shellcheck disable=SC1090
    source "$user_config_sh_file"
    return 0
  fi

  # automap 开关控制是否生成
  if [[ "${gr_radp_user_config_automap:-false}" != "true" ]]; then
    return 0
  fi

  if [[ ! -f "$user_yaml_file" ]]; then
    __fw_auto_configurable_warn "User yaml config '$user_yaml_file' not found, skip generating '$user_config_sh_file'."
    return 0
  fi

  mkdir -p "$user_config_dir"

  local framework_config_sh="$gr_fw_root_path/config/framework_config.sh"
  local -A predefined_yaml_var_set=()
  __fw_auto_configurable_extract_predefined_yaml_vars "$framework_config_sh" predefined_yaml_var_set

  {
    echo '#!/usr/bin/env bash'
    echo 'set -e'
    echo
    echo '########################################################################################################################'
    echo '# AUTO-GENERATED BY RADP BASH FRAMEWORK'
    echo "# source yaml: $user_yaml_file"
    echo '# If you want to customize mappings, create and maintain this file manually.'
    echo '########################################################################################################################'
    echo
    local key yaml_var gr_var
    for key in "${!__nr_user_map__[@]}"; do
      # 跳过 framework 侧不允许用户覆盖的部分（理论上已过滤，但这里再兜底）
      if [[ "$key" == 'radp.framework' || "$key" == radp.framework.* ]]; then
        continue
      fi

      yaml_var=$(__fw_auto_configurable_key_to_yaml_var_name "$key")

      # 仅为“framework_config.sh 未预定义”的 YAML_* 生成映射
      if [[ -n "${predefined_yaml_var_set["$yaml_var"]+x}" ]]; then
        continue
      fi

      gr_var=$(__fw_auto_configurable_key_to_gr_var_name "$key")
      echo "declare -gr $gr_var=\"\${GX_${yaml_var#YAML_}:-\${$yaml_var:-}}\""
    done | sort
    echo
  } >"$user_config_sh_file"

  chmod +x "$user_config_sh_file" || true

  # 生成后立即加载
  # shellcheck disable=SC1090
  source "$user_config_sh_file"
}

__fw_auto_configurable_merge_maps_with_restrictions() {
  local -n __nr_framework_map__=${1:?}
  local -n __nr_user_map__=${2:?}
  local -n __nr_out_map__=${3:?}

  local k
  for k in "${!__nr_framework_map__[@]}"; do
    __nr_out_map__["$k"]="${__nr_framework_map__["$k"]}"
  done

  for k in "${!__nr_user_map__[@]}"; do
    if [[ "$k" == 'radp.framework' || "$k" == radp.framework.* ]]; then
      __fw_auto_configurable_warn "Config '$k' is not allowed to be overridden by user config, ignored."
      continue
    fi
    __nr_out_map__["$k"]="${__nr_user_map__["$k"]}"
  done
}

__main() {
  __fw_auto_configurable_require_cmd yq || return 1
  : "${gr_fw_root_path:?}"

  local framework_config_dir_default="$gr_fw_root_path/config"
  local framework_config_filename_default='framework_config.yaml'

  local framework_yaml_file
  framework_yaml_file="${GX_RADP_FRAMEWORK_CONFIG_PATH:-$framework_config_dir_default}/${GX_RADP_FRAMEWORK_CONFIG_FILENAME:-$framework_config_filename_default}"

  local user_config_dir_default
  user_config_dir_default="$(dirname "${gr_fw_root_path}")/config"
  local user_config_filename_default='config.yaml'

  # 解析 framework yaml
  local -A framework_map=()
  __fw_auto_configurable_parse_yaml_to_map "$framework_yaml_file" framework_map
  __fw_auto_configurable_apply_base_defaults framework_map
  __fw_auto_configurable_resolve_placeholders_in_map framework_map

  # user yaml 的定位：优先 GX 覆盖，其次使用 framework yaml 中的配置（如果存在），最后回退默认路径
  local user_config_dir user_config_filename user_yaml_file
  user_config_dir="${GX_RADP_USER_CONFIG_PATH:-${framework_map['radp.user.config.path']:-$user_config_dir_default}}"
  user_config_filename="${GX_RADP_USER_CONFIG_FILENAME:-${framework_map['radp.user.config.filename']:-$user_config_filename_default}}"
  user_yaml_file="$user_config_dir/$user_config_filename"

  # 解析 user yaml
  local -A user_map=()
  __fw_auto_configurable_parse_yaml_to_map "$user_yaml_file" user_map
  __fw_auto_configurable_apply_base_defaults user_map
  __fw_auto_configurable_resolve_placeholders_in_map user_map

  # 合并（user > framework），但禁止 user 覆盖 radp.framework.*
  local -A merged_map=()
  __fw_auto_configurable_merge_maps_with_restrictions framework_map user_map merged_map
  __fw_auto_configurable_apply_base_defaults merged_map
  __fw_auto_configurable_resolve_placeholders_in_map merged_map

  # 导出 YAML_* 变量，供 framework_config.sh 使用
  __fw_auto_configurable_export_yaml_vars merged_map

  # source framework predefined configurable vars
  local framework_config_sh="$gr_fw_root_path/config/framework_config.sh"
  if [[ ! -f "$framework_config_sh" ]]; then
    __fw_auto_configurable_error "framework_config.sh not found: $framework_config_sh"
    return 1
  fi
  # shellcheck disable=SC1090
  source "$framework_config_sh" || return 1

  # user 扩展 config.sh：存在则直接加载；不存在则在 automap=true 时生成并加载
  __fw_auto_configurable_generate_user_config_sh_if_needed \
    "$user_yaml_file" \
    "${gr_radp_user_config_path:-$user_config_dir}" \
    "${gr_radp_user_config_filename:-$user_config_filename}" \
    user_map
}

__main "$@"
