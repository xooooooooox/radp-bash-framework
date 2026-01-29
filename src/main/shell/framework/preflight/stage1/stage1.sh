#!/bin/sh
# Stage 1: Bash version check and installation (POSIX shell)
#
# This stage runs in POSIX shell to bootstrap bash itself.
# After this stage completes, bash 4.3+ is guaranteed to be available.

set -e

# Source bash module (gr_fw_preflight_path is set by init.sh)
. "$gr_fw_preflight_path"/stage1/bash.sh

# Required bash version
__BASH_REQUIRED_VERSION="${RADP_BASH_VERSION:-4.3}"
__BASH_INSTALL_VERSION="${RADP_BASH_INSTALL_VERSION:-5.2.21}"

#######################################
# Main stage 1 entry point
# Globals:
#   gw_fw_requirements_bash_reexec - Set if bash was installed and re-exec needed
#   gw_fw_requirements_bash_bin - Set to the bash binary path
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__stage1_main() {
  # Check if bash meets requirements
  if __stage1_bash_check "$__BASH_REQUIRED_VERSION"; then
    # Bash is OK, record the binary path
    gw_fw_requirements_bash_bin="bash"
    export gw_fw_requirements_bash_bin
    return 0
  fi

  # Bash not available or version too old
  echo "Preflight: bash $__BASH_REQUIRED_VERSION+ required" >&2

  # Try to install bash
  if ! __stage1_bash_install "$__BASH_REQUIRED_VERSION" "$__BASH_INSTALL_VERSION"; then
    echo "Error: failed to install bash $__BASH_REQUIRED_VERSION+" >&2
    return 1
  fi

  # Verify installation
  if [ -n "$gw_fw_requirements_bash_reexec" ]; then
    if __stage1_bash_check "$__BASH_REQUIRED_VERSION" "$gw_fw_requirements_bash_reexec"; then
      gw_fw_requirements_bash_bin="$gw_fw_requirements_bash_reexec"
      export gw_fw_requirements_bash_bin gw_fw_requirements_bash_reexec
      return 0
    fi
  fi

  echo "Error: bash installation verification failed" >&2
  return 1
}

__stage1_main "$@"
