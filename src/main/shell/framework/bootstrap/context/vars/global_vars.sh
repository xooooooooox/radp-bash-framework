#!/usr/bin/env bash
set -e
# shellcheck source=../../bootstrap.sh

#######################################
# 声明全局变量 - 常量
# Globals:
#   gr_framework_context_vars_path - 全局变量脚本根目录
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   1 - failed
#######################################
__fw_declare_constants_vars() {
  if [[ ! -f "$gr_fw_bootstrap_path"/bootstrap.sh ]];then
    # 确保框架根目录正确
    local msg="框架初始化错误, 框架文件缺失或者框架根目录错误"
    echo -e "Error: $msg" >&2
    return 1
  fi

  # shellcheck source=./constants/constants.sh
  __fw_source_scripts "$gr_fw_context_vars_path"/constants/constants.sh "$@" || return 1

}

#######################################
# 声明全局变量 - 可配置的全局变量
# Globals:
#   gr_framework_context_vars_path - 全局变量脚本根目录
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   1 - failed
#######################################
__fw_declare_configurable_vars() {
  # shellcheck source=./configurable/autoconfigure.sh
  __fw_source_scripts "$gr_fw_context_vars_path"/configurable/autoconfigure.sh "$@" || return 1
}

#######################################
# 声明全局变量 - 运行时动态变量
# Globals:
#   gr_framework_context_vars_path - 全局变量脚本根目录
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   1 - failed
#######################################
__fw_declare_dynamic_vars() {
  # shellcheck source=./dynamic/dynamic.sh
  __fw_source_scripts "$gr_fw_context_vars_path"/dynamic/dynamic.sh "$@" || return 1
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
#   2) 可配置变量: 由 auto_configurable.sh 注入 (可通过配置文件进行配置化管理的全局变量)
#   3) 动态变量: *_dynamic.sh (运行时变量)
# 注意事项
#   1) 脚本业务逻辑中不允许使用大写的全局变量!
#   2) 大写的全局变量表示环境变量, 仅可出现在配置文件中
#   3) 全局变量尽量就近定义, 除非该全局变量需要脚本文件之间共享使用(这种情况就按照前文的分类定义到具体的文件中)
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
  __fw_declare_constants_vars "$@"
  __fw_declare_configurable_vars "$@"
  __fw_declare_dynamic_vars "$@"
}

declare -gr gr_fw_context_path="$gr_fw_root_path"/context
declare -gr gr_fw_context_vars_path="$gr_fw_context_path"/vars
declare -gr gr_fw_context_libs_path="$gr_fw_context_path"/libs
__main "$@"
