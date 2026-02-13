#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/cli/12_upgrade_cli.sh
# =============================================================================

setup() {
  load ../../helpers/test_helper
  setup_test_env

  stub_logger
  load_toolkit cli/12_upgrade_cli
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_cli_is_portable_mode
# =============================================================================

@test "radp_cli_is_portable_mode: function exists" {
  assert_function_exists radp_cli_is_portable_mode
}

@test "radp_cli_is_portable_mode: returns 0 when RADP_BF_PORTABLE=1" {
  RADP_BF_PORTABLE="1"
  run radp_cli_is_portable_mode
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_is_portable_mode: returns 1 when RADP_BF_PORTABLE is unset" {
  unset RADP_BF_PORTABLE
  run radp_cli_is_portable_mode
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_is_portable_mode: returns 1 when RADP_BF_PORTABLE is empty" {
  RADP_BF_PORTABLE=""
  run radp_cli_is_portable_mode
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_cli_detect_platform
# =============================================================================

@test "radp_cli_detect_platform: function exists" {
  assert_function_exists radp_cli_detect_platform
}

@test "radp_cli_detect_platform: returns valid platform string" {
  run radp_cli_detect_platform
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ ^(darwin|linux)-(amd64|arm64)$ ]]
}

# =============================================================================
# radp_cli_get_download_url
# =============================================================================

@test "radp_cli_get_download_url: function exists" {
  assert_function_exists radp_cli_get_download_url
}

@test "radp_cli_get_download_url: generates standard URL" {
  run radp_cli_get_download_url "v1.0.0" "darwin-arm64"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"/releases/download/v1.0.0/radp-bf-portable-darwin-arm64" ]]
}

@test "radp_cli_get_download_url: generates full version URL" {
  run radp_cli_get_download_url "v1.0.0" "linux-amd64" "true"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"/radp-bf-portable-full-linux-amd64" ]]
}

@test "radp_cli_get_download_url: defaults to standard (not full) version" {
  run radp_cli_get_download_url "v2.0.0" "darwin-arm64"
  [[ "$output" != *"-full-"* ]]
}

# =============================================================================
# radp_cli_version_lt
# =============================================================================

@test "radp_cli_version_lt: function exists" {
  assert_function_exists radp_cli_version_lt
}

@test "radp_cli_version_lt: returns 0 when v1 < v2" {
  run radp_cli_version_lt "0.5.0" "1.0.0"
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_version_lt: returns 1 when v1 == v2" {
  run radp_cli_version_lt "1.0.0" "1.0.0"
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_version_lt: returns 1 when v1 > v2" {
  run radp_cli_version_lt "2.0.0" "1.0.0"
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_version_lt: strips leading v prefix" {
  run radp_cli_version_lt "v0.5.0" "v1.0.0"
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_version_lt: unknown is always older" {
  run radp_cli_version_lt "unknown" "1.0.0"
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_version_lt: returns 1 when both unknown" {
  run radp_cli_version_lt "unknown" "unknown"
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_version_lt: handles patch version comparison" {
  run radp_cli_version_lt "1.0.1" "1.0.2"
  [[ "$status" -eq 0 ]]
}

# =============================================================================
# radp_cli_is_full_version
# =============================================================================

@test "radp_cli_is_full_version: function exists" {
  assert_function_exists radp_cli_is_full_version
}

@test "radp_cli_is_full_version: returns 0 when RADP_BF_BUNDLED_DEPS is set" {
  RADP_BF_BUNDLED_DEPS="1"
  run radp_cli_is_full_version
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_is_full_version: returns 1 when RADP_BF_BUNDLED_DEPS is unset" {
  unset RADP_BF_BUNDLED_DEPS
  run radp_cli_is_full_version
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_cli_detect_install_method
# =============================================================================

@test "radp_cli_detect_install_method: function exists" {
  assert_function_exists radp_cli_detect_install_method
}

@test "radp_cli_detect_install_method: returns portable when RADP_BF_PORTABLE=1" {
  RADP_BF_PORTABLE="1"
  run radp_cli_detect_install_method
  [[ "$status" -eq 0 ]]
  [[ "$output" == "portable" ]]
}

@test "radp_cli_detect_install_method: reads .install-method file" {
  unset RADP_BF_PORTABLE
  export RADP_APP_ROOT="$TEST_TEMP_DIR"
  echo -n "manual" > "$TEST_TEMP_DIR/.install-method"

  run radp_cli_detect_install_method
  [[ "$status" -eq 0 ]]
  [[ "$output" == "manual" ]]
}

@test "radp_cli_detect_install_method: detects ref install from .install-ref" {
  unset RADP_BF_PORTABLE
  export RADP_APP_ROOT="$TEST_TEMP_DIR"
  echo -n "manual" > "$TEST_TEMP_DIR/.install-method"
  echo -n "main" > "$TEST_TEMP_DIR/.install-ref"

  run radp_cli_detect_install_method
  [[ "$status" -eq 0 ]]
  [[ "$output" == "ref" ]]
}

@test "radp_cli_detect_install_method: keeps manual when ref is semver tag" {
  unset RADP_BF_PORTABLE
  export RADP_APP_ROOT="$TEST_TEMP_DIR"
  echo -n "manual" > "$TEST_TEMP_DIR/.install-method"
  echo -n "v1.2.3" > "$TEST_TEMP_DIR/.install-ref"

  run radp_cli_detect_install_method
  [[ "$status" -eq 0 ]]
  [[ "$output" == "manual" ]]
}

# =============================================================================
# radp_cli_get_repo_info
# =============================================================================

@test "radp_cli_get_repo_info: function exists" {
  assert_function_exists radp_cli_get_repo_info
}

@test "radp_cli_get_repo_info: reads .install-repo file" {
  export RADP_APP_ROOT="$TEST_TEMP_DIR"
  echo -n "myorg/myrepo" > "$TEST_TEMP_DIR/.install-repo"

  run radp_cli_get_repo_info
  [[ "$status" -eq 0 ]]
  [[ "$output" == "myorg/myrepo" ]]
}

@test "radp_cli_get_repo_info: falls back to __RADP_BF_REPO for portable" {
  unset RADP_APP_ROOT
  unset gr_fw_root_path
  RADP_BF_PORTABLE="1"

  run radp_cli_get_repo_info
  [[ "$status" -eq 0 ]]
  [[ "$output" == "xooooooooox/radp-bash-framework" ]]
}

# =============================================================================
# radp_cli_get_current_version
# =============================================================================

@test "radp_cli_get_current_version: function exists" {
  assert_function_exists radp_cli_get_current_version
}

@test "radp_cli_get_current_version: reads .install-version file" {
  export RADP_APP_ROOT="$TEST_TEMP_DIR"
  echo -n "v0.7.21" > "$TEST_TEMP_DIR/.install-version"

  run radp_cli_get_current_version
  [[ "$status" -eq 0 ]]
  [[ "$output" == "v0.7.21" ]]
}

@test "radp_cli_get_current_version: returns unknown when no version found" {
  export RADP_APP_ROOT="$TEST_TEMP_DIR"
  unset gr_app_version
  unset RADP_BF_PORTABLE

  run radp_cli_get_current_version
  [[ "$status" -eq 0 ]]
  [[ "$output" == "unknown" ]]
}
