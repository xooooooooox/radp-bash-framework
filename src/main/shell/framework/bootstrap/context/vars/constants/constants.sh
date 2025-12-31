#!/usr/bin/env bash

# 缓存当前正在执行的命令(即完整命令行)
declare -gra gra_command_line=("$0" "$@")
