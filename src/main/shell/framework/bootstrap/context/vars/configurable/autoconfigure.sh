#!/usr/bin/env bash
set -e

# auto_configurable 的职责：
# 1) 使用 yq 解析 framework/user yaml，按优先级合并为最终配置
# 2) 将配置转换为 `YAML_*` 形式的变量（类似 Spring Boot ENVIRONMENT）
# 3) source `framework_config.sh` 完成预定义 `gr_*` 声明
# 4) 处理 user 扩展：存在 `config.sh` 则 source；否则在 automap=true 时按 user yaml 生成

__fw_parse_yaml_to_map() {
  local yaml_file=${1:?}
  local -n __nr_out_map__=${2:?}

  if [[ ! -f "$yaml_file" ]]; then
    return 0
  fi

  # 解析所有标量节点为 key\tvalue 的 TSV 行
  local key value
  while IFS=$'\t' read -r key value; do
    [[ -z "${key:-}" ]] && continue
    if [[ "${value:-}"  == "null" ]]; then
        value=""
    fi
    __nr_out_map__["$key"]="$value"
  done < <(
    yq -r '.. | select(tag != "!!map" and tag != "!!seq") | [ (path | join(".")), (. | tostring) ] | @tsv' "$yaml_file"
  )
}

__fw_resolve_placeholders_in_map() {
  local map_name=${1:?}
}

__fw_autoconfigure() {
  # 注入 framework config
  # shellcheck source=../../../../config/framework_config.sh
  __fw_source_scripts "$gr_fw_config_file"

  # 注入 user extended config
  local user_config_path user_config_filename user_config_file
  user_config_path="${gr_radp_user_config_path:?}"
  user_config_filename=$(basename "${gr_radp_user_config_filename:?}")
  user_config_file="$user_config_path"/"$user_config_filename"
  __fw_source_scripts "$user_config_file"
}

__main() {
  local -A fw_parsed_yaml_config_map=()
  __fw_parse_yaml_to_map "$gr_fw_yaml_config_file" fw_parsed_yaml_config_map

  __fw_autoconfigure
}

__main "$@"
