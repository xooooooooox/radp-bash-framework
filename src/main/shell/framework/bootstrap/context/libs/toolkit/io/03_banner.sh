#!/usr/bin/env bash
# toolkit module: io/03_banner.sh
# Banner display utilities

#######################################
# Get banner ASCII art from various sources
# Priority:
#   1. radp_app_banner_art() function (if defined)
#   2. $gr_fw_user_config_path/banner.txt (user override)
#   3. $gr_fw_app_config_path/banner.txt (app bundled)
#   4. $gr_fw_banner_file (framework default)
# Outputs:
#   ASCII art string to stdout
#######################################
radp_banner_get_art() {
  if declare -F radp_app_banner_art >/dev/null 2>&1; then
    radp_app_banner_art
  elif [[ -f "$gr_fw_user_config_path/banner.txt" ]]; then
    cat "$gr_fw_user_config_path/banner.txt"
  elif [[ -n "${gr_fw_app_config_path:-}" && -f "$gr_fw_app_config_path/banner.txt" ]]; then
    cat "$gr_fw_app_config_path/banner.txt"
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
  # 从 commands/version.sh 文件中读取版本
  # 使用 RADP_APP_ROOT 定位，兼容开发模式和安装模式
  local version_sh_path="${RADP_APP_ROOT:-}/src/main/shell/commands/version.sh"
  local app_version=""
  if [[ -f "$version_sh_path" ]]; then
    app_version="$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)".*/\1/p' "$version_sh_path" 2>/dev/null || true)"
  fi
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
