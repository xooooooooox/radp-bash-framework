#!/usr/bin/env bash
set -e

# auto_configurable 的职责：
# 1) 使用 yq 解析 framework/user yaml，按优先级合并为最终配置
# 2) 将配置转换为 `YAML_*` 形式的变量（类似 Spring Boot ENVIRONMENT）
# 3) source `framework_config.sh` 完成预定义 `gr_*` 声明
# 4) 处理 user 扩展：存在 `config.sh` 则 source；否则在 automap=true 时按 user yaml 生成

__fw_autoconfigure() {
  # 注入 framework config
  local fw_config_path fw_config_filename fw_config_file
  fw_config_path="${gr_radp_framework_config_path:?}"
  fw_config_filename=$(basename "${gr_radp_framework_config_filename:?}")
  fw_config_file="$fw_config_path"/"$fw_config_filename"
  __fw_source_scripts "$fw_config_file"

  # 注入 user extended config
  local user_config_path user_config_filename user_config_file
  user_config_path="${gr_radp_user_config_path:?}"
  user_config_filename=$(basename "${gr_radp_user_config_filename:?}")
  user_config_file="$user_config_path"/"$user_config_filename"
  __fw_source_scripts "$user_config_file"
}

__main() {

  __fw_autoconfigure
}

__main "$@"
