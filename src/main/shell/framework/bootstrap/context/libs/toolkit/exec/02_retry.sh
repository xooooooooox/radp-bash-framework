#!/usr/bin/env bash
# toolkit module: exec/02_retry.sh

#######################################
# Wait until a condition becomes true
# Arguments:
#   1 - condition_cmd: Command to check (exit 0 = success)
#   --max-attempts N   Maximum attempts (default: 10)
#   --interval N       Sleep interval in seconds (default: 5)
#   --message MSG      Progress message (optional)
# Returns:
#   0 - Condition became true
#   1 - Timeout (max attempts reached)
# Example:
#   radp_wait_until "kubectl cluster-info" --max-attempts 5 --interval 10
#   radp_wait_until "ip link show flannel.1" --max-attempts 15 --interval 10 --message "Waiting for flannel..."
#######################################
radp_wait_until() {
  local condition_cmd=""
  local max_attempts=10
  local interval=5
  local message=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --max-attempts) max_attempts="$2"; shift 2 ;;
      --interval) interval="$2"; shift 2 ;;
      --message) message="$2"; shift 2 ;;
      --) shift; condition_cmd="$*"; break ;;
      *)
        if [[ -z "$condition_cmd" ]]; then
          condition_cmd="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$condition_cmd" ]]; then
    radp_log_error "radp_wait_until: condition command required"
    return 1
  fi

  [[ -n "$message" ]] && radp_log_info "$message"

  local attempt=0
  while [[ $attempt -lt $max_attempts ]]; do
    if eval "$condition_cmd" &>/dev/null; then
      return 0
    fi
    ((attempt++))
    [[ $attempt -lt $max_attempts ]] && sleep "$interval"
  done

  return 1
}

#######################################
# Retry a command until it succeeds
# Arguments:
#   1 - command: Command to execute
#   --max-attempts N   Maximum attempts (default: 3)
#   --interval N       Sleep interval between retries (default: 2)
#   --message MSG      Progress message (optional)
# Returns:
#   Exit code of the last command execution
# Example:
#   radp_retry "curl -fsSL https://example.com" --max-attempts 5 --interval 3
#######################################
radp_retry() {
  local cmd=""
  local max_attempts=3
  local interval=2
  local message=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --max-attempts) max_attempts="$2"; shift 2 ;;
      --interval) interval="$2"; shift 2 ;;
      --message) message="$2"; shift 2 ;;
      --) shift; cmd="$*"; break ;;
      *)
        if [[ -z "$cmd" ]]; then
          cmd="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$cmd" ]]; then
    radp_log_error "radp_retry: command required"
    return 1
  fi

  [[ -n "$message" ]] && radp_log_info "$message"

  local attempt=0
  local exit_code=1
  while [[ $attempt -lt $max_attempts ]]; do
    ((attempt++))
    radp_log_debug "Attempt $attempt/$max_attempts: $cmd"
    if eval "$cmd"; then
      return 0
    fi
    exit_code=$?
    [[ $attempt -lt $max_attempts ]] && sleep "$interval"
  done

  return $exit_code
}
