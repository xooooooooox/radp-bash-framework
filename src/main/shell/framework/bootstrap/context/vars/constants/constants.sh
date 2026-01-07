#!/usr/bin/env bash

# 当前框架的版本
declare -gr gr_fw_version=v0.1.3

# 缓存当前正在执行的命令(即完整命令行)
declare -gra gra_command_line=("$0" "$@")
