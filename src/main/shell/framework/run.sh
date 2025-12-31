#!/usr/bin/env bash
set -euo pipefail

#######################################
# 框架运行前置预检
# 1) 检测运行环境是否满足要求
# 2) 检测依赖是否满足
# 3) ...
# Globals:
#   gr_fw_bootstrap_root - framework bootstrap root path
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
#######################################
__fw_preflight() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  # shellcheck source=./preflight/preflight.sh
  source "$pwd"/preflight/preflight.sh
}

#######################################
# 框架核心方法
# Globals:
#   gr_fw_bootstrap_root - framework boostrap root path
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   None
#######################################
__fw_bootstrap() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  # shellcheck source=./bootstrap/bootstrap.sh
  source "$pwd"/bootstrap/bootstrap.sh "$@"
}

#######################################
# 脚本框架入口.
# 注意, 为了保证兼容性:
# 1) 入口脚本 bootstrap.sh 以及 preflight/*.sh 中的脚本请使用 POSIX sh 支持的语法
# 2) 一旦预检完,
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
  __fw_preflight
  __fw_bootstrap "$@"
}

__main "$@"
