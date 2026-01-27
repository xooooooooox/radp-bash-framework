#!/usr/bin/env bash
# radp-bash-framework app launcher
# 为 CLI 应用提供完整的初始化和运行支持
# 入口脚本通过 source 此文件启动应用
#
# 必需环境变量（入口脚本设置）：
#   RADP_APP_ROOT  - 项目根目录
#   RADP_APP_NAME  - 应用名称
#
# 可选环境变量（入口脚本可设置）：
#   RADP_APP_GLOBAL_OPTIONS - 全局选项列表（空格分隔）
#   RADP_APP_COMMANDS_DIR   - 命令目录（默认 $RADP_APP_ROOT/src/main/shell/commands）

# 验证必需的环境变量
: "${RADP_APP_ROOT:?RADP_APP_ROOT must be set before sourcing launcher.sh}"
: "${RADP_APP_NAME:?RADP_APP_NAME must be set before sourcing launcher.sh}"

# --------------------------------------------------------------------------- #
# 1. 解析全局选项（-v/--verbose, --debug 等）
# --------------------------------------------------------------------------- #
declare -ga __radp_app_filtered_args=()

__radp_app_parse_global_options() {
  __radp_app_filtered_args=()
  local verbose=false
  local debug=false
  local found_command=false

  # 构建全局选项集合用于快速查找
  local -A global_opts=()
  if [[ -n "${RADP_APP_GLOBAL_OPTIONS:-}" ]]; then
    local opt
    for opt in $RADP_APP_GLOBAL_OPTIONS; do
      global_opts["$opt"]=1
    done
  fi

  while [[ $# -gt 0 ]]; do
    # 一旦遇到非选项参数（子命令），后续所有参数都传递给子命令
    if [[ "$found_command" == "true" ]]; then
      __radp_app_filtered_args+=("$1")
      shift
      continue
    fi

    case "$1" in
    -v | --verbose)
      if [[ -n "${global_opts[-v]:-}${global_opts[--verbose]:-}" ]]; then
        verbose=true
        shift
      else
        __radp_app_filtered_args+=("$1")
        shift
      fi
      ;;
    --debug)
      if [[ -n "${global_opts[--debug]:-}" ]]; then
        debug=true
        shift
      else
        __radp_app_filtered_args+=("$1")
        shift
      fi
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

  # 设置输出模式环境变量
  if [[ "$debug" == "true" ]]; then
    # Debug 模式: banner on, log level debug, debug enabled
    export GX_RADP_FW_BANNER_MODE=on
    export GX_RADP_FW_LOG_LEVEL=debug
    export GX_RADP_FW_LOG_DEBUG=true
  elif [[ "$verbose" == "true" ]]; then
    # Verbose 模式: banner on, log level info
    export GX_RADP_FW_BANNER_MODE=on
    export GX_RADP_FW_LOG_LEVEL=info
  else
    # 默认模式: banner off, log level error (只显示错误)
    export GX_RADP_FW_BANNER_MODE=off
    export GX_RADP_FW_LOG_LEVEL=error
  fi
}

__radp_app_parse_global_options "$@"

# --------------------------------------------------------------------------- #
# 2. Config 路径自动检测（开发态 vs 安装态）
# --------------------------------------------------------------------------- #
if [[ -d "$RADP_APP_ROOT/src/main/shell/config" ]]; then
  export GX_RADP_FW_USER_CONFIG_PATH="$RADP_APP_ROOT/src/main/shell/config"
else
  export GX_RADP_FW_USER_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/$RADP_APP_NAME"
fi

# --------------------------------------------------------------------------- #
# 3. User lib 路径
# --------------------------------------------------------------------------- #
if [[ -d "$RADP_APP_ROOT/src/main/shell/libs" ]]; then
  export GX_RADP_FW_USER_LIB_PATH="$RADP_APP_ROOT/src/main/shell/libs"
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

if [[ -n "${RADP_APP_GLOBAL_OPTIONS:-}" ]]; then
  # shellcheck disable=SC2086
  radp_cli_set_global_options $RADP_APP_GLOBAL_OPTIONS
fi

# --------------------------------------------------------------------------- #
# 7. Dispatch
# --------------------------------------------------------------------------- #
if [[ ${#__radp_app_filtered_args[@]} -eq 0 ]]; then
  radp_app_run --help
else
  radp_app_run "${__radp_app_filtered_args[@]}"
fi
