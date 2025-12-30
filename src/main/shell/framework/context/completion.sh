#!/usr/bin/env bash

#######################################
# 自动补全-全局变量
# @see framework/context/vars/global_vars.sh
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
#######################################
__framework_completion_vars() {
  # shellcheck source=vars/global_vars.sh
  :
}

__main() {
  __framework_completion_vars
}

__main
