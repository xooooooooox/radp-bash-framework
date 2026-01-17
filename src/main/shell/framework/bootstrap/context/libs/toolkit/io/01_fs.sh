#!/usr/bin/env bash
# toolkit module: io/01_fs.sh

#######################################
# 将文件/目录路径解析为绝对路径，自动展开符号链接
# Globals:
#   BASH_SOURCE - 默认使用调用者脚本路径
# Arguments:
#   1 - target: 目标文件或目录；省略时取调用者脚本路径
# Outputs:
#   输出解析后的绝对路径
# Examples:
#   radp_io_get_path_abs ./logs -> /abs/path/logs
#   radp_io_get_path_abs -> /abs/path/of/caller/script.sh
#   radp_io_get_path_abs ./xx/file.txt -> /abs/path/to/file.txt
# Returns:
#   0 - Success
#######################################
radp_io_get_path_abs() {
  local target="${1:-${BASH_SOURCE[1]}}"

  # 解析符号链接
  while [[ -L "$target" ]]; do
    target=$(readlink "$target")
  done

  # 获取绝对路径
  if [[ -d "$target" ]]; then
    # 目标是一个目录
    # shellcheck disable=SC2005
    echo "$(cd "$target" && pwd)"
  else
    # 目标是一个文件
    echo "$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
  fi
}
