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
