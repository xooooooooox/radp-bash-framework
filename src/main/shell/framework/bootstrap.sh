#!/usr/bin/env bash
set -eux

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

#######################################
# 框架自动配置.
# Globals:
#   None
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   0 or 1
#######################################
__framework_bootstrap_context() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  # shellcheck source=./context/context.sh
  __framework_source_scripts "$pwd"/context/context.sh "$@"
}

#######################################
# 脚本框架入口.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
#######################################
__main() {
  # 构建上下文
  __framework_bootstrap_context "$@" || {
    local msg='Failed to build framework context, please check your code and config_file.'
    radp_log_error "$msg" || echo -e "Error: $msg" >&2
    return 1
  }
}

# 记录 sourced local scripts
declare -ga gwxa_framework_sourced_scripts
__main "$@"
