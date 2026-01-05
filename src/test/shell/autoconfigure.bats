#!/usr/bin/env bats
# Test file for autoconfigure.sh

# Setup - runs before each test
setup() {
  # Create temp directory for test files
  TEST_TEMP_DIR="$(mktemp -d)"

  # Get the project root
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"

  # Source the autoconfigure.sh functions (we need to set up required globals first)
  # Set up minimal required global variables
  export gr_fw_root_path="$PROJECT_ROOT/src/main/shell/framework"
  export gr_fw_bootstrap_path="$gr_fw_root_path/bootstrap"

  # Create a minimal __fw_source_scripts function for testing
  __fw_source_scripts() {
    local target="$1"
    if [[ -f "$target" ]]; then
      # shellcheck disable=SC1090
      source "$target"
    fi
  }
  export -f __fw_source_scripts
}

# Teardown - runs after each test
teardown() {
  # Clean up temp directory
  if [[ -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Helper function to source only the functions from autoconfigure.sh without running __main
source_autoconfigure_functions() {
  local autoconfigure_file="$PROJECT_ROOT/src/main/shell/framework/bootstrap/context/vars/configurable/autoconfigure.sh"

  # Extract and source only the function definitions
  # We use a subshell approach to avoid running __main
  eval "$(sed -n '/^__fw_yaml_to_env_vars()/,/^}/p' "$autoconfigure_file")"
  eval "$(sed -n '/^__fw_merge_env_vars()/,/^}/p' "$autoconfigure_file")"
  eval "$(sed -n '/^__fw_resolve_yaml_references()/,/^}/p' "$autoconfigure_file")"
  eval "$(sed -n '/^__fw_export_yaml_vars()/,/^}/p' "$autoconfigure_file")"
  eval "$(sed -n '/^__fw_yaml_var_to_shell_var()/,/^}/p' "$autoconfigure_file")"
  eval "$(sed -n '/^__fw_yaml_var_to_env_var()/,/^}/p' "$autoconfigure_file")"
  eval "$(sed -n '/^__fw_generate_user_config()/,/^}/p' "$autoconfigure_file")"
}

# =============================================================================
# Tests for __fw_yaml_to_env_vars
# =============================================================================

@test "__fw_yaml_to_env_vars: parses simple YAML key-value pairs" {
  source_autoconfigure_functions

  # Create a test YAML file
  cat >"$TEST_TEMP_DIR/test.yaml" <<'EOF'
radp:
  env: dev
  log:
    debug: true
EOF

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/test.yaml" result

  # Check that variables are correctly parsed
  [[ "${result[YAML_RADP_ENV]}" == "dev" ]]
  [[ "${result[YAML_RADP_LOG_DEBUG]}" == "true" ]]
}

@test "__fw_yaml_to_env_vars: handles nested YAML structures" {
  source_autoconfigure_functions

  cat >"$TEST_TEMP_DIR/test.yaml" <<'EOF'
radp:
  log:
    rolling-policy:
      enabled: true
      max-history: 7
EOF

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/test.yaml" result

  # Check nested keys are flattened correctly with hyphens converted to underscores
  [[ "${result[YAML_RADP_LOG_ROLLING_POLICY_ENABLED]}" == "true" ]]
  [[ "${result[YAML_RADP_LOG_ROLLING_POLICY_MAX_HISTORY]}" == "7" ]]
}

@test "__fw_yaml_to_env_vars: returns 0 for non-existent file" {
  source_autoconfigure_functions

  local -A result=()
  run __fw_yaml_to_env_vars "$TEST_TEMP_DIR/nonexistent.yaml" result

  # Should return 0 (silent return for missing file)
  [[ "$status" -eq 0 ]]
}

@test "__fw_yaml_to_env_vars: handles empty YAML file" {
  source_autoconfigure_functions

  # Create empty YAML file
  touch "$TEST_TEMP_DIR/empty.yaml"

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/empty.yaml" result

  # Result should be empty
  [[ ${#result[@]} -eq 0 ]]
}

@test "__fw_yaml_to_env_vars: converts lowercase to uppercase" {
  source_autoconfigure_functions

  cat >"$TEST_TEMP_DIR/test.yaml" <<'EOF'
myapp:
  setting: value
EOF

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/test.yaml" result

  # Check uppercase conversion
  [[ "${result[YAML_MYAPP_SETTING]}" == "value" ]]
}

# =============================================================================
# Tests for __fw_merge_env_vars
# =============================================================================

@test "__fw_merge_env_vars: merges two arrays correctly" {
  source_autoconfigure_functions

  local -A base=([YAML_A]="1" [YAML_B]="2")
  local -A override=([YAML_C]="3")
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ "${merged[YAML_A]}" == "1" ]]
  [[ "${merged[YAML_B]}" == "2" ]]
  [[ "${merged[YAML_C]}" == "3" ]]
}

@test "__fw_merge_env_vars: override takes precedence" {
  source_autoconfigure_functions

  local -A base=([YAML_A]="base_value" [YAML_B]="2")
  local -A override=([YAML_A]="override_value")
  local -A merged=()

  __fw_merge_env_vars base override merged

  # Override should win
  [[ "${merged[YAML_A]}" == "override_value" ]]
  [[ "${merged[YAML_B]}" == "2" ]]
}

@test "__fw_merge_env_vars: handles empty base array" {
  source_autoconfigure_functions

  local -A base=()
  local -A override=([YAML_A]="1")
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ "${merged[YAML_A]}" == "1" ]]
  [[ ${#merged[@]} -eq 1 ]]
}

@test "__fw_merge_env_vars: handles empty override array" {
  source_autoconfigure_functions

  local -A base=([YAML_A]="1")
  local -A override=()
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ "${merged[YAML_A]}" == "1" ]]
  [[ ${#merged[@]} -eq 1 ]]
}

@test "__fw_merge_env_vars: handles both empty arrays" {
  source_autoconfigure_functions

  local -A base=()
  local -A override=()
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ ${#merged[@]} -eq 0 ]]
}

# =============================================================================
# Tests for __fw_export_yaml_vars
# =============================================================================

@test "__fw_export_yaml_vars: exports variables globally" {
  source_autoconfigure_functions

  local -A vars=([YAML_TEST_VAR]="test_value")

  __fw_export_yaml_vars vars

  # Check that variable is now globally accessible
  [[ "$YAML_TEST_VAR" == "test_value" ]]
}

@test "__fw_export_yaml_vars: exports multiple variables" {
  source_autoconfigure_functions

  local -A vars=([YAML_VAR1]="value1" [YAML_VAR2]="value2")

  __fw_export_yaml_vars vars

  [[ "$YAML_VAR1" == "value1" ]]
  [[ "$YAML_VAR2" == "value2" ]]
}

@test "__fw_export_yaml_vars: handles empty array" {
  source_autoconfigure_functions

  local -A vars=()

  run __fw_export_yaml_vars vars

  [[ "$status" -eq 0 ]]
}

@test "__fw_export_yaml_vars: expands environment variables like \$HOME" {
  source_autoconfigure_functions

  # Test with $HOME environment variable
  local -A vars=([YAML_TEST_PATH]="\$HOME/some/path")

  __fw_export_yaml_vars vars

  # $HOME should be expanded to actual home directory
  [[ "$YAML_TEST_PATH" == "$HOME/some/path" ]]
  # Should not contain literal $HOME
  [[ "$YAML_TEST_PATH" != *'$HOME'* ]]
}

@test "__fw_export_yaml_vars: expands multiple environment variables" {
  source_autoconfigure_functions

  # Set a custom env var for testing
  export TEST_VAR="test_value"

  local -A vars=([YAML_COMBINED]="\$HOME/\$TEST_VAR/path")

  __fw_export_yaml_vars vars

  # Both variables should be expanded
  [[ "$YAML_COMBINED" == "$HOME/$TEST_VAR/path" ]]
  [[ "$YAML_COMBINED" == "$HOME/test_value/path" ]]
}

@test "__fw_export_yaml_vars: handles values without env vars unchanged" {
  source_autoconfigure_functions

  local -A vars=([YAML_PLAIN]="plain_value")

  __fw_export_yaml_vars vars

  [[ "$YAML_PLAIN" == "plain_value" ]]
}

# =============================================================================
# Tests for configuration priority
# =============================================================================

@test "configuration priority: user config overrides framework config" {
  source_autoconfigure_functions

  # Simulate framework config
  local -A fw_vars=([YAML_RADP_ENV]="default" [YAML_RADP_LOG_DEBUG]="false")

  # Simulate user config with override
  local -A user_vars=([YAML_RADP_ENV]="dev")

  # Merge
  local -A merged=()
  __fw_merge_env_vars fw_vars user_vars merged

  # User config should override framework config
  [[ "${merged[YAML_RADP_ENV]}" == "dev" ]]
  # Framework config should be preserved if not overridden
  [[ "${merged[YAML_RADP_LOG_DEBUG]}" == "false" ]]
}

@test "configuration priority: env-specific config overrides merged config" {
  source_autoconfigure_functions

  # Simulate merged config (fw + user)
  local -A merged=([YAML_RADP_ENV]="dev" [YAML_RADP_LOG_DEBUG]="false")

  # Simulate env-specific config
  local -A env_vars=([YAML_RADP_LOG_DEBUG]="true")

  # Final merge
  local -A final=()
  __fw_merge_env_vars merged env_vars final

  # Env-specific should override
  [[ "${final[YAML_RADP_LOG_DEBUG]}" == "true" ]]
  # Other values preserved
  [[ "${final[YAML_RADP_ENV]}" == "dev" ]]
}

@test "configuration priority: full chain fw -> user -> env" {
  source_autoconfigure_functions

  # Framework config
  local -A fw_vars=([YAML_RADP_ENV]="default" [YAML_RADP_LOG_LEVEL]="info" [YAML_RADP_LOG_DEBUG]="false")

  # User config overrides env
  local -A user_vars=([YAML_RADP_ENV]="dev")

  # First merge: fw + user
  local -A merged1=()
  __fw_merge_env_vars fw_vars user_vars merged1

  # Env-specific config overrides debug
  local -A env_vars=([YAML_RADP_LOG_DEBUG]="true")

  # Second merge: merged1 + env
  local -A final=()
  __fw_merge_env_vars merged1 env_vars final

  # Verify priority chain
  [[ "${final[YAML_RADP_ENV]}" == "dev" ]]        # from user
  [[ "${final[YAML_RADP_LOG_LEVEL]}" == "info" ]] # from framework (not overridden)
  [[ "${final[YAML_RADP_LOG_DEBUG]}" == "true" ]] # from env-specific
}

# =============================================================================
# Integration tests with actual YAML files
# =============================================================================

@test "integration: parse actual framework_config.yaml" {
  source_autoconfigure_functions

  local fw_yaml="$PROJECT_ROOT/src/main/shell/framework/config/framework_config.yaml"

  if [[ -f "$fw_yaml" ]]; then
    local -A result=()
    __fw_yaml_to_env_vars "$fw_yaml" result

    # Should have parsed some variables
    [[ ${#result[@]} -gt 0 ]]
    # Should have YAML_RADP_ENV
    [[ -n "${result[YAML_RADP_ENV]:-}" ]]
  else
    skip "framework_config.yaml not found"
  fi
}

@test "integration: parse actual user config.yaml" {
  source_autoconfigure_functions

  local user_yaml="$PROJECT_ROOT/src/main/shell/config/config.yaml"

  if [[ -f "$user_yaml" ]]; then
    local -A result=()
    __fw_yaml_to_env_vars "$user_yaml" result

    # Should have parsed some variables
    [[ ${#result[@]} -gt 0 ]]
  else
    skip "config.yaml not found"
  fi
}

# =============================================================================
# Tests for __fw_yaml_var_to_shell_var
# =============================================================================

@test "__fw_yaml_var_to_shell_var: converts YAML var to shell var" {
  source_autoconfigure_functions

  local result
  result=$(__fw_yaml_var_to_shell_var "YAML_RADP_USER_CONFIG_EXTEND_MY_VAR")

  [[ "$result" == "gr_radp_user_config_extend_my_var" ]]
}

@test "__fw_yaml_var_to_shell_var: handles nested keys" {
  source_autoconfigure_functions

  local result
  result=$(__fw_yaml_var_to_shell_var "YAML_RADP_USER_CONFIG_EXTEND_DATABASE_HOST")

  [[ "$result" == "gr_radp_user_config_extend_database_host" ]]
}

@test "__fw_yaml_var_to_shell_var: converts uppercase to lowercase" {
  source_autoconfigure_functions

  local result
  result=$(__fw_yaml_var_to_shell_var "YAML_MYAPP_SETTING")

  [[ "$result" == "gr_myapp_setting" ]]
}

# =============================================================================
# Tests for __fw_yaml_var_to_env_var
# =============================================================================

@test "__fw_yaml_var_to_env_var: converts YAML var to env var" {
  source_autoconfigure_functions

  local result
  result=$(__fw_yaml_var_to_env_var "YAML_RADP_USER_CONFIG_EXTEND_MY_VAR")

  [[ "$result" == "GX_RADP_USER_CONFIG_EXTEND_MY_VAR" ]]
}

@test "__fw_yaml_var_to_env_var: handles nested keys" {
  source_autoconfigure_functions

  local result
  result=$(__fw_yaml_var_to_env_var "YAML_RADP_USER_CONFIG_EXTEND_DATABASE_HOST")

  [[ "$result" == "GX_RADP_USER_CONFIG_EXTEND_DATABASE_HOST" ]]
}

# =============================================================================
# Tests for __fw_generate_user_config
# =============================================================================

@test "__fw_generate_user_config: generates config.sh with extend vars" {
  source_autoconfigure_functions

  # Set up the user config file path
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  # Create a vars map with extend variables
  local -A vars=(
    [YAML_RADP_USER_CONFIG_EXTEND_MY_VAR]="my_value"
    [YAML_RADP_USER_CONFIG_EXTEND_DATABASE_HOST]="localhost"
  )

  __fw_generate_user_config vars

  # Check that config.sh was created
  [[ -f "$gr_fw_user_config_file" ]]

  # Check content contains the expected declarations
  grep -q 'declare -gr gr_radp_user_config_extend_my_var=' "$gr_fw_user_config_file"
  grep -q 'declare -gr gr_radp_user_config_extend_database_host=' "$gr_fw_user_config_file"
}

@test "__fw_generate_user_config: generates empty template without extend vars" {
  source_autoconfigure_functions

  # Set up the user config file path
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  # Create a vars map without extend variables
  local -A vars=(
    [YAML_RADP_LOG_DEBUG]="true"
    [YAML_RADP_ENV]="dev"
  )

  __fw_generate_user_config vars

  # Check that config.sh was created with empty template
  [[ -f "$gr_fw_user_config_file" ]]

  # Check that it contains the header but no declare statements
  grep -q '# User configurable vars (auto-generated from YAML)' "$gr_fw_user_config_file"
  run grep -q 'declare -gr' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]
}

@test "__fw_generate_user_config: clears existing content when extend vars removed" {
  source_autoconfigure_functions

  # Set up the user config file path
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  # First, create a config.sh with extend vars
  local -A vars_with_extend=(
    [YAML_RADP_USER_CONFIG_EXTEND_MY_VAR]="my_value"
  )
  __fw_generate_user_config vars_with_extend

  # Verify it was created with the extend var
  [[ -f "$gr_fw_user_config_file" ]]
  grep -q 'declare -gr gr_radp_user_config_extend_my_var=' "$gr_fw_user_config_file"

  # Now call again without extend vars (simulating removal from YAML)
  local -A vars_without_extend=(
    [YAML_RADP_LOG_DEBUG]="true"
  )
  __fw_generate_user_config vars_without_extend

  # Check that config.sh still exists but no longer has the extend var declaration
  [[ -f "$gr_fw_user_config_file" ]]
  run grep -q 'declare -gr gr_radp_user_config_extend_my_var=' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]

  # Should still have the header
  grep -q '# User configurable vars (auto-generated from YAML)' "$gr_fw_user_config_file"
}

@test "__fw_generate_user_config: only includes extend vars in output" {
  source_autoconfigure_functions

  # Set up the user config file path
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  # Create a vars map with mixed variables
  local -A vars=(
    [YAML_RADP_LOG_DEBUG]="true"
    [YAML_RADP_USER_CONFIG_EXTEND_CUSTOM]="custom_value"
    [YAML_RADP_ENV]="dev"
  )

  __fw_generate_user_config vars

  # Check that config.sh was created
  [[ -f "$gr_fw_user_config_file" ]]

  # Check that only extend var is in the file
  grep -q 'gr_radp_user_config_extend_custom' "$gr_fw_user_config_file"
  # Non-extend vars should NOT be in the file
  run grep -q 'gr_radp_log_debug' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]
  run grep -q 'gr_radp_env' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]
}

@test "__fw_generate_user_config: generates correct declare format" {
  source_autoconfigure_functions

  # Set up the user config file path
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  # Create a vars map with an extend variable
  local -A vars=(
    [YAML_RADP_USER_CONFIG_EXTEND_TEST]="test_value"
  )

  __fw_generate_user_config vars

  # Check the exact format of the declaration
  # Format should be: declare -gr gr_xxx="${GX_XXX:-${YAML_XXX:-default}}"
  grep -q 'declare -gr gr_radp_user_config_extend_test="${GX_RADP_USER_CONFIG_EXTEND_TEST:-${YAML_RADP_USER_CONFIG_EXTEND_TEST:-test_value}}"' "$gr_fw_user_config_file"
}

# =============================================================================
# Tests for __fw_resolve_yaml_references
# =============================================================================

@test "__fw_resolve_yaml_references: resolves simple reference" {
  source_autoconfigure_functions

  local -A vars=(
    [YAML_RADP_FW_USER_EXTEND_PATH]="../../extend"
    [YAML_RADP_FW_USER_LIB_PATH]='${radp.fw.user.extend.path}/lib'
  )

  __fw_resolve_yaml_references vars

  # Reference should be resolved
  [[ "${vars[YAML_RADP_FW_USER_LIB_PATH]}" == "../../extend/lib" ]]
}

@test "__fw_resolve_yaml_references: resolves multiple references in same value" {
  source_autoconfigure_functions

  local -A vars=(
    [YAML_RADP_BASE_PATH]="/opt"
    [YAML_RADP_APP_NAME]="myapp"
    [YAML_RADP_FULL_PATH]='${radp.base.path}/${radp.app.name}/bin'
  )

  __fw_resolve_yaml_references vars

  # Both references should be resolved
  [[ "${vars[YAML_RADP_FULL_PATH]}" == "/opt/myapp/bin" ]]
}

@test "__fw_resolve_yaml_references: resolves nested references" {
  source_autoconfigure_functions

  local -A vars=(
    [YAML_RADP_ROOT]="/home/user"
    [YAML_RADP_APP_DIR]='${radp.root}/app'
    [YAML_RADP_LOG_DIR]='${radp.app.dir}/logs'
  )

  __fw_resolve_yaml_references vars

  # Nested references should be resolved
  [[ "${vars[YAML_RADP_APP_DIR]}" == "/home/user/app" ]]
  [[ "${vars[YAML_RADP_LOG_DIR]}" == "/home/user/app/logs" ]]
}

@test "__fw_resolve_yaml_references: handles non-existent reference gracefully" {
  source_autoconfigure_functions

  local -A vars=(
    [YAML_RADP_PATH]='${radp.nonexistent.path}/lib'
  )

  __fw_resolve_yaml_references vars

  # Non-existent reference should remain unchanged
  [[ "${vars[YAML_RADP_PATH]}" == '${radp.nonexistent.path}/lib' ]]
}

@test "__fw_resolve_yaml_references: handles empty array" {
  source_autoconfigure_functions

  local -A vars=()

  run __fw_resolve_yaml_references vars

  [[ "$status" -eq 0 ]]
}

@test "__fw_resolve_yaml_references: preserves values without references" {
  source_autoconfigure_functions

  local -A vars=(
    [YAML_RADP_SIMPLE]="simple_value"
    [YAML_RADP_NUMBER]="123"
  )

  __fw_resolve_yaml_references vars

  # Values without references should remain unchanged
  [[ "${vars[YAML_RADP_SIMPLE]}" == "simple_value" ]]
  [[ "${vars[YAML_RADP_NUMBER]}" == "123" ]]
}

@test "__fw_resolve_yaml_references: handles hyphenated keys" {
  source_autoconfigure_functions

  local -A vars=(
    [YAML_RADP_LOG_ROLLING_POLICY_ENABLED]="true"
    [YAML_RADP_LOG_STATUS]='policy-enabled: ${radp.log.rolling-policy.enabled}'
  )

  __fw_resolve_yaml_references vars

  # Hyphenated key reference should be resolved
  [[ "${vars[YAML_RADP_LOG_STATUS]}" == "policy-enabled: true" ]]
}

@test "__fw_resolve_yaml_references: integration with actual framework config pattern" {
  source_autoconfigure_functions

  # Simulate the actual use case from framework_config.yaml
  local -A vars=(
    [YAML_RADP_FW_USER_EXTEND_PATH]="../../extend"
    [YAML_RADP_FW_USER_LIB_PATH]='${radp.fw.user.extend.path}/lib'
  )

  __fw_resolve_yaml_references vars

  # Should resolve to the expected path
  [[ "${vars[YAML_RADP_FW_USER_LIB_PATH]}" == "../../extend/lib" ]]
  # Original value should remain unchanged
  [[ "${vars[YAML_RADP_FW_USER_EXTEND_PATH]}" == "../../extend" ]]
}
