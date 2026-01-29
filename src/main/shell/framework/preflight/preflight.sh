#!/bin/sh
# Preflight entry point - orchestrates two-stage dependency checking
#
# Stage 1 (POSIX shell): Check/install bash only
# Stage 2 (Bash): Check/install other dependencies (gnu-getopt, yq, etc.)
#
# This two-stage approach allows stage 2 to use bash features for cleaner code.

set -e

#######################################
# Run stage 1: Bash check (POSIX shell)
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_preflight_stage1() {
  # shellcheck source=./stage1/stage1.sh
  . "$gr_fw_preflight_path"/stage1/stage1.sh
}

#######################################
# Run stage 2: Other dependencies (Bash)
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_preflight_stage2() {
  # Stage 2 uses bash - find the correct bash binary
  __bash_bin="${gw_fw_requirements_bash_bin:-bash}"

  # Run stage 2 with bash
  # shellcheck source=./stage2/stage2.sh
  "$__bash_bin" "$gr_fw_preflight_path"/stage2/stage2.sh "$@"
}

#######################################
# Main entry point
#######################################
__main() {
  # Stage 1: Ensure bash is available
  __fw_preflight_stage1 "$@" || return 1

  # Re-exec with new bash if installed
  if [ -n "${gw_fw_requirements_bash_reexec:-}" ]; then
    if [ "${GW_FW_PREFLIGHT_REEXECED:-0}" != "1" ]; then
      export GW_FW_PREFLIGHT_REEXECED=1
      echo "Preflight: re-executing with $gw_fw_requirements_bash_reexec" >&2
      exec "$gw_fw_requirements_bash_reexec" "$0" "$@"
    fi
  fi

  # Stage 2: Check other dependencies
  __fw_preflight_stage2 "$@" || return 1
}

# Initialize globals
gw_fw_requirements_bash_reexec=${gw_fw_requirements_bash_reexec:-}
gw_fw_requirements_bash_bin=${gw_fw_requirements_bash_bin:-}

__main "$@"
