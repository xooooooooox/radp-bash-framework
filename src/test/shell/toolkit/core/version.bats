#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/core/05_version.sh
# =============================================================================

setup() {
  load ../../helpers/test_helper
  setup_test_env

  load_toolkit core/05_version
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_get_install_version
# =============================================================================

@test "radp_get_install_version: function exists" {
  assert_function_exists radp_get_install_version
}

@test "radp_get_install_version: returns base version when no .install-version file" {
  run radp_get_install_version "1.2.3" "$TEST_TEMP_DIR"

  [[ "$status" -eq 0 ]]
  [[ "$output" == "1.2.3" ]]
}

@test "radp_get_install_version: reads version from .install-version file" {
  echo -n "2.0.0-rc1" > "$TEST_TEMP_DIR/.install-version"

  run radp_get_install_version "1.0.0" "$TEST_TEMP_DIR"

  [[ "$status" -eq 0 ]]
  [[ "$output" == "2.0.0-rc1" ]]
}

@test "radp_get_install_version: uses RADP_APP_ROOT as default directory" {
  export RADP_APP_ROOT="$TEST_TEMP_DIR"
  echo -n "3.5.0" > "$TEST_TEMP_DIR/.install-version"

  run radp_get_install_version "1.0.0"

  [[ "$status" -eq 0 ]]
  [[ "$output" == "3.5.0" ]]
}

@test "radp_get_install_version: returns 'unknown' when no base version and no file" {
  run radp_get_install_version

  [[ "$status" -eq 0 ]]
  [[ "$output" == "unknown" ]]
}

# =============================================================================
# radp_get_fw_install_version
# =============================================================================

@test "radp_get_fw_install_version: function exists" {
  assert_function_exists radp_get_fw_install_version
}

@test "radp_get_fw_install_version: returns base version when no .install-version file" {
  local fw_dir
  fw_dir=$(create_temp_dir "framework")
  export gr_fw_root_path="$fw_dir"
  export gr_fw_version="4.0.0"

  run radp_get_fw_install_version

  [[ "$status" -eq 0 ]]
  [[ "$output" == "4.0.0" ]]
}

@test "radp_get_fw_install_version: reads version from parent of gr_fw_root_path" {
  local install_root
  install_root=$(create_temp_dir "install")
  local fw_dir
  fw_dir=$(create_temp_dir "install/framework")
  export gr_fw_root_path="$fw_dir"
  echo -n "5.1.0" > "$install_root/.install-version"

  run radp_get_fw_install_version "4.0.0"

  [[ "$status" -eq 0 ]]
  [[ "$output" == "5.1.0" ]]
}
