#!/usr/bin/env bash
# radp-bash-framework app launcher
# 为 CLI 应用提供完整的初始化和运行支持
# 入口脚本通过 source 此文件启动应用
#
# 必需环境变量（入口脚本设置）：
#   RADP_APP_ROOT  - 项目根目录
#
# 可选环境变量（入口脚本可设置）：
#   RADP_APP_NAME         - 应用名称（默认从 RADP_APP_ROOT 目录名派生）
#   RADP_APP_COMMANDS_DIR - 命令目录（默认 $RADP_APP_ROOT/src/main/shell/commands）

# 验证必需的环境变量
: "${RADP_APP_ROOT:?RADP_APP_ROOT must be set before sourcing launcher.sh}"

# 自动派生应用名称（如未设置）
if [[ -z "${RADP_APP_NAME:-}" ]]; then
  RADP_APP_NAME="$(basename "$RADP_APP_ROOT")"
  # 将 - 替换为 _，符合变量命名规范
  RADP_APP_NAME="${RADP_APP_NAME//-/_}"
  export RADP_APP_NAME
fi

# --------------------------------------------------------------------------- #
# 1. 解析全局选项（-v/--verbose, --debug 等）
# --------------------------------------------------------------------------- #
declare -ga __radp_app_filtered_args=()

__radp_app_parse_global_options() {
  __radp_app_filtered_args=()
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
      __radp_app_filtered_args+=("$1")
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
        __radp_app_filtered_args+=("$1")
      fi
      shift
      ;;
    --all)
      # Only valid after --config
      if [[ "$show_config" == "true" ]]; then
        config_all=true
      else
        __radp_app_filtered_args+=("$1")
      fi
      shift
      ;;
    --)
      shift
      __radp_app_filtered_args+=("$@")
      break
      ;;
    -*)
      # 未知选项，保留传递
      __radp_app_filtered_args+=("$1")
      shift
      ;;
    *)
      # 遇到子命令，标记后续参数直接传递
      found_command=true
      __radp_app_filtered_args+=("$1")
      shift
      ;;
    esac
  done

  # 设置 --config 模式
  if [[ "$show_config" == "true" ]]; then
    export __RADP_APP_SHOW_CONFIG=true
    [[ "$config_json" == "true" ]] && export __RADP_APP_CONFIG_JSON=true
    [[ "$config_all" == "true" ]] && export __RADP_APP_CONFIG_ALL=true
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

__radp_app_parse_global_options "$@"

# --------------------------------------------------------------------------- #
# 2. Config 路径
# --------------------------------------------------------------------------- #
# Development mode detection: if _ide.sh exists, use source config path
# Otherwise (installed mode), use XDG config path
if [[ -z "${GX_RADP_FW_USER_CONFIG_PATH:-}" ]]; then
  if [[ -f "$RADP_APP_ROOT/src/main/shell/config/_ide.sh" ]]; then
    # Development mode - use source config
    export GX_RADP_FW_USER_CONFIG_PATH="$RADP_APP_ROOT/src/main/shell/config"
  else
    # Installed mode - use XDG config
    export GX_RADP_FW_USER_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/$RADP_APP_NAME"
  fi
fi

# --------------------------------------------------------------------------- #
# 2.1 App config 路径（应用内置配置，始终指向源码目录）
# --------------------------------------------------------------------------- #
if [[ -z "${GX_RADP_FW_APP_CONFIG_PATH:-}" ]]; then
  export GX_RADP_FW_APP_CONFIG_PATH="$RADP_APP_ROOT/src/main/shell/config"
fi

# --------------------------------------------------------------------------- #
# 3. User lib 路径
# --------------------------------------------------------------------------- #
if [[ -d "$RADP_APP_ROOT/src/main/shell/libs" ]]; then
  export GX_RADP_FW_USER_LIB_PATHS="${RADP_APP_ROOT}/src/main/shell/libs:${GX_RADP_FW_USER_LIB_PATHS:-}"
fi

# --------------------------------------------------------------------------- #
# 4. Completion 命令检测（禁用 banner/log）
# --------------------------------------------------------------------------- #
if [[ "${__radp_app_filtered_args[0]:-}" == "completion" ]]; then
  export GX_RADP_FW_BANNER_MODE=off
  export GX_RADP_FW_LOG_CONSOLE_ENABLED=false
fi

# --------------------------------------------------------------------------- #
# 5. 加载框架
# --------------------------------------------------------------------------- #
# shellcheck source=./init.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/init.sh"

# --------------------------------------------------------------------------- #
# 6. 配置应用
# --------------------------------------------------------------------------- #
radp_cli_set_app_name "$RADP_APP_NAME"

__radp_app_commands_dir="${RADP_APP_COMMANDS_DIR:-$RADP_APP_ROOT/src/main/shell/commands}"
radp_cli_set_commands_dir "$__radp_app_commands_dir"
unset __radp_app_commands_dir

# 设置默认全局选项（用于帮助和补全）
radp_cli_set_global_options "-q" "--quiet" "-v" "--verbose" "--debug" "--config" "--all" "--json"

# --------------------------------------------------------------------------- #
# 7. Dispatch
# --------------------------------------------------------------------------- #
# Handle --config option
if [[ "${__RADP_APP_SHOW_CONFIG:-}" == "true" ]]; then
  radp_app_show_config
  exit 0
fi

if [[ ${#__radp_app_filtered_args[@]} -eq 0 ]]; then
  radp_app_run --help
else
  radp_app_run "${__radp_app_filtered_args[@]}"
fi
