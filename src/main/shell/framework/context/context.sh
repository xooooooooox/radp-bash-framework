#!/usr/bin/env bash
set -e

#######################################
# 提供编码时的代码补全功能.
# 该功能由 bashsupport pro 提供,
# 详情见(https://www.bashsupport.com/manual/navigation/sourced-files/)
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__framework_context_code_completion() {
  # shellcheck source=../context/completion.sh
  # shellcheck source=../../extend/completion.sh
  :
}

#######################################
# 自动配置
# Globals:
#   None
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   None
#######################################
__framework_context_autoconfigure() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  # shellcheck source=./autoconfigure.sh
  __framework_source_scripts "$pwd"/context/autoconfigure.sh "$@"
}

__main() {
  # 幂等控制, 避免重复加载上下文
  if [[ "${gw_framework_context_initialized:-0}" == "1" ]]; then
    return 0
  fi
  declare -g gw_framework_context_initialized="1"

  __framework_context_code_completion
  __framework_context_autoconfigure "$@"
}

declare -g gw_framework_context_initialized="0"
__main "$@"
