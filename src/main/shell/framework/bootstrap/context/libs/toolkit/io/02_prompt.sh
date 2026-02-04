#!/usr/bin/env bash
# toolkit module: io/02_prompt.sh

#######################################
# Confirmation prompt (y/N style)
# Displays a message and waits for user confirmation
# Arguments:
#   --msg <string>     Prompt message (required)
#   --default <Y|N>    Default answer if user presses Enter (default: N)
#   --timeout <sec>    Timeout in seconds (default: 0, no timeout)
#   --level <info|warn|error> Log level for the prompt (default: info)
# Returns:
#   0 - User confirmed (y/Y or default Y on timeout/empty input)
#   1 - User declined or timeout with default N
# Examples:
#   radp_io_prompt_confirm --msg "Continue?" --default Y
#   radp_io_prompt_confirm --msg "Delete file?" --level warn --timeout 30
#######################################
radp_io_prompt_confirm() {
  local msg="" default="N" timeout_sec=0 level="info"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --msg) msg="$2"; shift 2 ;;
      --default) default="${2^^}"; shift 2 ;;
      --timeout) timeout_sec="$2"; shift 2 ;;
      --level) level="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Validate required arguments
  if [[ -z "$msg" ]]; then
    radp_log_error "radp_io_prompt_confirm: --msg is required"
    return 1
  fi

  # Show prompt based on log level
  local prompt_text="$msg"
  case "$level" in
    error) radp_log_error "$prompt_text" ;;
    warn)  radp_log_warn "$prompt_text" ;;
    *)     radp_log_info "$prompt_text" ;;
  esac

  # Check if running in non-interactive mode
  if [[ ! -t 0 ]]; then
    radp_log_debug "Non-interactive mode, using default: $default"
    [[ "$default" == "Y" ]] && return 0 || return 1
  fi

  # Read user input with optional timeout
  local answer
  if [[ "$timeout_sec" -gt 0 ]]; then
    if ! read -r -t "$timeout_sec" answer; then
      radp_log_debug "Timeout reached, using default: $default"
      [[ "$default" == "Y" ]] && return 0 || return 1
    fi
  else
    read -r answer
  fi

  # Handle empty input (use default)
  if [[ -z "$answer" ]]; then
    [[ "$default" == "Y" ]] && return 0 || return 1
  fi

  # Check answer
  case "${answer,,}" in
    y|yes) return 0 ;;
    n|no)  return 1 ;;
    *)
      # Invalid input, treat as default
      [[ "$default" == "Y" ]] && return 0 || return 1
      ;;
  esac
}

#######################################
# Input prompt with nameref
# Prompts user for input and stores result in a variable
# Arguments:
#   1 - nameref: Variable name to store user input (required)
#   --msg <string>     Prompt message (required)
#   --default <value>  Default value if user presses Enter
#   --timeout <sec>    Timeout in seconds (default: 0, no timeout)
#   --level <info|warn|error> Log level for the prompt (default: info)
# Returns:
#   0 - Successfully got input
#   1 - Timeout or error
# Examples:
#   radp_nr_io_prompt_input result --msg "Enter name:" --default "default_name"
#   radp_nr_io_prompt_input choice --msg "Select option:" --timeout 60
#######################################
radp_nr_io_prompt_input() {
  local -n __nr_result__="${1:?'Variable name required'}"
  shift

  local msg="" default="" timeout_sec=0 level="info"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --msg) msg="$2"; shift 2 ;;
      --default) default="$2"; shift 2 ;;
      --timeout) timeout_sec="$2"; shift 2 ;;
      --level) level="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Validate required arguments
  if [[ -z "$msg" ]]; then
    radp_log_error "radp_nr_io_prompt_input: --msg is required"
    return 1
  fi

  # Show prompt based on log level
  local prompt_text="$msg"
  [[ -n "$default" ]] && prompt_text="$msg [default: $default]"
  case "$level" in
    error) radp_log_error "$prompt_text" ;;
    warn)  radp_log_warn "$prompt_text" ;;
    *)     radp_log_info "$prompt_text" ;;
  esac

  # Check if running in non-interactive mode
  if [[ ! -t 0 ]]; then
    radp_log_debug "Non-interactive mode, using default: $default"
    __nr_result__="$default"
    return 0
  fi

  # Read user input with optional timeout
  local answer
  if [[ "$timeout_sec" -gt 0 ]]; then
    if ! read -r -t "$timeout_sec" answer; then
      radp_log_debug "Timeout reached, using default: $default"
      __nr_result__="$default"
      [[ -n "$default" ]] && return 0 || return 1
    fi
  else
    read -r answer
  fi

  # Handle empty input (use default)
  if [[ -z "$answer" ]]; then
    __nr_result__="$default"
  else
    __nr_result__="$answer"
  fi

  return 0
}