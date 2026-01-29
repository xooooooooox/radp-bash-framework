#!/usr/bin/env bash
# Stage 2: Check and install dependencies (Bash)
#
# This stage runs after bash is confirmed available.
# We can use bash features: local, [[ ]], arrays, etc.

set -euo pipefail

# Stage 2 uses BASH_SOURCE[0] because it's executed (not sourced)
__STAGE2_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __STAGE2_DIR

# Source library
# shellcheck source=./lib.sh
source "$__STAGE2_DIR/lib.sh"

# Define requirements: name:check_func:install_func
declare -a __REQUIREMENTS=(
  "gnu-getopt:__check_gnu_getopt:__install_gnu_getopt"
  "yq:__check_yq:__install_yq"
)

# Source requirement modules
# shellcheck source=./gnu_getopt.sh
source "$__STAGE2_DIR/gnu_getopt.sh"
# shellcheck source=./yq.sh
source "$__STAGE2_DIR/yq.sh"

#######################################
# Check a single requirement
# Arguments:
#   1 - requirement spec (name:check:install)
# Returns:
#   0 - satisfied
#   1 - not satisfied
#######################################
__stage2_check_requirement() {
  local spec="$1"
  local name="${spec%%:*}"
  local rest="${spec#*:}"
  local check_func="${rest%%:*}"

  if declare -f "$check_func" >/dev/null 2>&1; then
    "$check_func"
    return $?
  fi

  # Fallback: check if command exists
  command -v "$name" >/dev/null 2>&1
}

#######################################
# Install a single requirement
# Arguments:
#   1 - requirement spec (name:check:install)
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage2_install_requirement() {
  local spec="$1"
  local name="${spec%%:*}"
  local rest="${spec#*:}"
  local rest2="${rest#*:}"
  local install_func="${rest2%%:*}"

  if declare -f "$install_func" >/dev/null 2>&1; then
    "$install_func"
    return $?
  fi

  __stage2_log_error "No installer for $name"
  return 1
}

#######################################
# Stage 2 main entry point
# Globals:
#   __REQUIREMENTS - array of requirement specs
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage2_main() {
  local missing=()

  # Check all requirements
  for spec in "${__REQUIREMENTS[@]}"; do
    local name="${spec%%:*}"
    if ! __stage2_check_requirement "$spec"; then
      missing+=("$spec")
    fi
  done

  # Nothing to install
  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  # Report missing
  local names=()
  for spec in "${missing[@]}"; do
    names+=("${spec%%:*}")
  done
  __stage2_log_info "Missing dependencies: ${names[*]}"

  # Install missing
  for spec in "${missing[@]}"; do
    local name="${spec%%:*}"
    __stage2_log_info "Installing $name..."
    if ! __stage2_install_requirement "$spec"; then
      __stage2_log_error "Failed to install $name"
      return 1
    fi
  done

  # Verify all installed
  for spec in "${missing[@]}"; do
    local name="${spec%%:*}"
    if ! __stage2_check_requirement "$spec"; then
      __stage2_log_error "$name installation verification failed"
      return 1
    fi
  done

  __stage2_log_info "All dependencies satisfied"
  return 0
}

#----------------------------------------------------------------------------------------------------------------------#
__stage2_main "$@"
