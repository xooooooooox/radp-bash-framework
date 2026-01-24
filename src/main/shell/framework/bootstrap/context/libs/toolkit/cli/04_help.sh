#!/usr/bin/env bash
# toolkit module: cli/04_help.sh
# 帮助生成：根据元数据自动生成帮助文本

#######################################
# 生成应用级帮助（顶级帮助）
# Outputs:
#   格式化的帮助文本
#######################################
radp_cli_help_app() {
    local app_name="${__radp_cli_app_name:-cli}"
    local app_desc="${__radp_cli_app_desc:-}"

    echo "$app_name${app_desc:+ - $app_desc}"
    echo
    echo "Usage:"
    echo "  $app_name <command> [options]"
    echo

    # 列出所有顶级命令
    local commands
    commands=$(radp_cli_list_commands)

    if [[ -n "$commands" ]]; then
        echo "Commands:"

        local cmd max_len=0
        # 计算最大命令长度
        while IFS= read -r cmd; do
            [[ ${#cmd} -gt $max_len ]] && max_len=${#cmd}
        done <<< "$commands"

        # 输出命令列表
        while IFS= read -r cmd; do
            local desc=""
            local -A meta=()

            # 尝试获取命令描述
            if radp_cli_cmd_exists "$cmd"; then
                radp_cli_get_cmd_meta "$cmd" meta 2>/dev/null || true
                desc="${meta[desc]:-}"
            elif radp_cli_has_subcommands "$cmd"; then
                # 如果是命令组（有子命令但没有自己的实现）
                desc="Manage $cmd"
            fi

            printf "  %-${max_len}s  %s\n" "$cmd" "$desc"
        done <<< "$commands"

        echo
    fi

    echo "Run '$app_name <command> --help' for more information on a command."
}

#######################################
# 生成命令组帮助（有子命令的命令）
# Arguments:
#   1 - cmd: 命令名
# Outputs:
#   格式化的帮助文本
#######################################
radp_cli_help_command_group() {
    local cmd="$1"
    local app_name="${__radp_cli_app_name:-cli}"

    # 尝试获取命令组描述
    local group_desc=""
    local -A meta=()
    if radp_cli_cmd_exists "$cmd"; then
        radp_cli_get_cmd_meta "$cmd" meta 2>/dev/null || true
        group_desc="${meta[desc]:-}"
    fi

    echo "${group_desc:-Manage $cmd}"
    echo
    echo "Usage:"
    echo "  $app_name $cmd <command> [options]"
    echo

    # 列出子命令
    local subcommands
    subcommands=$(radp_cli_list_subcommands "$cmd")

    if [[ -n "$subcommands" ]]; then
        echo "Commands:"

        local subcmd max_len=0
        while IFS= read -r subcmd; do
            [[ ${#subcmd} -gt $max_len ]] && max_len=${#subcmd}
        done <<< "$subcommands"

        while IFS= read -r subcmd; do
            local desc=""
            local -A sub_meta=()

            if radp_cli_get_cmd_meta "$cmd $subcmd" sub_meta 2>/dev/null; then
                desc="${sub_meta[desc]:-}"
            fi

            printf "  %-${max_len}s  %s\n" "$subcmd" "$desc"
        done <<< "$subcommands"

        echo
    fi

    echo "Run '$app_name $cmd <command> --help' for more information."
}

#######################################
# 生成具体命令的帮助
# Arguments:
#   1 - cmd_path: 命令路径（如 "vf init"）
# Outputs:
#   格式化的帮助文本
#######################################
radp_cli_help_command() {
    local cmd_path="$1"
    local app_name="${__radp_cli_app_name:-cli}"

    local -A meta=()
    if ! radp_cli_get_cmd_meta "$cmd_path" meta; then
        radp_log_error "Command not found: $cmd_path"
        return 1
    fi

    # 命令描述
    echo "${meta[desc]:-No description}"
    echo

    # Usage
    echo "Usage:"
    local usage_line="  $app_name $cmd_path"

    # 添加选项占位符
    if [[ -n "${meta[options]}" ]]; then
        usage_line+=" [options]"
    fi

    # 添加参数占位符
    if [[ -n "${meta[args]}" ]]; then
        local arg_line
        while IFS= read -r arg_line; do
            [[ -z "$arg_line" ]] && continue

            local -A arg_info=()
            radp_cli_parse_arg_spec "$arg_line" arg_info

            local arg_display="${arg_info[name]}"
            if [[ "${arg_info[variadic]}" == "true" ]]; then
                arg_display="[$arg_display...]"
            elif [[ "${arg_info[required]}" == "true" ]]; then
                arg_display="<$arg_display>"
            else
                arg_display="[$arg_display]"
            fi

            usage_line+=" $arg_display"
        done <<< "${meta[args]}"
    fi

    echo "$usage_line"
    echo

    # Arguments
    if [[ -n "${meta[args]}" ]]; then
        echo "Arguments:"

        local arg_line max_len=0
        while IFS= read -r arg_line; do
            [[ -z "$arg_line" ]] && continue
            local -A arg_info=()
            radp_cli_parse_arg_spec "$arg_line" arg_info
            [[ ${#arg_info[name]} -gt $max_len ]] && max_len=${#arg_info[name]}
        done <<< "${meta[args]}"

        while IFS= read -r arg_line; do
            [[ -z "$arg_line" ]] && continue
            local -A arg_info=()
            radp_cli_parse_arg_spec "$arg_line" arg_info

            local modifier=""
            if [[ "${arg_info[required]}" == "true" ]]; then
                modifier=" (required)"
            elif [[ "${arg_info[variadic]}" == "true" ]]; then
                modifier=" (multiple)"
            fi

            printf "  %-${max_len}s  %s%s\n" "${arg_info[name]}" "${arg_info[desc]}" "$modifier"
        done <<< "${meta[args]}"

        echo
    fi

    # Options
    if [[ -n "${meta[options]}" ]]; then
        echo "Options:"

        local opt_line
        while IFS= read -r opt_line; do
            [[ -z "$opt_line" ]] && continue

            local -A opt_info=()
            radp_cli_parse_option_spec "$opt_line" opt_info

            local opt_display=""
            if [[ -n "${opt_info[short]}" ]]; then
                opt_display="-${opt_info[short]}"
                [[ -n "${opt_info[long]}" ]] && opt_display+=", "
            fi
            if [[ -n "${opt_info[long]}" ]]; then
                opt_display+="--${opt_info[long]}"
            fi
            if [[ -n "${opt_info[value_name]}" ]]; then
                opt_display+=" <${opt_info[value_name]}>"
            fi

            local desc="${opt_info[desc]}"
            if [[ -n "${opt_info[default]}" ]]; then
                desc+=" [default: ${opt_info[default]}]"
            fi

            printf "  %-24s  %s\n" "$opt_display" "$desc"
        done <<< "${meta[options]}"

        echo
    fi

    # 内置选项
    echo "  -h, --help              Show this help message"
    echo

    # Examples
    if [[ -n "${meta[examples]}" ]]; then
        echo "Examples:"

        local example
        while IFS= read -r example; do
            [[ -z "$example" ]] && continue
            echo "  $app_name $example"
        done <<< "${meta[examples]}"

        echo
    fi
}

#######################################
# 自动生成帮助（根据上下文）
# Arguments:
#   @ - 命令路径参数
# Outputs:
#   适当的帮助文本
#######################################
radp_cli_help() {
    local cmd_path="${*:-}"

    if [[ -z "$cmd_path" ]]; then
        # 顶级帮助
        radp_cli_help_app
    elif radp_cli_cmd_exists "$cmd_path"; then
        # 具体命令帮助
        radp_cli_help_command "$cmd_path"
    elif radp_cli_has_subcommands "$cmd_path"; then
        # 命令组帮助
        radp_cli_help_command_group "$cmd_path"
    else
        radp_log_error "Unknown command: $cmd_path"
        echo
        radp_cli_help_app
        return 1
    fi
}
