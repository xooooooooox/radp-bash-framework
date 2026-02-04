#!/usr/bin/env bash
# toolkit module: os/02_security.sh

#######################################
# Disable SELinux
# Sets SELinux to permissive mode temporarily and disables it in config
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Successfully disabled or already disabled
#   1 - Failed to disable
# Note:
#   Only applicable on systems with SELinux (RHEL, CentOS, Fedora, etc.)
#######################################
radp_os_disable_selinux() {
  # Check if selinux commands exist
  if ! command -v getenforce &>/dev/null; then
    radp_log_debug "SELinux not installed, skipping"
    return 0
  fi

  local current_status
  current_status=$(getenforce 2>/dev/null || echo "Disabled")

  if [[ "$current_status" == "Disabled" ]]; then
    radp_log_info "SELinux is already disabled"
    return 0
  fi

  radp_log_info "Disabling SELinux..."

  # Set to permissive mode immediately (no reboot required)
  if [[ "$current_status" == "Enforcing" ]]; then
    $gr_sudo setenforce 0 || {
      radp_log_error "Failed to set SELinux to permissive mode"
      return 1
    }
    radp_log_info "SELinux set to permissive mode"
  fi

  # Update config file for persistence
  local selinux_config="/etc/selinux/config"
  if [[ -f "$selinux_config" ]]; then
    if grep -q '^SELINUX=enforcing' "$selinux_config" || grep -q '^SELINUX=permissive' "$selinux_config"; then
      $gr_sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "$selinux_config"
      $gr_sudo sed -i 's/^SELINUX=permissive/SELINUX=disabled/' "$selinux_config"
      radp_log_info "SELinux disabled in config (requires reboot for full effect)"
    fi
  fi

  return 0
}

#######################################
# Disable firewalld
# Stops and disables the firewalld service
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Successfully disabled or already disabled
#   1 - Failed to disable
# Note:
#   Only applicable on systems with firewalld (RHEL, CentOS, Fedora, etc.)
#######################################
radp_os_disable_firewalld() {
  # Check if firewalld is installed
  if ! command -v firewall-cmd &>/dev/null; then
    radp_log_debug "firewalld not installed, skipping"
    return 0
  fi

  # Check if firewalld service exists
  if ! systemctl list-unit-files firewalld.service &>/dev/null; then
    radp_log_debug "firewalld service not found, skipping"
    return 0
  fi

  local is_active is_enabled
  is_active=$(systemctl is-active firewalld 2>/dev/null || echo "inactive")
  is_enabled=$(systemctl is-enabled firewalld 2>/dev/null || echo "disabled")

  if [[ "$is_active" == "inactive" && "$is_enabled" == "disabled" ]]; then
    radp_log_info "firewalld is already stopped and disabled"
    return 0
  fi

  radp_log_info "Disabling firewalld..."

  # Stop firewalld if running
  if [[ "$is_active" != "inactive" ]]; then
    $gr_sudo systemctl stop firewalld || {
      radp_log_error "Failed to stop firewalld"
      return 1
    }
    radp_log_info "firewalld stopped"
  fi

  # Disable firewalld
  if [[ "$is_enabled" != "disabled" ]]; then
    $gr_sudo systemctl disable firewalld || {
      radp_log_error "Failed to disable firewalld"
      return 1
    }
    radp_log_info "firewalld disabled"
  fi

  return 0
}
