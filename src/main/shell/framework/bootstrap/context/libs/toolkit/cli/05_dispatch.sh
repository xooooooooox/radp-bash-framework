#!/usr/bin/env bash
# toolkit module: cli/05_dispatch.sh
# 命令路由：解析参数并路由到对应的命令函数

#######################################
# 主分发函数：解析命令行并路由到对应命令
# Arguments:
#   @ - 命令行参数
# Returns:
#   命令的返回码
#######################################
radp_cli_dispatch() {
    local -a args=("$@")

    # 处理无参数情况
    if [[ ${#args[@]} -eq 0 ]]; then
        radp_cli_help_app
        return 0
    fi

    # 处理全局选项
    case "${args[0]}" in
        -h|--help)
            radp_cli_help_app
            return 0
            ;;
        --version)
            if declare -F radp_app_version &>/dev/null; then
                radp_app_version
            else
                echo "${__radp_cli_app_name:-cli} ${__radp_cli_app_version:-unknown}"
            fi
            return 0
            ;;
    esac

    # 查找匹配的命令
    local cmd_path=""
    local cmd_args=()
    local longest_group=""  # 跟踪最长匹配的命令组路径
    local i=0

    # 逐步构建命令路径，找到最长匹配
    local test_path=""
    for ((i = 0; i < ${#args[@]}; i++)); do
        local arg="${args[$i]}"

        # 遇到选项则停止命令路径解析
        [[ "$arg" == -* ]] && break

        if [[ -z "$test_path" ]]; then
            test_path="$arg"
        else
            test_path="$test_path $arg"
        fi

        # 检查是否是有效命令
        if radp_cli_cmd_exists "$test_path"; then
            cmd_path="$test_path"
            cmd_args=("${args[@]:$((i + 1))}")
        elif radp_cli_has_subcommands "$test_path"; then
            # 是命令组，记录最长匹配的命令组路径
            longest_group="$test_path"
        else
            # 既不是命令也不是命令组，停止搜索
            break
        fi
    done

    # 未找到命令
    if [[ -z "$cmd_path" ]]; then
        # 优先使用最长匹配的命令组路径
        local target_group="${longest_group:-${args[0]}}"

        # 检查是否是命令组（有子命令但自身没有实现）
        if radp_cli_has_subcommands "$target_group"; then
            # 检查是否请求帮助（检查命令组路径后的下一个参数）
            local group_depth
            group_depth=$(echo "$target_group" | wc -w | tr -d ' ')
            local next_arg="${args[$group_depth]:-}"
            if [[ "$next_arg" == "-h" || "$next_arg" == "--help" ]]; then
                radp_cli_help_command_group "$target_group"
                return 0
            fi

            radp_log_error "Missing subcommand for: $target_group"
            echo
            radp_cli_help_command_group "$target_group"
            return 1
        fi

        radp_log_error "Unknown command: ${args[0]}"
        echo
        radp_cli_help_app
        return 1
    fi

    # 执行命令
    __radp_cli_execute_cmd "$cmd_path" "${cmd_args[@]}"
}

#######################################
# 执行具体命令
# Arguments:
#   1 - cmd_path: 命令路径
#   @ - 命令参数
# Returns:
#   命令的返回码
#######################################
__radp_cli_execute_cmd() {
    local cmd_path="$1"
    shift
    local -a cmd_args=("$@")

    local cmd_file
    cmd_file=$(radp_cli_get_cmd_file "$cmd_path") || {
        radp_log_error "Command file not found: $cmd_path"
        return 1
    }

    # 获取元数据
    local -A meta=()
    radp_cli_get_cmd_meta "$cmd_path" meta || {
        radp_log_error "Failed to parse command metadata: $cmd_path"
        return 1
    }

    # 检查是否是透传模式
    local passthrough=false
    if [[ "${meta[metas]}" == *passthrough* ]]; then
        passthrough=true
    fi

    if [[ "$passthrough" == "true" ]]; then
        # 透传模式：只检查 --help，其他参数直接传递
        if [[ "${cmd_args[0]:-}" == "-h" || "${cmd_args[0]:-}" == "--help" ]]; then
            radp_cli_help_command "$cmd_path"
            return 0
        fi

        # 加载命令文件
        # shellcheck source=/dev/null
        source "$cmd_file"

        # 获取函数名
        local func_name
        func_name=$(radp_cli_extract_cmd_func "$cmd_file") || {
            radp_log_error "No cmd_* function found in: $cmd_file"
            return 1
        }

        # 直接传递所有参数给命令函数
        "cmd_$func_name" "${cmd_args[@]}"
    else
        # 正常模式：解析参数
        if ! radp_cli_parse_args "${meta[options]}" "${meta[args]}" "${cmd_args[@]}"; then
            echo
            radp_cli_help_command "$cmd_path"
            return 1
        fi

        # 检查是否请求帮助
        if [[ "$__radp_cli_show_help" == "true" ]]; then
            radp_cli_help_command "$cmd_path"
            return 0
        fi

        # 加载命令文件
        # shellcheck source=/dev/null
        source "$cmd_file"

        # 获取函数名
        local func_name
        func_name=$(radp_cli_extract_cmd_func "$cmd_file") || {
            radp_log_error "No cmd_* function found in: $cmd_file"
            return 1
        }

        # 执行命令函数
        "cmd_$func_name" "${__radp_cli_positional_args[@]}"
    fi
}

#######################################
# 获取当前命令路径（供命令内部使用）
# Outputs:
#   当前执行的命令路径
#######################################
radp_cli_current_cmd() {
    echo "${__radp_cli_current_cmd:-}"
}
