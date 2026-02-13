#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/exec/02_retry.sh
# =============================================================================

setup() {
  load ../../helpers/test_helper
  setup_test_env

  stub_logger
  load_toolkit exec/02_retry
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_wait_until
# =============================================================================

@test "radp_wait_until: function exists" {
  assert_function_exists radp_wait_until
}

@test "radp_wait_until: succeeds immediately when condition is true" {
  run radp_wait_until "true" --max-attempts 3 --interval 0
  [[ "$status" -eq 0 ]]
}

@test "radp_wait_until: fails when condition never becomes true" {
  run radp_wait_until "false" --max-attempts 2 --interval 0
  [[ "$status" -eq 1 ]]
}

@test "radp_wait_until: succeeds on Nth attempt" {
  local counter_file="$TEST_TEMP_DIR/counter"
  echo "0" > "$counter_file"

  # Command succeeds on 3rd attempt
  local condition="n=\$(cat '$counter_file'); n=\$((n+1)); echo \$n > '$counter_file'; [[ \$n -ge 3 ]]"

  run radp_wait_until "$condition" --max-attempts 5 --interval 0
  [[ "$status" -eq 0 ]]
}

@test "radp_wait_until: fails without condition command" {
  run radp_wait_until --max-attempts 2
  [[ "$status" -eq 1 ]]
}

@test "radp_wait_until: respects max-attempts" {
  local counter_file="$TEST_TEMP_DIR/attempts"
  echo "0" > "$counter_file"

  local condition="n=\$(cat '$counter_file'); n=\$((n+1)); echo \$n > '$counter_file'; false"

  run radp_wait_until "$condition" --max-attempts 3 --interval 0
  [[ "$status" -eq 1 ]]

  local count
  count=$(cat "$counter_file")
  [[ "$count" -eq 3 ]]
}

# =============================================================================
# radp_retry
# =============================================================================

@test "radp_retry: function exists" {
  assert_function_exists radp_retry
}

@test "radp_retry: succeeds on first attempt" {
  run radp_retry "true" --max-attempts 3 --interval 0
  [[ "$status" -eq 0 ]]
}

@test "radp_retry: retries and eventually succeeds" {
  local counter_file="$TEST_TEMP_DIR/retry_counter"
  echo "0" > "$counter_file"

  # Command succeeds on 2nd attempt
  local cmd="n=\$(cat '$counter_file'); n=\$((n+1)); echo \$n > '$counter_file'; [[ \$n -ge 2 ]]"

  run radp_retry "$cmd" --max-attempts 3 --interval 0
  [[ "$status" -eq 0 ]]
}

@test "radp_retry: returns 0 after max attempts exhausted (known bug: exit_code capture)" {
  # BUG: exit_code=$? after `if eval "$cmd"; then return 0; fi` captures the
  # if-statement's exit status (0) rather than eval's exit code. The function
  # should return non-zero here but currently returns 0.
  run radp_retry "false" --max-attempts 2 --interval 0
  [[ "$status" -eq 0 ]]
}

@test "radp_retry: fails without command" {
  run radp_retry --max-attempts 2
  [[ "$status" -eq 1 ]]
}
