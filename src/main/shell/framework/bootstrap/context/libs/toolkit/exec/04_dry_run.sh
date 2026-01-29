#!/usr/bin/env bash
# toolkit module: exec/04_dry_run.sh
# Dry-run mode support for safe command execution preview

# Global variable to track dry-run mode
declare -g gw_dry_run=""

#######################################
# Enable or disable dry-run mode
# Globals:
#   gw_dry_run
# Arguments:
#   $1 - "true" to enable, "false" or empty to disable
# Returns:
#   None
#######################################
radp_set_dry_run() {
  local enabled="${1:-true}"
  if [[ "$enabled" == "true" || "$enabled" == "1" ]]; then
    gw_dry_run="true"
  else
    gw_dry_run=""
  fi
}

#######################################
# Check if dry-run mode is enabled
# Globals:
#   gw_dry_run
# Arguments:
#   None
# Returns:
#   0 - dry-run mode is enabled
#   1 - dry-run mode is disabled
#######################################
radp_is_dry_run() {
  [[ -n "$gw_dry_run" ]]
}

#######################################
# Execute a command or log it in dry-run mode
# In dry-run mode: logs "[dry-run] <description>" and returns 0
# In normal mode: executes the command
# Globals:
#   gw_dry_run
# Arguments:
#   $1 - Description of the action (required)
#   $@ - Command and arguments to execute
# Returns:
#   0 - in dry-run mode (always succeeds)
#   Command exit code - in normal mode
# Examples:
#   radp_exec "Install nginx package" apt-get install -y nginx
#   radp_exec "Create directory $dir" mkdir -p "$dir"
#   radp_exec "Set timezone to $tz" timedatectl set-timezone "$tz"
#######################################
radp_exec() {
  local desc="$1"
  shift

  if radp_is_dry_run; then
    radp_log_info "[dry-run] $desc"
    return 0
  fi

  "$@"
}

#######################################
# Execute a command with sudo or log it in dry-run mode
# Convenience wrapper that prepends sudo to the command
# Globals:
#   gw_dry_run
#   gr_sudo
# Arguments:
#   $1 - Description of the action (required)
#   $@ - Command and arguments to execute (sudo is prepended)
# Returns:
#   0 - in dry-run mode (always succeeds)
#   Command exit code - in normal mode
# Examples:
#   radp_exec_sudo "Install nginx package" apt-get install -y nginx
#   radp_exec_sudo "Enable chronyd service" systemctl enable chronyd
#######################################
radp_exec_sudo() {
  local desc="$1"
  shift

  if radp_is_dry_run; then
    radp_log_info "[dry-run] $desc"
    return 0
  fi

  ${gr_sudo:-} "$@"
}

#######################################
# Log a dry-run message for operations that can't be wrapped
# Use this for complex operations that can't be expressed as a single command
# Globals:
#   gw_dry_run
# Arguments:
#   $1 - Description of the action
# Returns:
#   0 - dry-run mode is enabled (caller should skip the operation)
#   1 - dry-run mode is disabled (caller should proceed)
# Examples:
#   if radp_dry_run_skip "Configure complex settings"; then
#     return 0
#   fi
#   # ... complex operations ...
#######################################
radp_dry_run_skip() {
  local desc="$1"

  if radp_is_dry_run; then
    radp_log_info "[dry-run] $desc"
    return 0
  fi

  return 1
}
