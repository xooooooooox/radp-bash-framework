#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/exec/04_dry_run.sh
# =============================================================================

setup() {
  load ../../helpers/test_helper
  setup_test_env

  stub_logger
  load_toolkit exec/04_dry_run
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_set_dry_run
# =============================================================================

@test "radp_set_dry_run: function exists" {
  assert_function_exists radp_set_dry_run
}

@test "radp_set_dry_run: enables dry-run with 'true'" {
  radp_set_dry_run "true"
  [[ "$gw_dry_run" == "true" ]]
}

@test "radp_set_dry_run: enables dry-run with '1'" {
  radp_set_dry_run "1"
  [[ "$gw_dry_run" == "true" ]]
}

@test "radp_set_dry_run: enables dry-run with no argument (defaults to true)" {
  radp_set_dry_run
  [[ "$gw_dry_run" == "true" ]]
}

@test "radp_set_dry_run: disables dry-run with 'false'" {
  radp_set_dry_run "true"
  radp_set_dry_run "false"
  [[ -z "$gw_dry_run" ]]
}

# =============================================================================
# radp_is_dry_run
# =============================================================================

@test "radp_is_dry_run: function exists" {
  assert_function_exists radp_is_dry_run
}

@test "radp_is_dry_run: returns 0 when dry-run enabled" {
  radp_set_dry_run "true"
  run radp_is_dry_run
  [[ "$status" -eq 0 ]]
}

@test "radp_is_dry_run: returns 1 when dry-run disabled" {
  gw_dry_run=""
  run radp_is_dry_run
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_exec
# =============================================================================

@test "radp_exec: function exists" {
  assert_function_exists radp_exec
}

@test "radp_exec: executes command in normal mode" {
  gw_dry_run=""
  local marker="$TEST_TEMP_DIR/executed"

  radp_exec "Create marker file" touch "$marker"

  [[ -f "$marker" ]]
}

@test "radp_exec: skips command in dry-run mode" {
  radp_set_dry_run "true"
  local marker="$TEST_TEMP_DIR/should_not_exist"

  radp_exec "Create marker file" touch "$marker"

  [[ ! -f "$marker" ]]
}

@test "radp_exec: returns 0 in dry-run mode" {
  radp_set_dry_run "true"

  run radp_exec "Fail command" false
  [[ "$status" -eq 0 ]]
}

@test "radp_exec: returns command exit code in normal mode" {
  gw_dry_run=""

  run radp_exec "Run true" true
  [[ "$status" -eq 0 ]]

  run radp_exec "Run false" false
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_exec_sudo
# =============================================================================

@test "radp_exec_sudo: function exists" {
  assert_function_exists radp_exec_sudo
}

@test "radp_exec_sudo: skips command in dry-run mode" {
  radp_set_dry_run "true"
  local marker="$TEST_TEMP_DIR/sudo_marker"

  radp_exec_sudo "Create marker" touch "$marker"

  [[ ! -f "$marker" ]]
}

@test "radp_exec_sudo: executes command without sudo when gr_sudo is empty" {
  gw_dry_run=""
  gr_sudo=""
  local marker="$TEST_TEMP_DIR/sudo_executed"

  radp_exec_sudo "Create marker" touch "$marker"

  [[ -f "$marker" ]]
}

# =============================================================================
# radp_dry_run_skip
# =============================================================================

@test "radp_dry_run_skip: function exists" {
  assert_function_exists radp_dry_run_skip
}

@test "radp_dry_run_skip: returns 0 when dry-run enabled (caller should skip)" {
  radp_set_dry_run "true"

  run radp_dry_run_skip "Complex operation"
  [[ "$status" -eq 0 ]]
}

@test "radp_dry_run_skip: returns 1 when dry-run disabled (caller should proceed)" {
  gw_dry_run=""

  run radp_dry_run_skip "Complex operation"
  [[ "$status" -eq 1 ]]
}
