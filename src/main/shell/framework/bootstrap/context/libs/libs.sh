#!/usr/bin/env bash
set -e
# shellcheck source=../vars/global_vars.sh

__fw_include_lib_internal() {
  # 加载日志组件
  # shellcheck source=./logger/logger.sh
  __fw_source_scripts "$gr_fw_context_libs_path"/logger/logger.sh
  # 如果日志组件成功加载, 后续便可以使用 radp_log_xx 进行日志打印了

  __fw_source_scripts "$gr_fw_context_libs_path"/toolkit || {
    local msg='Failed to load framework libs, please check your code.'
    radp_log_error "$msg"
    return 1
  }
}

__fw_include_lib_external() {
  # Skip if user lib paths array is empty
  [[ ${#gra_radp_fw_user_lib_paths[@]} -eq 0 ]] && return 0

  local scripts_before=${#gwxa_fw_sourced_scripts[@]}

  # Iterate over all user lib paths
  local lib_path
  for lib_path in "${gra_radp_fw_user_lib_paths[@]}"; do
    [[ -z "$lib_path" ]] && continue
    [[ ! -d "$lib_path" ]] && {
      if [[ "${gr_radp_fw_log_debug:-false}" == "true" ]]; then
        radp_log_debug "User lib path not found, skipping: '$lib_path'"
      fi
      continue
    }
    __fw_source_scripts "$lib_path"
  done

  # Log debug info about sourced external scripts if debug mode is enabled
  if [[ "${gr_radp_fw_log_debug:-false}" == "true" ]]; then
    local scripts_after=${#gwxa_fw_sourced_scripts[@]}
    if [[ $scripts_after -gt $scripts_before ]]; then
      radp_log_debug "Sourced external user lib scripts:"
      local i
      for ((i = scripts_before; i < scripts_after; i++)); do
        radp_log_debug "  - ${gwxa_fw_sourced_scripts[$i]}"
      done
    else
      local paths_str
      printf -v paths_str "'%s' " "${gra_radp_fw_user_lib_paths[@]}"
      radp_log_debug "No external user lib scripts found in: $paths_str"
    fi
  fi
}

__main() {
  __fw_include_lib_internal
  __fw_include_lib_external
}

__main
