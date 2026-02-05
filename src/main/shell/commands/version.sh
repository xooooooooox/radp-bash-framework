#!/usr/bin/env bash
# @cmd
# @desc Show radp-bash-framework version

# Application version - same as framework version
declare -gr gr_app_version="v0.7.16"

cmd_version() {
  radp_get_fw_install_version
}
