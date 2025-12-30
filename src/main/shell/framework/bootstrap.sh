#!/usr/bin/env bash
set -eux

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
__framework_build_context() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  # shellcheck source=./context/context.sh
  source "$pwd"/context.sh "$@"
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
  __framework_build_context "$@" || {
    local msg='Failed to build framework context, please check your code and config_file.'
    radp_log_error "$msg" || echo -e "Error: $msg" >&2
    return 1
  }
}

__main "$@"
