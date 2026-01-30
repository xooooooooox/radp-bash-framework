#!/usr/bin/env bash
# toolkit module: cli/07_app.sh
# 应用入口：提供 radp_app_run 和相关配置函数

# 应用配置
declare -g __radp_cli_app_desc=""
declare -g __radp_cli_app_version=""

#######################################
# 配置应用信息
# Arguments:
#   1 - name: 应用名称
#   2 - version: 应用版本（可选）
#   3 - desc: 应用描述（可选）
#######################################
radp_app_config() {
  local name="$1"
  local version="${2:-}"
  local desc="${3:-}"

  radp_cli_set_app_name "$name"
  __radp_cli_app_version="$version"
  __radp_cli_app_desc="$desc"
}

#######################################
# 应用主入口
# 自动发现命令并处理分发
# Prerequisites:
#   - 已调用 radp_cli_set_commands_dir 设置命令目录
#   - 已调用 radp_cli_set_app_name 设置应用名称（或 radp_app_config）
# Arguments:
#   @ - 命令行参数
# Returns:
#   命令的返回码
#######################################
radp_app_run() {
  # 确保命令目录已设置
  if [[ -z "$__radp_cli_commands_dir" ]]; then
    radp_log_error "Commands directory not set. Call radp_cli_set_commands_dir first."
    return 1
  fi

  # 发现命令
  radp_cli_discover || {
    radp_log_error "Failed to discover commands"
    return 1
  }

  # 分发
  radp_cli_dispatch "$@"
}

#######################################
# 简化的应用初始化和运行
# 自动检测应用目录结构并运行
# Arguments:
#   1 - app_root: 应用根目录（包含 src/main/shell/commands/）
#   2 - app_name: 应用名称
#   @ - 命令行参数
# Returns:
#   命令的返回码
#######################################
radp_app_bootstrap() {
  local app_root="$1"
  local app_name="$2"
  shift 2

  # 设置应用名称
  radp_cli_set_app_name "$app_name"

  # 查找命令目录
  local commands_dir=""
  if [[ -d "$app_root/src/main/shell/commands" ]]; then
    commands_dir="$app_root/src/main/shell/commands"
  elif [[ -d "$app_root/commands" ]]; then
    commands_dir="$app_root/commands"
  else
    radp_log_error "Commands directory not found in: $app_root"
    return 1
  fi

  radp_cli_set_commands_dir "$commands_dir"

  # 加载应用配置（如果存在）
  local config_file="$app_root/src/main/shell/config/app.yaml"
  if [[ -f "$config_file" ]]; then
    # TODO: 从 YAML 加载配置
    :
  fi

  # 运行
  radp_app_run "$@"
}

#######################################
# 输出应用版本（供命令内部使用或覆盖）
#######################################
radp_app_version() {
  echo "${__radp_cli_app_name:-cli} ${__radp_cli_app_version:-unknown}"
}

#######################################
# 检查是否请求版本
# Arguments:
#   @ - 命令行参数
# Returns:
#   0 - 请求了版本
#   1 - 未请求版本
#######################################
radp_app_is_version_request() {
  [[ "${1:-}" == "-v" || "${1:-}" == "--version" ]]
}

#######################################
# 检查是否请求帮助
# Arguments:
#   @ - 命令行参数
# Returns:
#   0 - 请求了帮助
#   1 - 未请求帮助
#######################################
radp_app_is_help_request() {
  [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]
}

#######################################
# Display application configuration
# Shows paths, framework settings, and application extensions
# Globals:
#   __RADP_APP_CONFIG_JSON - if set, output JSON format
#   gr_fw_* - framework path variables
#   gr_radp_* - configuration variables
# Outputs:
#   Configuration info to stdout
#######################################
radp_app_show_config() {
  local app_name="${RADP_APP_NAME:-${__radp_cli_app_name:-cli}}"

  if [[ "${__RADP_APP_CONFIG_JSON:-}" == "true" ]]; then
    __radp_app_show_config_json "$app_name"
  else
    __radp_app_show_config_text "$app_name"
  fi
}

#######################################
# Display configuration in text format (Style A: Grouped)
#######################################
__radp_app_show_config_text() {
  local app_name="$1"

  echo "$app_name Configuration"
  echo "========================"
  echo ""

  # [Paths]
  echo "[Paths]"
  local config_exists="not found"
  [[ -f "${gr_fw_user_yaml_config_file:-}" ]] && config_exists="exists"
  printf "  %-22s %s\n" "User config dir" "${gr_fw_user_config_path:-<not set>}"
  printf "  %-22s %s (%s)\n" "Config file" "${gr_fw_user_yaml_config_file:-<not set>}" "$config_exists"
  # Display user lib dirs (multiple paths supported)
  if [[ ${#gra_radp_fw_user_lib_paths[@]} -eq 0 ]]; then
    printf "  %-22s %s\n" "User lib dirs" "<not set>"
  elif [[ ${#gra_radp_fw_user_lib_paths[@]} -eq 1 ]]; then
    printf "  %-22s %s\n" "User lib dirs" "${gra_radp_fw_user_lib_paths[0]}"
  else
    printf "  %-22s\n" "User lib dirs"
    local lib_path
    for lib_path in "${gra_radp_fw_user_lib_paths[@]}"; do
      printf "    - %s\n" "$lib_path"
    done
  fi
  printf "  %-22s %s\n" "Framework root" "${gr_fw_root_path:-<not set>}"
  echo ""

  # [Framework]
  echo "[Framework]"
  printf "  %-22s %s\n" "Version" "${gr_fw_version:-unknown}"
  printf "  %-22s %s\n" "Banner mode" "${gr_radp_fw_banner_mode:-off}"
  printf "  %-22s %s\n" "Log level" "${gr_radp_fw_log_level:-info}"
  printf "  %-22s %s\n" "Log debug" "${gr_radp_fw_log_debug:-false}"
  echo ""

  # [Application] - show app version from commands/version.sh
  local version_sh_path="${gr_fw_user_config_path%/config}/commands/version.sh"
  local app_version=""
  if [[ -f "$version_sh_path" ]]; then
    app_version="$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)".*/\1/p' "$version_sh_path" 2>/dev/null || true)"
  fi
  if [[ -n "$app_version" ]]; then
    echo "[Application]"
    printf "  %-22s %s\n" "Version" "$app_version"
    echo ""
  fi

  # [Application Extensions]
  # Collect all gr_radp_extend_* variables and group them
  __radp_app_show_config_extensions_text "$app_name"
}

#######################################
# Display application extensions in text format
#######################################
__radp_app_show_config_extensions_text() {
  local app_name="$1"
  local prefix="gr_radp_extend_"
  local current_section=""
  local var_name var_value key section

  # Get all gr_radp_extend_* variables, sorted
  local vars
  vars=$(compgen -v | grep "^${prefix}" | sort)

  [[ -z "$vars" ]] && return 0

  while IFS= read -r var_name; do
    var_value="${!var_name}"

    # Extract key: gr_radp_extend_homelabctl_gitlab_type -> homelabctl_gitlab_type
    key="${var_name#$prefix}"

    # Determine section from first part: homelabctl_gitlab_type -> homelabctl
    section="${key%%_*}"

    # Check for subsection: homelabctl_gitlab_type -> gitlab
    local rest="${key#*_}"
    local subsection=""
    if [[ "$rest" == *_* ]]; then
      subsection="${rest%%_*}"
    fi

    # Build section header
    local full_section="$section"
    [[ -n "$subsection" ]] && full_section="${section}.${subsection}"

    # Print section header if changed
    if [[ "$full_section" != "$current_section" ]]; then
      [[ -n "$current_section" ]] && echo ""
      echo "[Application: $full_section]"
      current_section="$full_section"
    fi

    # Extract display key (remove section prefix)
    local display_key="$key"
    if [[ -n "$subsection" ]]; then
      # homelabctl_gitlab_type -> type
      display_key="${rest#*_}"
      [[ "$display_key" == "$rest" ]] && display_key="${rest}"
    else
      # homelabctl_version -> version
      display_key="${key#*_}"
    fi

    # Handle empty values
    [[ -z "$var_value" ]] && var_value="<not set>"

    printf "  %-22s %s\n" "$display_key" "$var_value"
  done <<<"$vars"
}

#######################################
# Display configuration in JSON format
#######################################
__radp_app_show_config_json() {
  local app_name="$1"
  local config_exists="false"
  [[ -f "${gr_fw_user_yaml_config_file:-}" ]] && config_exists="true"

  # Build user_lib_dirs JSON array
  local user_lib_dirs_json="[]"
  if [[ ${#gra_radp_fw_user_lib_paths[@]} -gt 0 ]]; then
    local -a json_paths=()
    local lib_path
    for lib_path in "${gra_radp_fw_user_lib_paths[@]}"; do
      json_paths+=("\"$lib_path\"")
    done
    local IFS=','
    user_lib_dirs_json="[${json_paths[*]}]"
  fi

  # Get app version from commands/version.sh
  local version_sh_path="${gr_fw_user_config_path%/config}/commands/version.sh"
  local app_version=""
  if [[ -f "$version_sh_path" ]]; then
    app_version="$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)".*/\1/p' "$version_sh_path" 2>/dev/null || true)"
  fi
  local app_version_json="null"
  [[ -n "$app_version" ]] && app_version_json="\"$app_version\""

  # Build JSON output
  cat <<EOF
{
  "app_name": "$app_name",
  "app_version": $app_version_json,
  "paths": {
    "user_config_dir": "${gr_fw_user_config_path:-}",
    "config_file": "${gr_fw_user_yaml_config_file:-}",
    "config_file_exists": $config_exists,
    "user_lib_dirs": $user_lib_dirs_json,
    "framework_root": "${gr_fw_root_path:-}"
  },
  "framework": {
    "version": "${gr_fw_version:-unknown}",
    "banner_mode": "${gr_radp_fw_banner_mode:-off}",
    "log_level": "${gr_radp_fw_log_level:-info}",
    "log_debug": ${gr_radp_fw_log_debug:-false}
  },
EOF

  # Add extensions
  echo '  "extend": {'
  __radp_app_show_config_extensions_json
  echo '  }'
  echo '}'
}

#######################################
# Display application extensions in JSON format
#######################################
__radp_app_show_config_extensions_json() {
  local prefix="gr_radp_extend_"
  local vars var_name var_value key
  local -A sections
  local -a section_order

  # Get all gr_radp_extend_* variables
  vars=$(compgen -v | grep "^${prefix}" | sort)

  [[ -z "$vars" ]] && return 0

  # Group variables by top-level section
  while IFS= read -r var_name; do
    var_value="${!var_name}"
    key="${var_name#$prefix}"
    local section="${key%%_*}"
    local rest="${key#*_}"

    # Initialize section if not exists
    if [[ -z "${sections[$section]:-}" ]]; then
      sections[$section]=""
      section_order+=("$section")
    fi

    # Escape JSON value
    var_value="${var_value//\\/\\\\}"
    var_value="${var_value//\"/\\\"}"
    [[ -z "$var_value" ]] && var_value="null" || var_value="\"$var_value\""

    # Add to section
    if [[ -n "${sections[$section]}" ]]; then
      sections[$section]="${sections[$section]},"
    fi
    sections[$section]="${sections[$section]}\"$rest\": $var_value"
  done <<<"$vars"

  # Output sections
  local first=true
  for section in "${section_order[@]}"; do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    printf '    "%s": {%s}' "$section" "${sections[$section]}"
  done
  echo ""
}
