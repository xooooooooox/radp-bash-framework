#!/usr/bin/env bash
# toolkit module: cli/03_parse.sh
# 参数解析：根据元数据解析命令行参数

# 全局变量用于返回 getopt 规格
declare -g __radp_cli_getopt_short=""
declare -g __radp_cli_getopt_long=""

#######################################
# 根据元数据构建 getopt 选项字符串
# Arguments:
#   1 - options_spec: @option 声明列表（换行分隔）
# Globals:
#   __radp_cli_getopt_short - 设置短选项字符串
#   __radp_cli_getopt_long - 设置长选项字符串
# Returns:
#   0 - 成功
#######################################
radp_cli_build_getopt_spec() {
    local options_spec="$1"

    __radp_cli_getopt_short=""
    __radp_cli_getopt_long=""
    local line

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local -A opt_info=()
        radp_cli_parse_option_spec "$line" opt_info

        # 构建短选项
        if [[ -n "${opt_info[short]}" ]]; then
            __radp_cli_getopt_short+="${opt_info[short]}"
            [[ "${opt_info[has_value]}" == "true" ]] && __radp_cli_getopt_short+=":"
        fi

        # 构建长选项
        if [[ -n "${opt_info[long]}" ]]; then
            [[ -n "$__radp_cli_getopt_long" ]] && __radp_cli_getopt_long+=","
            __radp_cli_getopt_long+="${opt_info[long]}"
            [[ "${opt_info[has_value]}" == "true" ]] && __radp_cli_getopt_long+=":"
        fi
    done <<< "$options_spec"

    # 添加内置选项
    __radp_cli_getopt_short+="h"
    __radp_cli_getopt_long="${__radp_cli_getopt_long:+$__radp_cli_getopt_long,}help"
}

#######################################
# 解析命令行参数
# 根据元数据解析参数，设置 opt_xxx 和位置参数变量
# Arguments:
#   1 - options_spec: @option 声明列表
#   2 - args_spec: @arg 声明列表
#   @ - 命令行参数
# Globals:
#   opt_* - 设置选项变量
#   __radp_cli_positional_args - 设置位置参数数组
#   __radp_cli_show_help - 是否显示帮助
# Returns:
#   0 - 解析成功
#   1 - 解析失败
#######################################
radp_cli_parse_args() {
    local options_spec="$1"
    local args_spec="$2"
    shift 2

    # 清理旧的选项变量
    local var
    for var in $(compgen -v opt_); do
        unset "$var"
    done

    __radp_cli_positional_args=()
    __radp_cli_show_help=false

    # 设置默认值
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local -A opt_info=()
        radp_cli_parse_option_spec "$line" opt_info

        if [[ -n "${opt_info[default]}" && -n "${opt_info[long]}" ]]; then
            local var_name="opt_${opt_info[long]//-/_}"
            declare -g "$var_name=${opt_info[default]}"
        fi
    done <<< "$options_spec"

    # 如果没有参数，直接返回
    [[ $# -eq 0 ]] && return 0

    # 构建 getopt 规格
    radp_cli_build_getopt_spec "$options_spec"

    # 使用 getopt 解析
    local parsed
    if ! parsed=$(getopt -o "$__radp_cli_getopt_short" -l "$__radp_cli_getopt_long" -n "${__radp_cli_app_name:-cli}" -- "$@" 2>&1); then
        radp_log_error "$parsed"
        return 1
    fi

    eval set -- "$parsed"

    # 构建选项映射：短选项 -> 长选项
    local -A short_to_long=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local -A opt_info=()
        radp_cli_parse_option_spec "$line" opt_info
        if [[ -n "${opt_info[short]}" && -n "${opt_info[long]}" ]]; then
            short_to_long["-${opt_info[short]}"]="${opt_info[long]}"
        fi
    done <<< "$options_spec"

    # 处理解析后的参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                __radp_cli_show_help=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                local opt_name="$1"
                local long_name

                # 转换短选项为长选项名
                if [[ "$opt_name" == -? ]]; then
                    long_name="${short_to_long[$opt_name]:-}"
                    if [[ -z "$long_name" ]]; then
                        # 未知短选项，跳过
                        shift
                        continue
                    fi
                else
                    long_name="${opt_name#--}"
                fi

                local var_name="opt_${long_name//-/_}"

                # 检查是否需要值
                local needs_value=false
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    local -A opt_info=()
                    radp_cli_parse_option_spec "$line" opt_info
                    if [[ "${opt_info[long]}" == "$long_name" ]]; then
                        needs_value="${opt_info[has_value]}"
                        break
                    fi
                done <<< "$options_spec"

                if [[ "$needs_value" == "true" ]]; then
                    shift
                    declare -g "$var_name=$1"
                else
                    declare -g "$var_name=true"
                fi
                shift
                ;;
            *)
                __radp_cli_positional_args+=("$1")
                shift
                ;;
        esac
    done

    # 收集剩余的位置参数
    while [[ $# -gt 0 ]]; do
        __radp_cli_positional_args+=("$1")
        shift
    done

    # 验证必填参数
    local arg_index=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local -A arg_info=()
        radp_cli_parse_arg_spec "$line" arg_info

        if [[ "${arg_info[required]}" == "true" ]]; then
            if [[ $arg_index -ge ${#__radp_cli_positional_args[@]} ]]; then
                radp_log_error "Missing required argument: ${arg_info[name]}"
                return 1
            fi
        fi

        ((arg_index++)) || true
    done <<< "$args_spec"

    return 0
}

#######################################
# 获取位置参数
# Arguments:
#   1 - index: 参数索引（从 0 开始）
#   2 - default: 默认值（可选）
# Outputs:
#   参数值或默认值
#######################################
radp_cli_get_arg() {
    local index="$1"
    local default="${2:-}"

    if [[ $index -lt ${#__radp_cli_positional_args[@]} ]]; then
        echo "${__radp_cli_positional_args[$index]}"
    else
        echo "$default"
    fi
}

#######################################
# 获取所有位置参数
# Outputs:
#   所有位置参数，空格分隔
#######################################
radp_cli_get_all_args() {
    echo "${__radp_cli_positional_args[*]}"
}

#######################################
# 获取剩余位置参数（从指定索引开始）
# Arguments:
#   1 - start_index: 起始索引
# Outputs:
#   剩余参数，每行一个
#######################################
radp_cli_get_remaining_args() {
    local start_index="$1"
    local i

    for ((i = start_index; i < ${#__radp_cli_positional_args[@]}; i++)); do
        echo "${__radp_cli_positional_args[$i]}"
    done
}
