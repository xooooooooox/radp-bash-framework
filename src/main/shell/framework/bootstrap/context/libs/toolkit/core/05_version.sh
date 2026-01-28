#!/usr/bin/env bash
# toolkit module: core/05_version.sh

#######################################
# Build version string from .version file or release version
# For manual installs, reads .version file and builds display string
# For package manager installs, returns the release version as-is
#
# Arguments:
#   $1 - app_root: Application root directory
#   $2 - release_version: Release version (e.g., v0.1.4)
# Outputs:
#   Version string to stdout
# Examples:
#   radp_version_build "/path/to/app" "v0.1.4"
#   # Package manager: "v0.1.4"
#   # Manual (tag):    "v0.2.0-rc1 (manual, 2026-01-29)"
#   # Manual (branch): "main@abc1234 (manual, 2026-01-29)"
#######################################
radp_version_build() {
  local app_root="${1:-}"
  local release_version="${2:-unknown}"
  local version_file="${app_root}/.version"

  # If .version file exists (manual install), build version from it
  if [[ -f "${version_file}" ]]; then
    local ref="" commit="" install_date=""
    while IFS='=' read -r key value; do
      case "${key}" in
        ref) ref="${value}" ;;
        commit) commit="${value}" ;;
        date) install_date="${value}" ;;
      esac
    done < "${version_file}"

    # Build display string
    local display="${ref:-${release_version}}"
    # Add commit hash for non-tag refs (branches)
    [[ -n "${commit}" && "${ref}" != v* ]] && display="${ref}@${commit}"
    # Add install info
    [[ -n "${install_date}" ]] && display="${display} (manual, ${install_date})"
    echo "${display}"
    return
  fi

  # Default: use release version
  echo "${release_version}"
}
