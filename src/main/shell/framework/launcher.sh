#!/usr/bin/env bash
#######################################
# radp-bash-framework App Launcher
# 为 CLI 应用提供完整的初始化和运行支持
#
# 必需环境变量：
#   RADP_APP_ROOT - 项目根目录
#
# 可选环境变量：
#   RADP_APP_NAME         - 应用名称
#   RADP_APP_COMMANDS_DIR - 命令目录
#######################################

#######################################
# 全局变量声明
#######################################

# 全局数组：过滤后的命令行参数
declare -ga gwa_radp_app_filtered_args=()

# 全局状态标志
declare -g gw_radp_app_show_config=false
declare -g gw_radp_app_config_json=false
declare -g gw_radp_app_config_all=false

#######################################
# 解析全局选项并过滤命令行参数
# 处理 -q, -v, --debug, --config 等全局选项
# Globals:
#   gwa_radp_app_filtered_args - 输出：过滤后的参数数组
#   gw_radp_app_show_config    - 输出：是否显示配置
#   gw_radp_app_config_json    - 输出：是否 JSON 格式
#   gw_radp_app_config_all     - 输出：是否显示全部配置
# Arguments:
#   @ - 命令行参数
# Outputs:
#   设置 GX_RADP_FW_* 环境变量
# Returns:
#   0 - 成功
#######################################
__radp_app_parse_global_options() {
  gwa_radp_app_filtered_args=()
  local quiet=false
  local verbose=false
  local debug=false
  local show_config=false
  local config_json=false
  local config_all=false
  local found_command=false

  while [[ $# -gt 0 ]]; do
    # 一旦遇到非选项参数（子命令），后续所有参数都传递给子命令
    if [[ "$found_command" == "true" ]]; then
      gwa_radp_app_filtered_args+=("$1")
      shift
      continue
    fi

    case "$1" in
    -q | --quiet)
      quiet=true
      shift
      ;;
    -v | --verbose)
      verbose=true
      shift
      ;;
    --debug)
      debug=true
      shift
      ;;
    --config)
      show_config=true
      shift
      ;;
    --json)
      # Only valid after --config
      if [[ "$show_config" == "true" ]]; then
        config_json=true
      else
        gwa_radp_app_filtered_args+=("$1")
      fi
      shift
      ;;
    --all)
      # Only valid after --config
      if [[ "$show_config" == "true" ]]; then
        config_all=true
      else
        gwa_radp_app_filtered_args+=("$1")
      fi
      shift
      ;;
    --)
      shift
      gwa_radp_app_filtered_args+=("$@")
      break
      ;;
    -*)
      # 未知选项，保留传递
      gwa_radp_app_filtered_args+=("$1")
      shift
      ;;
    *)
      # 遇到子命令，标记后续参数直接传递
      found_command=true
      gwa_radp_app_filtered_args+=("$1")
      shift
      ;;
    esac
  done

  # 设置 --config 模式
  if [[ "$show_config" == "true" ]]; then
    gw_radp_app_show_config=true
    export __RADP_APP_SHOW_CONFIG=true
    if [[ "$config_json" == "true" ]]; then
      gw_radp_app_config_json=true
      export __RADP_APP_CONFIG_JSON=true
    fi
    if [[ "$config_all" == "true" ]]; then
      gw_radp_app_config_all=true
      export __RADP_APP_CONFIG_ALL=true
    fi
  fi

  # 设置输出模式环境变量
  if [[ "$quiet" == "true" ]]; then
    # Quiet 模式: banner off, console log disabled
    export GX_RADP_FW_BANNER_MODE=off
    export GX_RADP_FW_LOG_CONSOLE_ENABLED=false
  elif [[ "$debug" == "true" ]]; then
    # Debug 模式: banner on, log level debug, debug enabled, console enabled
    export GX_RADP_FW_BANNER_MODE=on
    export GX_RADP_FW_LOG_LEVEL=debug
    export GX_RADP_FW_LOG_DEBUG=true
    export GX_RADP_FW_LOG_CONSOLE_ENABLED=true
  elif [[ "$verbose" == "true" ]]; then
    # Verbose 模式: banner on, log level info, console enabled
    export GX_RADP_FW_BANNER_MODE=on
    export GX_RADP_FW_LOG_LEVEL=info
    export GX_RADP_FW_LOG_CONSOLE_ENABLED=true
  fi
}

#######################################
# 配置用户配置路径
# 开发模式检测：如果 _ide.sh 存在，使用源码配置路径
# 否则（安装模式），使用 XDG 配置路径
# Globals:
#   RADP_APP_ROOT - 输入：应用根目录
#   RADP_APP_NAME - 输入：应用名称
#   GX_RADP_FW_USER_CONFIG_PATH - 输出：用户配置路径
# Arguments:
#   None
# Returns:
#   0 - 成功
#######################################
__radp_app_setup_user_config_path() {
  if [[ -z "${GX_RADP_FW_USER_CONFIG_PATH:-}" ]]; then
    if [[ -f "$RADP_APP_ROOT/src/main/shell/config/_ide.sh" ]]; then
      # Development mode - use source config
      export GX_RADP_FW_USER_CONFIG_PATH="$RADP_APP_ROOT/src/main/shell/config"
    else
      # Installed mode - use XDG config
      export GX_RADP_FW_USER_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/$RADP_APP_NAME"
    fi
  fi
}

#######################################
# 配置应用内置配置路径
# Globals:
#   RADP_APP_ROOT - 输入：应用根目录
#   GX_RADP_FW_APP_CONFIG_PATH - 输出：应用配置路径
# Arguments:
#   None
# Returns:
#   0 - 成功
#######################################
__radp_app_setup_app_config_path() {
  if [[ -z "${GX_RADP_FW_APP_CONFIG_PATH:-}" ]]; then
    export GX_RADP_FW_APP_CONFIG_PATH="$RADP_APP_ROOT/src/main/shell/config"
  fi
}

#######################################
# 配置用户库路径
# Globals:
#   RADP_APP_ROOT - 输入：应用根目录
#   GX_RADP_FW_USER_LIB_PATHS - 输出：用户库路径
# Arguments:
#   None
# Returns:
#   0 - 成功
#######################################
__radp_app_setup_user_lib_paths() {
  if [[ -d "$RADP_APP_ROOT/src/main/shell/libs" ]]; then
    export GX_RADP_FW_USER_LIB_PATHS="${RADP_APP_ROOT}/src/main/shell/libs:${GX_RADP_FW_USER_LIB_PATHS:-}"
  fi
}

#######################################
# 检测 completion 命令并禁用 banner/log
# Globals:
#   gwa_radp_app_filtered_args - 输入：过滤后的参数数组
#   GX_RADP_FW_BANNER_MODE - 输出：banner 模式
#   GX_RADP_FW_LOG_CONSOLE_ENABLED - 输出：控制台日志开关
# Arguments:
#   None
# Returns:
#   0 - 成功
#######################################
__radp_app_check_completion_command() {
  if [[ "${gwa_radp_app_filtered_args[0]:-}" == "completion" ]]; then
    export GX_RADP_FW_BANNER_MODE=off
    export GX_RADP_FW_LOG_CONSOLE_ENABLED=false
  fi
}

#######################################
# 配置 CLI 应用
# Globals:
#   RADP_APP_NAME - 输入：应用名称
#   RADP_APP_ROOT - 输入：应用根目录
#   RADP_APP_COMMANDS_DIR - 输入：命令目录（可选）
# Arguments:
#   None
# Returns:
#   0 - 成功
#######################################
__radp_app_configure_cli() {
  radp_cli_set_app_name "$RADP_APP_NAME"

  local commands_dir="${RADP_APP_COMMANDS_DIR:-$RADP_APP_ROOT/src/main/shell/commands}"
  radp_cli_set_commands_dir "$commands_dir"

  # 设置默认全局选项（用于帮助和补全）
  radp_cli_set_global_options "-q" "--quiet" "-v" "--verbose" "--debug" "--config" "--all" "--json"
}

#######################################
# 命令分发
# Globals:
#   gw_radp_app_show_config - 输入：是否显示配置
#   gwa_radp_app_filtered_args - 输入：过滤后的参数数组
# Arguments:
#   None
# Returns:
#   命令执行的退出码
#######################################
__radp_app_dispatch() {
  # Handle --config option
  if [[ "$gw_radp_app_show_config" == "true" ]]; then
    radp_app_show_config
    exit 0
  fi

  if [[ ${#gwa_radp_app_filtered_args[@]} -eq 0 ]]; then
    # 无参数时显示帮助
    radp_app_run help
  else
    radp_app_run "${gwa_radp_app_filtered_args[@]}"
  fi
}

#######################################
# 主入口函数
# 执行应用启动的完整流程
# Globals:
#   RADP_APP_ROOT - 输入：应用根目录
#   RADP_APP_NAME - 输入/输出：应用名称
# Arguments:
#   @ - 命令行参数
# Returns:
#   命令执行的退出码
#######################################
__radp_app_main() {
  # 验证必需的环境变量
  : "${RADP_APP_ROOT:?RADP_APP_ROOT must be set before sourcing launcher.sh}"

  # 自动派生应用名称（如未设置）
  if [[ -z "${RADP_APP_NAME:-}" ]]; then
    RADP_APP_NAME="$(basename "$RADP_APP_ROOT")"
    # 将 - 替换为 _，符合变量命名规范
    RADP_APP_NAME="${RADP_APP_NAME//-/_}"
    export RADP_APP_NAME
  fi

  # 1. 解析全局选项
  __radp_app_parse_global_options "$@"

  # 2. 配置路径
  __radp_app_setup_user_config_path
  __radp_app_setup_app_config_path

  # 3. 用户库路径
  __radp_app_setup_user_lib_paths

  # 4. Completion 命令检测
  __radp_app_check_completion_command

  # 5. 加载框架
  # shellcheck source=./init.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/init.sh"

  # 6. 配置应用
  __radp_app_configure_cli

  # 7. 命令分发
  __radp_app_dispatch
}

#######################################
# 执行入口
#######################################
__radp_app_main "$@"
