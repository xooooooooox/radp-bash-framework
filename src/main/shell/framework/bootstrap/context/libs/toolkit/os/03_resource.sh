#!/usr/bin/env bash
# toolkit module: os/03_resource.sh

#######################################
# Check minimum CPU cores
# Verifies the system has at least the specified number of CPU cores
# Arguments:
#   1 - min_cores: Minimum required CPU cores
# Returns:
#   0 - System meets requirement
#   1 - System does not meet requirement
# Outputs:
#   Warning message if requirement not met
# Examples:
#   radp_os_check_min_cpu_cores 4
#######################################
radp_os_check_min_cpu_cores() {
  local min_cores="${1:?'Minimum CPU cores required'}"
  local actual_cores

  # Get CPU cores
  if [[ -f /proc/cpuinfo ]]; then
    actual_cores=$(grep -c '^processor' /proc/cpuinfo)
  elif command -v nproc &>/dev/null; then
    actual_cores=$(nproc)
  elif command -v sysctl &>/dev/null; then
    actual_cores=$(sysctl -n hw.ncpu 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo "0")
  else
    radp_log_warn "Cannot determine CPU cores count"
    return 1
  fi

  if [[ "$actual_cores" -lt "$min_cores" ]]; then
    radp_log_warn "System has $actual_cores CPU cores, but $min_cores required"
    return 1
  fi

  radp_log_debug "CPU cores check passed: $actual_cores >= $min_cores"
  return 0
}

#######################################
# Check minimum RAM
# Verifies the system has at least the specified amount of RAM
# Arguments:
#   1 - min_ram: Minimum required RAM (supports GB, G, MB, M suffixes)
#                Examples: "4GB", "4G", "4096MB", "4096M", "4096" (MB)
# Returns:
#   0 - System meets requirement
#   1 - System does not meet requirement
# Outputs:
#   Warning message if requirement not met
# Examples:
#   radp_os_check_min_ram 4GB
#   radp_os_check_min_ram 4G
#   radp_os_check_min_ram 4096M
#######################################
radp_os_check_min_ram() {
  local min_ram="${1:?'Minimum RAM required'}"
  local actual_ram_kb actual_ram_mb min_ram_mb

  # Parse min_ram to MB
  local value unit
  if [[ "$min_ram" =~ ^([0-9]+)([GgMm]?[Bb]?)$ ]]; then
    value="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]^^}"
    case "$unit" in
      GB|G) min_ram_mb=$((value * 1024)) ;;
      MB|M|"") min_ram_mb="$value" ;;
      *)
        radp_log_error "Invalid RAM unit: $unit"
        return 1
        ;;
    esac
  else
    radp_log_error "Invalid RAM format: $min_ram"
    return 1
  fi

  # Get actual RAM in KB
  if [[ -f /proc/meminfo ]]; then
    actual_ram_kb=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')
    actual_ram_mb=$((actual_ram_kb / 1024))
  elif command -v sysctl &>/dev/null; then
    # macOS
    local actual_bytes
    actual_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    actual_ram_mb=$((actual_bytes / 1024 / 1024))
  else
    radp_log_warn "Cannot determine system RAM"
    return 1
  fi

  if [[ "$actual_ram_mb" -lt "$min_ram_mb" ]]; then
    local actual_gb=$((actual_ram_mb / 1024))
    local min_gb=$((min_ram_mb / 1024))
    radp_log_warn "System has ${actual_gb}GB RAM, but ${min_gb}GB required"
    return 1
  fi

  radp_log_debug "RAM check passed: ${actual_ram_mb}MB >= ${min_ram_mb}MB"
  return 0
}

#######################################
# Get total system RAM in MB
# Returns:
#   Outputs total RAM in MB to stdout
#   Returns 1 if unable to determine
# Examples:
#   ram_mb=$(radp_os_get_total_ram_mb)
#######################################
radp_os_get_total_ram_mb() {
  local actual_ram_kb

  if [[ -f /proc/meminfo ]]; then
    actual_ram_kb=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')
    echo $((actual_ram_kb / 1024))
  elif command -v sysctl &>/dev/null; then
    local actual_bytes
    actual_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    echo $((actual_bytes / 1024 / 1024))
  else
    return 1
  fi
}

#######################################
# Get total CPU cores
# Returns:
#   Outputs number of CPU cores to stdout
#   Returns 1 if unable to determine
# Examples:
#   cores=$(radp_os_get_cpu_cores)
#######################################
radp_os_get_cpu_cores() {
  if [[ -f /proc/cpuinfo ]]; then
    grep -c '^processor' /proc/cpuinfo
  elif command -v nproc &>/dev/null; then
    nproc
  elif command -v sysctl &>/dev/null; then
    sysctl -n hw.ncpu 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || return 1
  else
    return 1
  fi
}
