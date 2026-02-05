#!/usr/bin/env bash
# toolkit module: cli/05b_app_global_options.sh
# 应用级全局选项：支持应用通过 _globals.sh 定义全局选项

# 全局变量：存储应用级全局选项定义
declare -g __radp_cli_app_global_options=""     # 应用级全局选项列表（用于补全）
declare -ga __radp_cli_app_global_options_spec=()  # 应用级全局选项规格数组

#######################################
# 加载应用级全局选项定义
# 从 commands/_globals.sh 文件中读取 @global 注解
# Globals:
#   __radp_cli_commands_dir - 命令目录
#   __radp_cli_app_global_options - 输出：应用级全局选项列表
#   __radp_cli_app_global_options_spec - 输出：应用级全局选项规格
# Returns:
#   0 - 成功（即使文件不存在也返回成功）
#######################################
radp_cli_load_app_global_options() {
  __radp_cli_app_global_options=""
  __radp_cli_app_global_options_spec=()

  local globals_file="${__radp_cli_commands_dir:-}/_globals.sh"
  [[ -f "$globals_file" ]] || return 0

  local line
  local -a options_list=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过空行和非注释行
    if [[ ! "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    # 提取注释内容（去掉 # 前缀）
    line="${line#*#}"
    line="${line# }" # 去掉前导空格

    case "$line" in
    @global\ *)
      local spec="${line#@global }"
      __radp_cli_app_global_options_spec+=("$spec")

      # 解析选项提取短选项和长选项
      local -A opt_info=()
      radp_cli_parse_option_spec "$spec" opt_info
      [[ -n "${opt_info[short]}" ]] && options_list+=("-${opt_info[short]}")
      [[ -n "${opt_info[long]}" ]] && options_list+=("--${opt_info[long]}")
      ;;
    esac
  done <"$globals_file"

  __radp_cli_app_global_options="${options_list[*]}"
}

#######################################
# 解析应用级全局选项（从参数数组中提取）
# 支持命令前位置的全局选项解析
# Arguments:
#   1 - var_name: 输入/输出参数数组的变量名（nameref）
# Globals:
#   __radp_cli_app_global_options_spec - 应用级全局选项规格
#   gopt_* - 输出：解析后的全局选项值
# Returns:
#   0 - 成功
#######################################
radp_cli_parse_app_global_options() {
  local -n __args_ref="$1"

  # 没有定义应用级全局选项，直接返回
  [[ ${#__radp_cli_app_global_options_spec[@]} -eq 0 ]] && return 0

  # 构建选项映射：短选项 -> 长选项，以及选项是否需要值
  local -A short_to_long=()
  local -A opt_has_value=()
  local spec
  for spec in "${__radp_cli_app_global_options_spec[@]}"; do
    local -A opt_info=()
    radp_cli_parse_option_spec "$spec" opt_info
    if [[ -n "${opt_info[short]}" && -n "${opt_info[long]}" ]]; then
      short_to_long["-${opt_info[short]}"]="${opt_info[long]}"
    fi
    if [[ -n "${opt_info[long]}" ]]; then
      opt_has_value["--${opt_info[long]}"]="${opt_info[has_value]}"
      [[ -n "${opt_info[short]}" ]] && opt_has_value["-${opt_info[short]}"]="${opt_info[has_value]}"
    fi

    # 设置默认值
    if [[ -n "${opt_info[default]}" && -n "${opt_info[long]}" ]]; then
      local var_name="gopt_${opt_info[long]//-/_}"
      declare -g "$var_name=${opt_info[default]}"
    fi
  done

  # 解析参数，过滤掉应用级全局选项
  local -a filtered_args=()
  local i=0
  local found_command=false

  while [[ $i -lt ${#__args_ref[@]} ]]; do
    local arg="${__args_ref[$i]}"

    # 一旦遇到非选项参数（子命令），后续所有参数都保留
    if [[ "$found_command" == "true" ]]; then
      filtered_args+=("$arg")
      ((i++))
      continue
    fi

    # 检查是否是应用级全局选项
    if [[ -n "${opt_has_value[$arg]:-}" ]]; then
      local long_name
      if [[ "$arg" == -? ]]; then
        long_name="${short_to_long[$arg]:-}"
      else
        long_name="${arg#--}"
      fi

      if [[ -n "$long_name" ]]; then
        local var_name="gopt_${long_name//-/_}"

        if [[ "${opt_has_value[$arg]}" == "true" ]]; then
          # 需要值的选项
          ((i++))
          if [[ $i -lt ${#__args_ref[@]} ]]; then
            declare -g "$var_name=${__args_ref[$i]}"
          fi
        else
          # 布尔选项
          declare -g "$var_name=true"
        fi
        ((i++))
        continue
      fi
    fi

    # 检查是否是命令（非选项参数）
    if [[ "$arg" != -* ]]; then
      found_command=true
    fi

    filtered_args+=("$arg")
    ((i++))
  done

  # 更新参数数组
  __args_ref=("${filtered_args[@]}")
}

#######################################
# 从命令参数中提取应用级全局选项（命令后位置）
# 在命令选项解析前调用，提取并移除应用级全局选项
# Arguments:
#   1 - var_name: 输入/输出参数数组的变量名（nameref）
# Globals:
#   __radp_cli_app_global_options_spec - 应用级全局选项规格
#   gopt_* - 输出：解析后的全局选项值
# Returns:
#   0 - 成功
#######################################
radp_cli_extract_app_global_options() {
  local -n __cmd_args_ref="$1"

  # 没有定义应用级全局选项，直接返回
  [[ ${#__radp_cli_app_global_options_spec[@]} -eq 0 ]] && return 0

  # 构建选项映射
  local -A short_to_long=()
  local -A opt_has_value=()
  local -A is_app_global_opt=()
  local spec
  for spec in "${__radp_cli_app_global_options_spec[@]}"; do
    local -A opt_info=()
    radp_cli_parse_option_spec "$spec" opt_info
    if [[ -n "${opt_info[short]}" && -n "${opt_info[long]}" ]]; then
      short_to_long["-${opt_info[short]}"]="${opt_info[long]}"
    fi
    if [[ -n "${opt_info[long]}" ]]; then
      opt_has_value["--${opt_info[long]}"]="${opt_info[has_value]}"
      is_app_global_opt["--${opt_info[long]}"]=1
      [[ -n "${opt_info[short]}" ]] && opt_has_value["-${opt_info[short]}"]="${opt_info[has_value]}"
      [[ -n "${opt_info[short]}" ]] && is_app_global_opt["-${opt_info[short]}"]=1
    fi
  done

  # 解析参数，过滤掉应用级全局选项
  local -a filtered_args=()
  local i=0

  while [[ $i -lt ${#__cmd_args_ref[@]} ]]; do
    local arg="${__cmd_args_ref[$i]}"

    # 检查是否是应用级全局选项
    if [[ -n "${is_app_global_opt[$arg]:-}" ]]; then
      local long_name
      if [[ "$arg" == -? ]]; then
        long_name="${short_to_long[$arg]:-}"
      else
        long_name="${arg#--}"
      fi

      if [[ -n "$long_name" ]]; then
        local var_name="gopt_${long_name//-/_}"

        if [[ "${opt_has_value[$arg]}" == "true" ]]; then
          # 需要值的选项
          ((i++))
          if [[ $i -lt ${#__cmd_args_ref[@]} ]]; then
            declare -g "$var_name=${__cmd_args_ref[$i]}"
          fi
        else
          # 布尔选项
          declare -g "$var_name=true"
        fi
        ((i++))
        continue
      fi
    fi

    filtered_args+=("$arg")
    ((i++))
  done

  # 更新参数数组
  __cmd_args_ref=("${filtered_args[@]}")
}

#######################################
# 获取应用级全局选项帮助文本
# Outputs:
#   格式化的全局选项帮助
#######################################
radp_cli_app_global_options_help() {
  [[ ${#__radp_cli_app_global_options_spec[@]} -eq 0 ]] && return 0

  echo "Application Options:"

  local spec
  for spec in "${__radp_cli_app_global_options_spec[@]}"; do
    local -A opt_info=()
    radp_cli_parse_option_spec "$spec" opt_info

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
  done

  echo
}
