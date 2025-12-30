#!/usr/bin/env bash

# shellcheck source=../global_vars.sh

# 缓存当前正在执行的命令(即完整命令行)
declare -gra gra_command_line=("$0" "$@")

# 1. framework path
declare -gr gr_framework_config_path="$gr_framework_root_path"/config
declare -gr gr_framework_libs_path="$gr_framework_context_path"/libs
