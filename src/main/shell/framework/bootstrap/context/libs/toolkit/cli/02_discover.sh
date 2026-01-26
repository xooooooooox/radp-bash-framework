#!/usr/bin/env bash
# toolkit module: cli/02_discover.sh
# 命令发现：扫描 commands/ 目录，自动发现命令和子命令

# 全局变量：存储已发现的命令
declare -gA __radp_cli_commands=()      # 命令路径映射：cmd_path -> file_path
declare -gA __radp_cli_cmd_meta=()      # 命令元数据缓存
declare -g __radp_cli_commands_dir=""   # 命令目录路径
declare -g __radp_cli_app_name=""       # 应用名称

#######################################
# 设置命令目录路径
# Arguments:
#   1 - commands_dir: commands/ 目录的绝对路径
# Returns:
#   0 - 成功
#   1 - 目录不存在
#######################################
radp_cli_set_commands_dir() {
    local commands_dir="$1"

    if [[ ! -d "$commands_dir" ]]; then
        radp_log_error "Commands directory not found: $commands_dir"
        return 1
    fi

    __radp_cli_commands_dir="$commands_dir"

    # Update IDE completion hints with commands directory
    radp_ide_add_commands_dir "$commands_dir"
}

#######################################
# 设置应用名称
# Arguments:
#   1 - app_name: 应用名称（如 homelabctl）
#######################################
radp_cli_set_app_name() {
    __radp_cli_app_name="$1"
}

#######################################
# 发现所有命令
# 扫描 commands/ 目录，识别命令和子命令
# 规则：
#   - commands/xxx.sh -> 顶级命令 xxx
#   - commands/xxx/yyy.sh -> 子命令 xxx yyy
#   - 以 _ 开头的文件被忽略（内部使用）
# Globals:
#   __radp_cli_commands_dir - 命令目录
#   __radp_cli_commands - 填充命令映射
# Returns:
#   0 - 成功
#   1 - 命令目录未设置
#######################################
radp_cli_discover() {
    [[ -n "$__radp_cli_commands_dir" ]] || {
        radp_log_error "Commands directory not set. Call radp_cli_set_commands_dir first."
        return 1
    }

    __radp_cli_commands=()

    local file rel_path cmd_path
    while IFS= read -r -d '' file; do
        # 获取相对路径
        rel_path="${file#"$__radp_cli_commands_dir"/}"

        # 跳过以 _ 开头的文件（内部使用）
        local basename="${rel_path##*/}"
        [[ "$basename" == _* ]] && continue

        # 验证是否是有效的命令文件（包含 @cmd 标记）
        if ! grep -q '^[[:space:]]*#[[:space:]]*@cmd' "$file" 2>/dev/null; then
            continue
        fi

        # 转换路径为命令路径
        # commands/vf/init.sh -> vf init
        # commands/version.sh -> version
        cmd_path="${rel_path%.sh}"
        cmd_path="${cmd_path//\// }"

        __radp_cli_commands["$cmd_path"]="$file"
    done < <(find "$__radp_cli_commands_dir" -type f -name "*.sh" -print0 | sort -z)

    return 0
}

#######################################
# 获取命令文件路径
# Arguments:
#   1 - cmd_path: 命令路径（如 "vf init"）
# Outputs:
#   命令文件的绝对路径
# Returns:
#   0 - 找到命令
#   1 - 命令不存在
#######################################
radp_cli_get_cmd_file() {
    local cmd_path="${1:-}"
    # 空路径返回失败
    [[ -z "$cmd_path" ]] && return 1

    local file="${__radp_cli_commands[$cmd_path]:-}"

    if [[ -n "$file" ]]; then
        echo "$file"
        return 0
    fi
    return 1
}

#######################################
# 检查命令是否存在
# Arguments:
#   1 - cmd_path: 命令路径
# Returns:
#   0 - 存在
#   1 - 不存在
#######################################
radp_cli_cmd_exists() {
    local cmd_path="${1:-}"
    # 空路径始终返回不存在
    [[ -n "$cmd_path" ]] && [[ -n "${__radp_cli_commands[$cmd_path]:-}" ]]
}

#######################################
# 获取所有顶级命令
# Outputs:
#   每行一个顶级命令名
#######################################
radp_cli_list_commands() {
    local cmd_path
    local -A seen=()

    for cmd_path in "${!__radp_cli_commands[@]}"; do
        # 提取顶级命令（第一个词）
        local top_cmd="${cmd_path%% *}"
        if [[ -z "${seen[$top_cmd]:-}" ]]; then
            echo "$top_cmd"
            seen[$top_cmd]=1
        fi
    done | sort
}

#######################################
# 获取指定命令的子命令
# Arguments:
#   1 - parent_cmd: 父命令（如 "vf"）
# Outputs:
#   每行一个子命令名
# Note:
#   也会输出命令组（如 "vf template" 会输出 "template"）
#######################################
radp_cli_list_subcommands() {
    local parent_cmd="$1"
    local cmd_path
    local -A seen=()

    for cmd_path in "${!__radp_cli_commands[@]}"; do
        # 检查是否以 parent_cmd 开头且有子命令
        if [[ "$cmd_path" == "$parent_cmd "* ]]; then
            # 提取剩余路径
            local remaining="${cmd_path#"$parent_cmd "}"
            # 提取直接子命令（第一个词）
            local sub="${remaining%% *}"
            # 去重输出
            if [[ -z "${seen[$sub]:-}" ]]; then
                echo "$sub"
                seen[$sub]=1
            fi
        fi
    done | sort
}

#######################################
# 检查命令是否有子命令
# Arguments:
#   1 - cmd: 命令名
# Returns:
#   0 - 有子命令
#   1 - 没有子命令
#######################################
radp_cli_has_subcommands() {
    local cmd="${1:-}"
    # 空命令返回没有子命令
    [[ -z "$cmd" ]] && return 1

    local cmd_path

    for cmd_path in "${!__radp_cli_commands[@]}"; do
        if [[ "$cmd_path" == "$cmd "* ]]; then
            return 0
        fi
    done
    return 1
}

#######################################
# 获取命令的元数据
# Arguments:
#   1 - cmd_path: 命令路径
#   2 - var_name: 存储结果的关联数组变量名
# Returns:
#   0 - 成功
#   1 - 命令不存在
#######################################
radp_cli_get_cmd_meta() {
    local cmd_path="$1"
    local -n __meta_out="$2"

    local file
    file="$(radp_cli_get_cmd_file "$cmd_path")" || return 1

    radp_cli_parse_meta "$file" __meta_out
}
