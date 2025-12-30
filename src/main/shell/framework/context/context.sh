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
  source "$pwd"/context/autoconfigure.sh "$@"
}


__main() {
  # TODO v1.0-2025/12/28: 记得解决重复构建 context 的问题

  __framework_context_code_completion
  __framework_context_autoconfigure "$@"
}

__main "$@"
