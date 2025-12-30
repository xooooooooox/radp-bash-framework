#!/usr/bin/env bash
set -e

#######################################
# 导入指定目录下的脚本(.sh 后缀)
# 如果是目录, 默认按文件名排序后导入
# Globals:
#   gxa_framework_sourced_scripts - 记录框架导入的脚本文件
# Arguments:
#   1 - 目标目录或文件
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__framework_source_scripts() {
  local targets=${1:?}
  shift || true # the remaining "$@" will be forwarded to sourced scripts

  local target
  for target in $targets; do
    if [[ -e "$target" ]]; then
      local -a sorted_scripts
      if [[ -d "$target" ]]; then
        # 如果目标是目录, 查找该目录下的所有 .sh 文件
        mapfile -t sorted_scripts < <(find "$target" -type f -name "*.sh" | sort -t '_' -k 1,1n)
      elif [[ -f "$target" && "${target: -3}" == ".sh" ]]; then
        sorted_scripts=("$target")
      else
        continue
      fi

      local script
      for script in "${sorted_scripts[@]}"; do
        # shellcheck disable=SC1090
        source "$script" "$@" || {
          radp_log_error "Failed to source $script" || echo "Failed to source $script" >&2
          return 1
        }
        gwxa_framework_sourced_scripts+=("$script")
      done
    fi
  done
}

__framework_declare_constants_vars() {
  # shellcheck source=constants/1_framework_constants.sh
  __framework_source_scripts "$gr_framework_context_path"/vars/constants "$@" || return 1
}

__framework_declare_configurable_vars() {
  :
}

__framework_declare_dynamic_vars() {
  # shellcheck source=dynamic/1_framework_dynamic.sh
  __framework_source_scripts "$gr_framework_context_path"/vars/dynamic "$@" || return 1
}

#######################################
# 统一声明所有全局变量
# 命名规范：脚本内所有全局变量必须为小写, 变量命名由几部分组成: `g<r|w>[x][a]_name`
#   0) g: 标识其为全局变量
#   1) r|w: 标识其是否为常量. r为只读变量, w为运行时变量
#   2) x: exported, 保证父子进程的可见性
#   3) a: 是个数组变量
# 分类: 包括三类变量
#   1) 常量: *_constants.sh
#   2) 可配置变量: config.sh (可捅咕配置文件进行配置化管理的全局变量)
#   3) 动态变量: *_dynamic.sh (运行时变量)
# 注意事项
#   1) 脚本业务逻辑中不允许使用大写的全局变量!
#   2) 大写的全局变量表示环境变量, 仅可出现在配置文件中
# Globals:
#   None
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   None
#######################################
__main() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  declare -gxr gr_framework_root_path="$pwd"/../..
  declare -gxr gr_framework_context_path="$gr_framework_root_path"/context

  __framework_declare_constants_vars "$@"
  __framework_declare_configurable_vars
  __framework_declare_dynamic_vars "$@"
}

__main "$@"
