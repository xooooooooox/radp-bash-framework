#!/usr/bin/env bash

# Framework release version - single source of truth
declare -g _fw_release_version=v0.6.5

# Build version string from .version file if exists (manual install)
_fw_build_version() {
  local fw_root="${gr_fw_root_path:-}"
  local version_file="${fw_root}/.version"

  if [[ -f "${version_file}" ]]; then
    local ref="" commit="" install_date=""
    while IFS='=' read -r key value; do
      case "${key}" in
      ref) ref="${value}" ;;
      commit) commit="${value}" ;;
      date) install_date="${value}" ;;
      esac
    done <"${version_file}"

    local display="${ref:-${_fw_release_version}}"
    [[ -n "${commit}" && "${ref}" != v* ]] && display="${ref}@${commit}"
    [[ -n "${install_date}" ]] && display="${display} (manual, ${install_date})"
    echo "${display}"
    return
  fi

  echo "${_fw_release_version}"
}

declare -g gr_fw_version
gr_fw_version="$(_fw_build_version)"
readonly gr_fw_version

# 缓存当前正在执行的命令(即完整命令行)
declare -gra gra_command_line=("$0" "$@")
