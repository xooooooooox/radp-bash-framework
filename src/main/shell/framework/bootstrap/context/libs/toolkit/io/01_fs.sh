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

#######################################
# Append a line to file if it doesn't exist (prevent duplicates)
# Arguments:
#   1 - file_path: Path to the file
#   2 - line: Line content to append
# Globals:
#   gr_sudo - sudo command prefix (optional)
# Returns:
#   0 - Success (line added or already exists)
#   1 - Failure
# Examples:
#   radp_io_append_line_unique "/etc/hosts" "127.0.0.1 myhost"
#   radp_io_append_line_unique "$HOME/.bashrc" "export PATH=\$PATH:/opt/bin"
#######################################
radp_io_append_line_unique() {
  local file_path="${1:?'File path required'}"
  local line="${2:?'Line content required'}"

  # Create file if it doesn't exist
  if [[ ! -f "$file_path" ]]; then
    local dir
    dir=$(dirname "$file_path")
    if [[ ! -d "$dir" ]]; then
      ${gr_sudo:-} mkdir -p "$dir" || {
        radp_log_error "Failed to create directory: $dir"
        return 1
      }
    fi
    ${gr_sudo:-} touch "$file_path" || {
      radp_log_error "Failed to create file: $file_path"
      return 1
    }
  fi

  # Check if line already exists (exact match)
  if grep -Fxq "$line" "$file_path" 2>/dev/null; then
    radp_log_debug "Line already exists in $file_path"
    return 0
  fi

  # Append line
  echo "$line" | ${gr_sudo:-} tee -a "$file_path" > /dev/null || {
    radp_log_error "Failed to append line to $file_path"
    return 1
  }

  radp_log_debug "Line appended to $file_path"
  return 0
}