#!/usr/bin/env bash
# toolkit module: os/09_service.sh
# Systemd service management functions

#######################################
# Enable and start a systemd service
# Arguments:
#   1 - service_name: Name of the service (with or without .service suffix)
# Returns:
#   0 - Successfully enabled and started
#   1 - Failed
#######################################
radp_os_service_enable_start() {
  local service_name="${1:?'Service name required'}"

  # Ensure .service suffix
  [[ "$service_name" != *.service ]] && service_name="${service_name}.service"

  if ! command -v systemctl &>/dev/null; then
    radp_log_error "systemctl not found"
    return 1
  fi

  radp_exec_sudo "Enable $service_name" systemctl enable "$service_name" 2>/dev/null || {
    radp_log_error "Failed to enable $service_name"
    return 1
  }

  radp_exec_sudo "Start $service_name" systemctl start "$service_name" || {
    radp_log_error "Failed to start $service_name"
    return 1
  }

  radp_log_info "$service_name enabled and started"
  return 0
}

#######################################
# Restart a systemd service
# Arguments:
#   1 - service_name: Name of the service (with or without .service suffix)
# Returns:
#   0 - Successfully restarted
#   1 - Failed
#######################################
radp_os_service_restart() {
  local service_name="${1:?'Service name required'}"

  # Ensure .service suffix
  [[ "$service_name" != *.service ]] && service_name="${service_name}.service"

  if ! command -v systemctl &>/dev/null; then
    radp_log_error "systemctl not found"
    return 1
  fi

  radp_exec_sudo "Restart $service_name" systemctl restart "$service_name" || {
    radp_log_error "Failed to restart $service_name"
    return 1
  }

  radp_log_info "$service_name restarted"
  return 0
}

#######################################
# Stop and disable a systemd service
# Arguments:
#   1 - service_name: Name of the service (with or without .service suffix)
# Returns:
#   0 - Successfully stopped and disabled
#   1 - Failed
#######################################
radp_os_service_stop_disable() {
  local service_name="${1:?'Service name required'}"

  # Ensure .service suffix
  [[ "$service_name" != *.service ]] && service_name="${service_name}.service"

  if ! command -v systemctl &>/dev/null; then
    radp_log_error "systemctl not found"
    return 1
  fi

  # Stop if running
  if systemctl is-active "$service_name" &>/dev/null; then
    radp_exec_sudo "Stop $service_name" systemctl stop "$service_name" || {
      radp_log_warn "Failed to stop $service_name"
    }
  fi

  # Disable if enabled
  if systemctl is-enabled "$service_name" &>/dev/null; then
    radp_exec_sudo "Disable $service_name" systemctl disable "$service_name" 2>/dev/null || {
      radp_log_warn "Failed to disable $service_name"
    }
  fi

  return 0
}

#######################################
# Configure HTTP proxy for a systemd service
# Creates/updates a drop-in file for proxy environment variables
# Arguments:
#   1 - service_name: Name of the service (e.g., docker, containerd)
#   2 - http_proxy: HTTP proxy URL
#   3 - https_proxy: HTTPS proxy URL (optional, defaults to http_proxy)
#   4 - no_proxy: Comma-separated list of hosts to bypass (optional)
# Returns:
#   0 - Successfully configured
#   1 - Failed
#######################################
radp_os_service_configure_http_proxy() {
  local service_name="${1:?'Service name required'}"
  local http_proxy="${2:?'HTTP proxy URL required'}"
  local https_proxy="${3:-$http_proxy}"
  local no_proxy="${4:-localhost,127.0.0.1}"

  # Ensure service name without .service suffix for directory
  service_name="${service_name%.service}"

  local drop_in_dir="/etc/systemd/system/${service_name}.service.d"
  local drop_in_file="${drop_in_dir}/http-proxy.conf"

  radp_log_info "Configuring HTTP proxy for ${service_name}..."

  # Check for dry-run mode for complex file operations
  if radp_dry_run_skip "Create $drop_in_dir and write proxy config to $drop_in_file"; then
    radp_log_info "[dry-run] Would configure:"
    radp_log_info "  HTTP_PROXY=${http_proxy}"
    radp_log_info "  HTTPS_PROXY=${https_proxy}"
    radp_log_info "  NO_PROXY=${no_proxy}"
    return 0
  fi

  # Create drop-in directory
  $gr_sudo mkdir -p "$drop_in_dir" || {
    radp_log_error "Failed to create $drop_in_dir"
    return 1
  }

  # Write proxy configuration
  $gr_sudo tee "$drop_in_file" >/dev/null <<EOF
[Service]
Environment="HTTP_PROXY=${http_proxy}"
Environment="HTTPS_PROXY=${https_proxy}"
Environment="NO_PROXY=${no_proxy}"
EOF

  if [[ $? -ne 0 ]]; then
    radp_log_error "Failed to write proxy configuration"
    return 1
  fi

  # Reload systemd daemon
  radp_exec_sudo "Reload systemd daemon" systemctl daemon-reload || {
    radp_log_error "Failed to reload systemd daemon"
    return 1
  }

  radp_log_info "HTTP proxy configured for ${service_name}"
  radp_log_info "  HTTP_PROXY=${http_proxy}"
  radp_log_info "  HTTPS_PROXY=${https_proxy}"
  radp_log_info "  NO_PROXY=${no_proxy}"
  radp_log_info "Restart ${service_name} to apply changes"

  return 0
}

#######################################
# Remove HTTP proxy configuration for a systemd service
# Arguments:
#   1 - service_name: Name of the service (e.g., docker, containerd)
# Returns:
#   0 - Successfully removed
#   1 - Failed
#######################################
radp_os_service_remove_http_proxy() {
  local service_name="${1:?'Service name required'}"

  # Ensure service name without .service suffix for directory
  service_name="${service_name%.service}"

  local drop_in_file="/etc/systemd/system/${service_name}.service.d/http-proxy.conf"

  if [[ ! -f "$drop_in_file" ]]; then
    radp_log_info "No proxy configuration found for ${service_name}"
    return 0
  fi

  radp_log_info "Removing HTTP proxy configuration for ${service_name}..."

  radp_exec_sudo "Remove $drop_in_file" rm -f "$drop_in_file" || {
    radp_log_error "Failed to remove $drop_in_file"
    return 1
  }

  # Reload systemd daemon
  radp_exec_sudo "Reload systemd daemon" systemctl daemon-reload || {
    radp_log_warn "Failed to reload systemd daemon"
  }

  radp_log_info "HTTP proxy configuration removed for ${service_name}"
  return 0
}
