#!/usr/bin/env bash
# @cmd
# @desc Show radp-bash-framework version
# @example version

# Application version - same as framework version
declare -gr gr_app_version="v0.7.24"

cmd_version() {
  radp_get_fw_install_version
}
