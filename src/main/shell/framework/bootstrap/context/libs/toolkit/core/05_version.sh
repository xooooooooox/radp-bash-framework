#!/usr/bin/env bash
# toolkit module: core/05_version.sh

#######################################
# Get actual installed version for an application.
# Checks for .install-version file in the specified directory.
# If the file exists, returns its content; otherwise returns the base version.
#
# This is used to show accurate version info when installed via:
#   curl ... | bash -s -- --ref main
#
# Globals:
#   RADP_APP_ROOT - application root directory (used as default check_dir)
# Arguments:
#   1 - base_version: version defined in source code (fallback)
#   2 - check_dir: (optional) directory to check for .install-version
#                  defaults to $RADP_APP_ROOT
# Outputs:
#   Prints the actual installed version
# Returns:
#   0 - Success
# Examples:
#   radp_get_install_version "$gr_myapp_version"
#   radp_get_install_version "$gr_myapp_version" "/path/to/app"
#######################################
radp_get_install_version() {
  local base_version="${1:-unknown}"
  local check_dir="${2:-${RADP_APP_ROOT:-}}"

  if [[ -n "$check_dir" && -f "$check_dir/.install-version" ]]; then
    cat "$check_dir/.install-version"
  else
    echo "$base_version"
  fi
}

#######################################
# Get actual installed version for the framework itself.
# Checks for .install-version file in the framework install directory.
#
# Globals:
#   gr_fw_root_path - framework root path (framework/ subdirectory)
#   gr_fw_version - framework version defined in source code
# Arguments:
#   1 - base_version: (optional) override base version, defaults to $gr_fw_version
# Outputs:
#   Prints the actual installed framework version
# Returns:
#   0 - Success
# Examples:
#   radp_get_fw_install_version
#   radp_get_fw_install_version "$gr_fw_version"
#######################################
radp_get_fw_install_version() {
  local base_version="${1:-${gr_fw_version:-unknown}}"
  local fw_install_dir

  # gr_fw_root_path points to framework/ subdirectory
  # The .install-version file is in the parent directory (install root)
  fw_install_dir="$(dirname "${gr_fw_root_path:-}")"

  if [[ -n "$fw_install_dir" && -f "$fw_install_dir/.install-version" ]]; then
    cat "$fw_install_dir/.install-version"
  else
    echo "$base_version"
  fi
}
