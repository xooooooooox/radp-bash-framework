#!/usr/bin/env bash
# toolkit module: io/03_banner.sh
# Banner display utilities

#######################################
# Get banner ASCII art from various sources
# Priority:
#   1. radp_app_banner_art() function (if defined)
#   2. $gr_fw_user_config_path/banner.txt (if exists)
#   3. $gr_fw_banner_file (framework default)
# Outputs:
#   ASCII art string to stdout
#######################################
radp_banner_get_art() {
  if declare -F radp_app_banner_art >/dev/null 2>&1; then
    radp_app_banner_art
  elif [[ -f "$gr_fw_user_config_path/banner.txt" ]]; then
    cat "$gr_fw_user_config_path/banner.txt"
  else
    cat "$gr_fw_banner_file"
  fi
}

#######################################
# Build complete banner with ASCII art and version info
# The version info lines are auto-aligned to match ASCII art width
# Globals:
#   RADP_APP_NAME - application name
#   gr_fw_banner_file - framework banner file path
#   gr_fw_user_config_path - user config path
# Outputs:
#   Complete banner string to stdout
#######################################
radp_banner_build() {
  # 1. 获取 ASCII 图案
  local banner_art
  banner_art="$(radp_banner_get_art)"

  # 2. 获取版本信息
  local app_name="${RADP_APP_NAME:-radp-cli}"
  local app_var="${app_name//-/_}"
  # 检查 gr_* 变量（automap 生成）和 YAML_* 变量（YAML 解析）
  local gr_version_var="gr_radp_extend_${app_var}_version"
  local yaml_version_var="YAML_RADP_EXTEND_${app_var^^}_VERSION"
  local app_version="${!gr_version_var:-${!yaml_version_var:-}}"
  local fw_version
  fw_version="$(radp_get_fw_install_version)"

  # 3. 计算 ASCII 图案宽度
  local art_width=0
  local line
  while IFS= read -r line; do
    (( ${#line} > art_width )) && art_width=${#line}
  done <<< "$banner_art"
  # 确保最小宽度（"radp-bash-framework" 19字符 + 版本约 12 字符 + 前缀 4 字符 + 间隔）
  (( art_width < 45 )) && art_width=45

  # 4. 构建完整 banner
  local banner="$banner_art"
  if [[ -n "$app_version" ]]; then
    app_version="$(radp_get_install_version "$app_version")"
    banner+="$(printf '\n :: %-20s %*s' "$app_name" $((art_width - 24)) "($app_version)")"
  fi
  banner+="$(printf '\n :: %-20s %*s' "radp-bash-framework" $((art_width - 24)) "($fw_version)")"

  echo "$banner"
}

#######################################
# Print banner if banner mode is enabled
# Globals:
#   gr_radp_fw_banner_mode - banner mode (on/off)
# Returns:
#   0 - always
#######################################
radp_banner_print() {
  [[ "$gr_radp_fw_banner_mode" == "off" ]] && return 0
  radp_log_raw "$(radp_banner_build)"
}
