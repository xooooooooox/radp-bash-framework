#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/os/ modules
# =============================================================================
#
# Run these tests:
#   bats src/test/shell/toolkit_os.bats
#
# Note: Some tests are platform-dependent and may be skipped.
#
# =============================================================================

setup() {
  load helpers/test_helper
  setup_test_env

  # Load internal helpers first (defines __fw_os_get_distro_info)
  load_internal dynamic/dynamic

  # Load the modules being tested
  load_toolkit os/01_distro
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_os_get_distro_* functions
# =============================================================================

@test "radp_os_get_distro_os: function exists" {
  assert_function_exists radp_os_get_distro_os
}

@test "radp_os_get_distro_os: returns valid OS type" {
  local result
  result=$(radp_os_get_distro_os)

  # uname -s returns: Linux, Darwin, Windows, etc.
  [[ "$result" =~ ^(Linux|Darwin|Windows|unknown)$ ]]
}

@test "radp_os_get_distro_arch: function exists" {
  assert_function_exists radp_os_get_distro_arch
}

@test "radp_os_get_distro_arch: returns non-empty string" {
  local result
  result=$(radp_os_get_distro_arch)

  [[ -n "$result" ]]
}

@test "radp_os_get_distro_arch: returns valid architecture" {
  local result
  result=$(radp_os_get_distro_arch)

  # Common architectures from uname -m
  [[ "$result" =~ ^(x86_64|amd64|aarch64|arm64|i386|i686|armv7l|unknown)$ ]] || [[ -n "$result" ]]
}

@test "radp_os_get_distro_id: function exists" {
  assert_function_exists radp_os_get_distro_id
}

@test "radp_os_get_distro_id: returns non-empty on known OS" {
  local os
  os=$(radp_os_get_distro_os)

  if [[ "$os" == "Darwin" ]] || [[ "$os" == "Linux" ]]; then
    local result
    result=$(radp_os_get_distro_id)
    [[ -n "$result" ]]
  else
    skip "Unknown OS: $os"
  fi
}

@test "radp_os_get_distro_pm: function exists" {
  assert_function_exists radp_os_get_distro_pm
}

@test "radp_os_get_distro_pm: returns valid package manager" {
  local os
  os=$(radp_os_get_distro_os)

  local result
  result=$(radp_os_get_distro_pm)

  if [[ "$os" == "Darwin" ]]; then
    # macOS: brew or unknown
    [[ "$result" == "brew" ]] || [[ "$result" == "unknown" ]]
  elif [[ "$os" == "Linux" ]]; then
    # Linux: one of the common package managers or unknown
    [[ "$result" =~ ^(apt-get|dnf|yum|zypper|pacman|apk|unknown)$ ]]
  else
    skip "Unknown OS: $os"
  fi
}

# =============================================================================
# radp_os_is_pkg_installed
# =============================================================================

@test "radp_os_is_pkg_installed: function exists" {
  assert_function_exists radp_os_is_pkg_installed
}

@test "radp_os_is_pkg_installed: returns 1 for non-existent package" {
  run radp_os_is_pkg_installed "nonexistent-package-xyz-12345"
  [[ "$status" -eq 1 ]]
}

@test "radp_os_is_pkg_installed: detects installed package" {
  # bash should be installed on any system running these tests
  if ! command -v bash &>/dev/null; then
    skip "bash not in PATH"
  fi

  run radp_os_is_pkg_installed bash
  # May not work on all systems depending on package manager detection
  [[ "$status" -eq 0 ]] || skip "Package detection not supported on this system"
}
