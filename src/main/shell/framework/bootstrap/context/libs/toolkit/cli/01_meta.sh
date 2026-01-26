#!/usr/bin/env bash
# toolkit module: cli/01_meta.sh
# 元数据解析：从命令文件注释中提取 @cmd, @desc, @arg, @option, @example, @complete, @meta 等

#######################################
# 从命令文件中解析元数据
# 支持的元数据标记：
#   @cmd              - 声明这是一个命令
#   @desc <text>      - 命令描述
#   @arg <name>       - 位置参数（可选）
#   @arg <name>!      - 位置参数（必填）
#   @arg <name>~      - 剩余参数（收集所有）
#   @option -s, --long <value>  - 选项参数
#   @option ... [default: x]    - 带默认值
#   @example <text>   - 使用示例
#   @complete <name> <func>     - 动态补全函数（name 为参数名或选项长名）
#   @meta passthrough - 透传模式：跳过参数解析，所有参数直接传递给命令函数
# Arguments:
#   1 - file_path: 命令文件路径
#   2 - var_name: 存储结果的关联数组变量名
# Outputs:
#   通过 nameref 填充关联数组
# Returns:
#   0 - 成功解析
#   1 - 文件不存在或不是命令文件
#######################################
radp_cli_parse_meta() {
  local file_path="$1"
  local -n __meta_ref="$2"

  [[ -f "$file_path" ]] || return 1

  local line
  local in_meta_block=false
  local desc=""
  local -a args=()
  local -a options=()
  local -a examples=()
  local -a completes=()
  local -a metas=()
  local is_cmd=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过空行和非注释行
    if [[ ! "$line" =~ ^[[:space:]]*# ]]; then
      # 遇到非注释行且已经开始解析，则停止
      [[ "$in_meta_block" == true ]] && break
      continue
    fi

    # 提取注释内容（去掉 # 前缀）
    line="${line#*#}"
    line="${line# }" # 去掉前导空格

    case "$line" in
    @cmd*)
      is_cmd=true
      in_meta_block=true
      ;;
    @desc\ *)
      desc="${line#@desc }"
      ;;
    @arg\ *)
      args+=("${line#@arg }")
      ;;
    @option\ *)
      options+=("${line#@option }")
      ;;
    @example\ *)
      examples+=("${line#@example }")
      ;;
    @complete\ *)
      completes+=("${line#@complete }")
      ;;
    @meta\ *)
      metas+=("${line#@meta }")
      ;;
    esac
  done <"$file_path"

  [[ "$is_cmd" == true ]] || return 1

  __meta_ref[is_cmd]="true"
  __meta_ref[desc]="$desc"
  __meta_ref[args]="$(printf '%s\n' "${args[@]}")"
  __meta_ref[options]="$(printf '%s\n' "${options[@]}")"
  __meta_ref[examples]="$(printf '%s\n' "${examples[@]}")"
  __meta_ref[completes]="$(printf '%s\n' "${completes[@]}")"
  __meta_ref[metas]="$(printf '%s\n' "${metas[@]}")"

  return 0
}

#######################################
# 解析单个 @arg 声明
# 格式：
#   name       - 可选参数
#   name!      - 必填参数
#   name~      - 剩余参数（收集所有）
#   后跟空格和描述
# Arguments:
#   1 - arg_spec: @arg 后面的内容
#   2 - var_name: 存储结果的关联数组变量名
# Returns:
#   0 - 成功
#######################################
radp_cli_parse_arg_spec() {
  local arg_spec="$1"
  local -n __arg_ref="$2"

  local name desc required=false variadic=false

  # 提取参数名（第一个空格之前的部分）
  name="${arg_spec%% *}"
  # 提取描述（第一个空格之后的部分）
  if [[ "$arg_spec" == *" "* ]]; then
    desc="${arg_spec#* }"
  else
    desc=""
  fi

  # 检查修饰符
  if [[ "$name" == *"!" ]]; then
    name="${name%!}"
    required=true
  elif [[ "$name" == *"~" ]]; then
    name="${name%~}"
    variadic=true
  fi

  __arg_ref[name]="$name"
  __arg_ref[desc]="$desc"
  __arg_ref[required]="$required"
  __arg_ref[variadic]="$variadic"
}

#######################################
# 解析单个 @option 声明
# 格式：
#   -s, --long <value>  Description [default: x]
#   -s, --long          Boolean flag
#   --long <value>      Long only
# Arguments:
#   1 - opt_spec: @option 后面的内容
#   2 - var_name: 存储结果的关联数组变量名
# Returns:
#   0 - 成功
#######################################
radp_cli_parse_option_spec() {
  local opt_spec="$1"
  local -n __opt_ref="$2"

  local short="" long="" value_name="" desc="" default="" required=false

  # 提取默认值 [default: xxx]
  if [[ "$opt_spec" =~ \[default:[[:space:]]*([^]]+)\] ]]; then
    default="${BASH_REMATCH[1]}"
    opt_spec="${opt_spec/\[default:*\]/}"
  fi

  # 提取短选项 -x
  if [[ "$opt_spec" =~ -([a-zA-Z]),? ]]; then
    short="${BASH_REMATCH[1]}"
  fi

  # 提取长选项 --xxx
  if [[ "$opt_spec" =~ --([a-zA-Z][-a-zA-Z0-9]*) ]]; then
    long="${BASH_REMATCH[1]}"
  fi

  # 提取值名称 <xxx>
  if [[ "$opt_spec" =~ \<([^>]+)\> ]]; then
    value_name="${BASH_REMATCH[1]}"
  fi

  # 提取描述（去掉选项部分后的内容）
  # 先移除选项定义部分，剩下的是描述
  local pattern="^[[:space:]]*(-[a-zA-Z],?[[:space:]]*)?--[a-zA-Z][-a-zA-Z0-9]*([[:space:]]+<[^>]+>)?[[:space:]]+"
  if [[ "$opt_spec" =~ $pattern ]]; then
    desc="${opt_spec:${#BASH_REMATCH[0]}}"
    # 清理描述中可能残留的默认值标记
    desc="${desc/\[default:*\]/}"
    desc="${desc#"${desc%%[![:space:]]*}"}" # trim leading
    desc="${desc%"${desc##*[![:space:]]}"}" # trim trailing
  fi

  __opt_ref[short]="$short"
  __opt_ref[long]="$long"
  __opt_ref[value_name]="$value_name"
  __opt_ref[desc]="$desc"
  __opt_ref[default]="$default"
  __opt_ref[has_value]="$([[ -n "$value_name" ]] && echo true || echo false)"
}

#######################################
# 解析单个 @complete 声明
# 格式：
#   <name> <function>
#   name 可以是参数名或选项长名
# Arguments:
#   1 - complete_spec: @complete 后面的内容
#   2 - var_name: 存储结果的关联数组变量名
# Returns:
#   0 - 成功
#######################################
radp_cli_parse_complete_spec() {
  local complete_spec="$1"
  local -n __complete_ref="$2"

  local name func

  # 提取名称和函数
  name="${complete_spec%% *}"
  if [[ "$complete_spec" == *" "* ]]; then
    func="${complete_spec#* }"
    func="${func%% *}" # 只取第一个词作为函数名
  else
    func=""
  fi

  __complete_ref[name]="$name"
  __complete_ref[func]="$func"
}

#######################################
# 获取参数或选项的补全函数
# Arguments:
#   1 - name: 参数名或选项长名
#   2 - completes: 补全规格（换行分隔）
# Outputs:
#   补全函数名，如果没有则无输出
# Returns:
#   0 - 找到
#   1 - 未找到
#######################################
radp_cli_get_complete_func() {
  local name="$1"
  local completes="$2"

  local complete_line
  while IFS= read -r complete_line; do
    [[ -z "$complete_line" ]] && continue
    local -A complete_info=()
    radp_cli_parse_complete_spec "$complete_line" complete_info
    if [[ "${complete_info[name]}" == "$name" ]]; then
      echo "${complete_info[func]}"
      return 0
    fi
  done <<<"$completes"

  return 1
}

#######################################
# 从命令文件中提取函数名
# 查找 cmd_xxx() 形式的函数定义
# Arguments:
#   1 - file_path: 命令文件路径
# Outputs:
#   函数名（不含 cmd_ 前缀）
# Returns:
#   0 - 找到函数
#   1 - 未找到
#######################################
radp_cli_extract_cmd_func() {
  local file_path="$1"

  [[ -f "$file_path" ]] || return 1

  local line
  while IFS= read -r line; do
    # 匹配 cmd_xxx() 或 function cmd_xxx
    if [[ "$line" =~ ^[[:space:]]*(function[[:space:]]+)?cmd_([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\) ]]; then
      echo "${BASH_REMATCH[2]}"
      return 0
    fi
  done <"$file_path"

  return 1
}
