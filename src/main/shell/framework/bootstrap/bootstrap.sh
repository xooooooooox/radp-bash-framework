#!/usr/bin/env bash
set -e
# shellcheck source=../run.sh

#######################################
# 导入指定目录下的脚本(.sh 后缀)
# 如果是目录, 默认按文件名排序后导入
# Globals:
#   gwxa_fw_sourced_scripts - 记录框架导入的脚本文件
# Arguments:
#   1 - 目标目录或文件
# Outputs:
#   None
# Returns:
#   0 - Success
#######################################
__fw_source_scripts() {
  local targets=${1:?}
  shift || true # the remaining "$@" will be forwarded to sourced scripts

  local tgt
  for tgt in $targets; do
    if [[ -e "$tgt" ]]; then
      local -a sorted_scripts
      if [[ -d "$tgt" ]]; then
        # 如果目标是目录, 查找该目录下的所有 .sh 文件
        mapfile -t sorted_scripts < <(find "$tgt" -type f -name "*.sh" | sort -t '_' -k 1,1n)
      elif [[ -f "$tgt" && "${tgt: -3}" == ".sh" ]]; then
        sorted_scripts=("$tgt")
      else
        continue
      fi

      local script_to_source
      for script_to_source in "${sorted_scripts[@]}"; do
        # shellcheck disable=SC1090
        source "$script_to_source" "$@" || {
          radp_log_error "Failed to source $script_to_source" || echo "Failed to source $script_to_source" >&2
          return 1
        }
        gwxa_fw_sourced_scripts+=("$script_to_source")
      done
    fi
  done
}

#######################################
# 构建框架上下文
# 包括: 全局变量, 库函数等
# Globals:
#   gr_fw_bootstrap_root - bootstrap root path
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   None
#######################################
__fw_bootstrap_context() {
  # shellcheck source=./context/context.sh
  __fw_source_scripts "$gr_fw_bootstrap_path"/context/context.sh "$@"
}

__main() {
  # 构建上下文
  __fw_bootstrap_context "$@" || {
    local msg='Failed to build framework context, please check your code and config_file.'
    radp_log_error "$msg" || echo -e "Error: $msg" >&2
    return 1
  }
}

declare -gxa gwxa_fw_sourced_scripts # 记录 sourced local scripts
__main "$@"
