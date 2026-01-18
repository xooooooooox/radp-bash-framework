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
  # shellcheck source=./preflight/preflight.sh
  . "$gr_fw_preflight_path"/preflight.sh
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
  # shellcheck source=./bootstrap/bootstrap.sh
  source "$gr_fw_bootstrap_path"/bootstrap.sh "$@"
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
  # 幂等控制,避免重复执行
  if [ "${gw_fw_run_initialized:-0}" = "1" ]; then
    return 0
  fi
  gw_fw_run_initialized="1"

  gr_fw_root_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  gr_fw_entrypoint=${gr_fw_root_path}/run.sh
  gr_fw_preflight_path="$gr_fw_root_path"/preflight
  gr_fw_bootstrap_path="$gr_fw_root_path"/bootstrap
  readonly gr_fw_root_path gr_fw_entrypoint gr_fw_preflight_path gr_fw_bootstrap_path

  __fw_preflight
  __fw_bootstrap "$@"
}

#----------------------------------------------------------------------------------------------------------------------#
gw_fw_run_initialized="0"
gr_fw_root_path=${gr_fw_root_path:-}
gr_fw_preflight_path=${gr_fw_preflight_path:-}
gr_fw_bootstrap_path=${gr_fw_bootstrap_path:-}

__main "$@"
