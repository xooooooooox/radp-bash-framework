#!/usr/bin/env bash
# toolkit module: io/01_fs.sh

function radp_io_get_path_abs() {
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
