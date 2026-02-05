#!/usr/bin/env bash
# toolkit module: os/04_sysctl.sh

#######################################
# Set a sysctl parameter temporarily
# Arguments:
#   1 - key: sysctl parameter name (e.g., net.ipv4.ip_forward)
#   2 - value: value to set
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Success
#   1 - Failure
# Examples:
#   radp_os_sysctl_set "net.ipv4.ip_forward" "1"
#######################################
radp_os_sysctl_set() {
  local key="${1:?'Parameter key required'}"
  local value="${2:?'Parameter value required'}"

  $gr_sudo sysctl -w "${key}=${value}" >/dev/null 2>&1 || {
    radp_log_error "Failed to set sysctl parameter: ${key}=${value}"
    return 1
  }

  radp_log_debug "Set sysctl: ${key}=${value}"
  return 0
}

#######################################
# Check if a sysctl parameter has expected value
# Arguments:
#   1 - key: sysctl parameter name
#   2 - expected: expected value
# Returns:
#   0 - Parameter matches expected value
#   1 - Parameter does not match or error
# Examples:
#   radp_os_sysctl_check "net.ipv4.ip_forward" "1"
#######################################
radp_os_sysctl_check() {
  local key="${1:?'Parameter key required'}"
  local expected="${2:?'Expected value required'}"

  local current
  current=$(sysctl -n "$key" 2>/dev/null) || {
    radp_log_error "Failed to read sysctl parameter: $key"
    return 1
  }

  if [[ "$current" != "$expected" ]]; then
    radp_log_error "sysctl parameter $key is $current, expected $expected"
    return 1
  fi

  radp_log_debug "sysctl parameter $key = $expected (OK)"
  return 0
}

#######################################
# Configure sysctl parameters persistently
# Creates a config file in /etc/sysctl.d/ and applies settings
# Arguments:
#   1 - config_name: name for the config file (without .conf extension)
#   2..n - key=value pairs to configure
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Success
#   1 - Failure
# Examples:
#   radp_os_sysctl_configure_persistent "k8s" \
#     "net.bridge.bridge-nf-call-iptables=1" \
#     "net.bridge.bridge-nf-call-ip6tables=1" \
#     "net.ipv4.ip_forward=1"
#######################################
radp_os_sysctl_configure_persistent() {
  local config_name="${1:?'Config name required'}"
  shift

  if [[ $# -eq 0 ]]; then
    radp_log_error "At least one key=value pair required"
    return 1
  fi

  local config_file="/etc/sysctl.d/${config_name}.conf"
  local temp_file
  temp_file=$(mktemp)

  # Write config content
  {
    echo "# Managed by radp-bash-framework"
    echo "# Do not edit manually"
    echo ""
    for param in "$@"; do
      # Convert = to ' = ' for sysctl format
      echo "${param%%=*} = ${param#*=}"
    done
  } > "$temp_file"

  # Install config file
  $gr_sudo cp "$temp_file" "$config_file" || {
    rm -f "$temp_file"
    radp_log_error "Failed to create sysctl config file: $config_file"
    return 1
  }
  rm -f "$temp_file"

  radp_log_info "Created sysctl config: $config_file"

  # Apply settings
  $gr_sudo sysctl --system >/dev/null 2>&1 || {
    radp_log_error "Failed to apply sysctl settings"
    return 1
  }

  radp_log_info "Applied sysctl settings"
  return 0
}
