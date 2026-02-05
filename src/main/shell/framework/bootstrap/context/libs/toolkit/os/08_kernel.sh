#!/usr/bin/env bash
# toolkit module: os/08_kernel.sh

#######################################
# Check if a kernel module is loaded
# Arguments:
#   1 - module: kernel module name
# Returns:
#   0 - Module is loaded
#   1 - Module is not loaded
# Examples:
#   radp_os_is_kernel_module_loaded "overlay"
#######################################
radp_os_is_kernel_module_loaded() {
  local module="${1:?'Module name required'}"

  lsmod | grep -q "^${module}[[:space:]]" 2>/dev/null
}

#######################################
# Load kernel modules
# Arguments:
#   1..n - module names to load
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - All modules loaded successfully
#   1 - Failed to load one or more modules
# Examples:
#   radp_os_load_kernel_modules "overlay" "br_netfilter"
#######################################
radp_os_load_kernel_modules() {
  if [[ $# -eq 0 ]]; then
    radp_log_error "At least one module name required"
    return 1
  fi

  local module
  local failed=0

  for module in "$@"; do
    if radp_os_is_kernel_module_loaded "$module"; then
      radp_log_debug "Kernel module already loaded: $module"
      continue
    fi

    $gr_sudo modprobe "$module" || {
      radp_log_error "Failed to load kernel module: $module"
      ((failed++))
      continue
    }

    # Verify module loaded
    if ! radp_os_is_kernel_module_loaded "$module"; then
      radp_log_error "Kernel module not loaded after modprobe: $module"
      ((failed++))
      continue
    fi

    radp_log_info "Loaded kernel module: $module"
  done

  [[ $failed -eq 0 ]]
}

#######################################
# Configure kernel modules to load at boot
# Creates a config file in /etc/modules-load.d/
# Arguments:
#   1 - config_name: name for the config file (without .conf extension)
#   2..n - module names to configure
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Success
#   1 - Failure
# Examples:
#   radp_os_configure_kernel_modules "k8s" "overlay" "br_netfilter"
#######################################
radp_os_configure_kernel_modules() {
  local config_name="${1:?'Config name required'}"
  shift

  if [[ $# -eq 0 ]]; then
    radp_log_error "At least one module name required"
    return 1
  fi

  local config_file="/etc/modules-load.d/${config_name}.conf"
  local temp_file
  temp_file=$(mktemp)

  # Write config content
  {
    echo "# Managed by radp-bash-framework"
    echo "# Do not edit manually"
    for module in "$@"; do
      echo "$module"
    done
  } > "$temp_file"

  # Install config file
  $gr_sudo cp "$temp_file" "$config_file" || {
    rm -f "$temp_file"
    radp_log_error "Failed to create modules config file: $config_file"
    return 1
  }
  rm -f "$temp_file"

  radp_log_info "Created kernel modules config: $config_file"
  return 0
}

#######################################
# Configure and load kernel modules
# Combines configure_kernel_modules and load_kernel_modules
# Arguments:
#   1 - config_name: name for the config file (without .conf extension)
#   2..n - module names to configure and load
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Success
#   1 - Failure
# Examples:
#   radp_os_setup_kernel_modules "k8s" "overlay" "br_netfilter"
#######################################
radp_os_setup_kernel_modules() {
  local config_name="${1:?'Config name required'}"
  shift

  # Configure for boot persistence
  radp_os_configure_kernel_modules "$config_name" "$@" || return 1

  # Load modules now
  radp_os_load_kernel_modules "$@" || return 1

  return 0
}
