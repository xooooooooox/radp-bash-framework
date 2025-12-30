#!/usr/bin/env bash
set -eux

#######################################
# 导入指定目录下的脚本(.sh 后缀)
# 如果是目录, 默认按文件名排序后导入
# Globals:
#   gxa_framework_sourced_scripts - 记录框架导入的脚本文件
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
# 框架自动配置.
# Globals:
#   None
# Arguments:
#   @ - 命令行所有参数
# Outputs:
#   None
# Returns:
#   0 or 1
#######################################
__fw_bootstrap_context() {
  # shellcheck source=./context/context.sh
  __fw_source_scripts "$gr_fw_bootstrap_root"/context/context.sh "$@"
}

#######################################
# 脚本框架入口.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
#######################################
__main() {
  local pwd
  pwd=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  # bootstrap 根目录(幂等：避免重复 source 时修改只读变量)
  if [[ -z "${gr_fw_bootstrap_root:-}" ]]; then
    gr_fw_bootstrap_root="$pwd"
    readonly gr_fw_bootstrap_root
  fi

  # 构建上下文
  __fw_bootstrap_context "$@" || {
    local msg='Failed to build framework context, please check your code and config_file.'
    radp_log_error "$msg" || echo -e "Error: $msg" >&2
    return 1
  }
}

declare -g gr_fw_bootstrap_root
declare -gxa gwxa_fw_sourced_scripts  # 记录 sourced local scripts
__main "$@"
