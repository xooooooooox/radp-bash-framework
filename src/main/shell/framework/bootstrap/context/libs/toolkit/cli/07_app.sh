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
# Display configuration in text format (Docker info style)
#######################################
__radp_app_show_config_text() {
  local app_name="$1"

  # Get app version from commands/version.sh
  local version_sh_path="${RADP_APP_ROOT:-}/src/main/shell/commands/version.sh"
  local app_version=""
  if [[ -f "$version_sh_path" ]]; then
    app_version="$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)".*/\1/p' "$version_sh_path" 2>/dev/null || true)"
  fi

  # App section
  printf "%-13s%s\n" "App:" "$app_name"
  printf "%-13s%s\n" "Version:" "${app_version:-unknown}"
  printf "%-13s%s\n" "Environment:" "${gr_radp_env:-local}"
  echo ""

  # Framework section
  echo "Framework:"
  printf " %-12s%s\n" "Version:" "${gr_fw_version:-unknown}"
  printf " %-12s%s\n" "Root:" "${gr_fw_root_path:-<not set>}"
  echo ""

  # Config section
  local config_exists_text="not found"
  [[ -f "${gr_fw_user_yaml_config_file:-}" ]] && config_exists_text="exists"

  echo "Config:"
  printf " %-12s%s\n" "Directory:" "${gr_fw_user_config_path:-<not set>}"
  printf " %-12s%s (%s)\n" "File:" "${gr_fw_user_yaml_config_file:-<not set>}" "$config_exists_text"
  # Display libs (first path only for brevity, or list all)
  if [[ ${#gra_radp_fw_user_lib_paths[@]} -eq 0 ]]; then
    printf " %-12s%s\n" "Libs:" "<not set>"
  elif [[ ${#gra_radp_fw_user_lib_paths[@]} -eq 1 ]]; then
    printf " %-12s%s\n" "Libs:" "${gra_radp_fw_user_lib_paths[0]}"
  else
    printf " %-12s\n" "Libs:"
    local lib_path
    for lib_path in "${gra_radp_fw_user_lib_paths[@]}"; do
      printf "   - %s\n" "$lib_path"
    done
  fi
  echo ""

  # Settings section
  echo "Settings:"
  printf " %-12s%s\n" "Banner:" "${gr_radp_fw_banner_mode:-off}"
  echo ""

  # Log section
  local console_status="disabled"
  [[ "${gr_radp_fw_log_console_enabled:-true}" == "true" ]] && console_status="enabled"
  local file_status="disabled"
  [[ "${gr_radp_fw_log_file_enabled:-true}" == "true" ]] && file_status="enabled"

  echo "Log:"
  printf " %-12s%s\n" "Level:" "${gr_radp_fw_log_level:-info}"
  printf " %-12s%s\n" "Debug:" "${gr_radp_fw_log_debug:-false}"
  printf " %-12s%s\n" "Console:" "$console_status"
  printf " %-12s%s\n" "File:" "$file_status"
  printf " %-12s%s\n" "File Path:" "${gr_radp_fw_log_file_name:-<not set>}"
  echo ""

  # Log Rolling section
  local rolling_status="false"
  [[ "${gr_radp_fw_log_rolling_policy_enabled:-true}" == "true" ]] && rolling_status="true"

  echo "Log Rolling:"
  printf " %-15s%s\n" "Enabled:" "$rolling_status"
  printf " %-15s%s\n" "Max History:" "${gr_radp_fw_log_rolling_policy_max_history:-7}"
  printf " %-15s%s\n" "Max File Size:" "${gr_radp_fw_log_rolling_policy_max_file_size:-10MB}"
  printf " %-15s%s\n" "Total Size:" "${gr_radp_fw_log_rolling_policy_total_size_cap:-5GB}"

  # Extensions section (only when --all is specified)
  if [[ "${__RADP_APP_CONFIG_ALL:-}" == "true" ]]; then
    __radp_app_show_config_extensions_text "$app_name"
  fi
}

#######################################
# Display application extensions in text format (Docker info style)
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

  echo ""
  echo "Extensions:"

  while IFS= read -r var_name; do
    var_value="${!var_name}"

    # Extract key: gr_radp_extend_homelabctl_vf_config_dir -> homelabctl_vf_config_dir
    key="${var_name#$prefix}"

    # Determine top section from first part: homelabctl_vf_config_dir -> homelabctl
    local top_section="${key%%_*}"

    # Get remaining part after top section: vf_config_dir
    local rest="${key#*_}"

    # Determine subsection: vf_config_dir -> vf
    local subsection="${rest%%_*}"

    # Get the key name: config_dir
    local display_key="${rest#*_}"
    # If no underscore in rest, display_key is same as rest (e.g., "version")
    [[ "$display_key" == "$rest" ]] && display_key="$rest"

    # Build section identifier: homelabctl.vf or just homelabctl
    local full_section="$top_section"
    # Check if this is a subsection (more than one underscore in original key)
    if [[ "$key" == *_*_* ]]; then
      full_section="${top_section}_${subsection}"
    fi

    # Print section header if changed
    if [[ "$full_section" != "$current_section" ]]; then
      if [[ "$key" == *_*_* ]]; then
        # Has subsection
        printf " %s:\n" "$subsection"
      else
        # No subsection, top-level extension key
        :
      fi
      current_section="$full_section"
    fi

    # Handle empty values
    [[ -z "$var_value" ]] && var_value="-"

    # Output with proper indentation
    if [[ "$key" == *_*_* ]]; then
      # Has subsection - deeper indent
      printf "  %-22s%s\n" "${display_key}:" "$var_value"
    else
      # Top-level extension
      printf " %-23s%s\n" "${display_key}:" "$var_value"
    fi
  done <<<"$vars"
}

#######################################
# Display configuration in JSON format (Docker info style)
#######################################
__radp_app_show_config_json() {
  local app_name="$1"
  local config_exists="false"
  [[ -f "${gr_fw_user_yaml_config_file:-}" ]] && config_exists="true"

  # Get app version from commands/version.sh
  local version_sh_path="${RADP_APP_ROOT:-}/src/main/shell/commands/version.sh"
  local app_version=""
  if [[ -f "$version_sh_path" ]]; then
    app_version="$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)".*/\1/p' "$version_sh_path" 2>/dev/null || true)"
  fi
  local app_version_json="null"
  [[ -n "$app_version" ]] && app_version_json="\"$app_version\""

  # Build libs JSON (first path for backward compatibility, but can show all)
  local libs_json="null"
  if [[ ${#gra_radp_fw_user_lib_paths[@]} -gt 0 ]]; then
    libs_json="\"${gra_radp_fw_user_lib_paths[0]}\""
  fi

  # Build JSON output
  cat <<EOF
{
  "app": {
    "name": "$app_name",
    "version": ${app_version_json},
    "environment": "${gr_radp_env:-local}"
  },
  "framework": {
    "version": "${gr_fw_version:-unknown}",
    "root": "${gr_fw_root_path:-}"
  },
  "config": {
    "directory": "${gr_fw_user_config_path:-}",
    "file": "${gr_fw_user_yaml_config_file:-}",
    "file_exists": $config_exists,
    "libs": ${libs_json}
  },
  "settings": {
    "banner": "${gr_radp_fw_banner_mode:-off}"
  },
  "log": {
    "level": "${gr_radp_fw_log_level:-info}",
    "debug": ${gr_radp_fw_log_debug:-false},
    "console": ${gr_radp_fw_log_console_enabled:-true},
    "file": {
      "enabled": ${gr_radp_fw_log_file_enabled:-true},
      "path": "${gr_radp_fw_log_file_name:-}"
    },
    "rolling": {
      "enabled": ${gr_radp_fw_log_rolling_policy_enabled:-true},
      "max_history": ${gr_radp_fw_log_rolling_policy_max_history:-7},
      "max_file_size": "${gr_radp_fw_log_rolling_policy_max_file_size:-10MB}",
      "total_size_cap": "${gr_radp_fw_log_rolling_policy_total_size_cap:-5GB}"
    }
  }
EOF

  # Add extensions only when --all is specified
  if [[ "${__RADP_APP_CONFIG_ALL:-}" == "true" ]]; then
    echo ','
    echo '  "extensions": {'
    __radp_app_show_config_extensions_json
    echo '  }'
  fi
  echo '}'
}

#######################################
# Display application extensions in JSON format
# Groups by subsection (e.g., gr_radp_extend_homelabctl_vf_* -> extensions.vf.*)
#######################################
__radp_app_show_config_extensions_json() {
  local prefix="gr_radp_extend_"
  local vars var_name var_value key
  local -A subsections
  local -a subsection_order

  # Get all gr_radp_extend_* variables
  vars=$(compgen -v | grep "^${prefix}" | sort)

  [[ -z "$vars" ]] && return 0

  # Group variables by subsection
  # gr_radp_extend_homelabctl_vf_config_dir -> subsection=vf, key=config_dir
  while IFS= read -r var_name; do
    var_value="${!var_name}"
    key="${var_name#$prefix}"

    # Skip top-level app keys like homelabctl_version (no subsection)
    # Only process keys with subsections: homelabctl_vf_config_dir
    local top_section="${key%%_*}"
    local rest="${key#*_}"

    # Determine if there's a subsection
    local subsection=""
    local field_key=""
    if [[ "$rest" == *_* ]]; then
      subsection="${rest%%_*}"
      field_key="${rest#*_}"
    else
      # No subsection, skip for now (could add to top-level if needed)
      continue
    fi

    # Initialize subsection if not exists
    if [[ -z "${subsections[$subsection]:-}" ]]; then
      subsections[$subsection]=""
      subsection_order+=("$subsection")
    fi

    # Escape JSON value
    var_value="${var_value//\\/\\\\}"
    var_value="${var_value//\"/\\\"}"
    [[ -z "$var_value" ]] && var_value="null" || var_value="\"$var_value\""

    # Add to subsection
    if [[ -n "${subsections[$subsection]}" ]]; then
      subsections[$subsection]="${subsections[$subsection]}, "
    fi
    subsections[$subsection]="${subsections[$subsection]}\"$field_key\": $var_value"
  done <<<"$vars"

  # Output subsections
  local first=true
  for subsection in "${subsection_order[@]}"; do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    printf '    "%s": {%s}' "$subsection" "${subsections[$subsection]}"
  done
  echo ""
}
