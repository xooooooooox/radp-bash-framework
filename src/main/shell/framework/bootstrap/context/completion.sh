#!/usr/bin/env bash

__fw_setup_user_completion() {
  # TODO v0.3.1-2026/1/9: 在下面两个方法中添加 shellcheck source=
  :
}

#----------------------------------------------------------------------------------------------------------------------#
__main() {
  __fw_setup_user_completion
}

declare -gr gr_fw_user_completion_file="$gr_fw_user_config_path"/completion.sh
__main
