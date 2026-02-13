#!/usr/bin/env bats
# Test file for autoconfigure.sh

setup() {
  load ../helpers/test_helper
  setup_test_env

  PROJECT_ROOT="$TEST_PROJECT_ROOT"

  # Set up minimal required global variables
  export gr_fw_root_path="$TEST_FRAMEWORK_ROOT"
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

  # Extract and source only the function definitions from autoconfigure.sh
  # (avoids file-scope code that references undefined framework globals)
  source_autoconfigure_functions
}

teardown() {
  teardown_test_env
}

# Helper: extract individual functions from autoconfigure.sh via sed
source_autoconfigure_functions() {
  local autoconfigure_file="$TEST_AUTOCONFIGURE_FILE"

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
  cat >"$TEST_TEMP_DIR/test.yaml" <<'EOF'
radp:
  env: dev
  log:
    debug: true
EOF

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/test.yaml" result

  [[ "${result[YAML_RADP_ENV]}" == "dev" ]]
  [[ "${result[YAML_RADP_LOG_DEBUG]}" == "true" ]]
}

@test "__fw_yaml_to_env_vars: handles nested YAML structures" {
  cat >"$TEST_TEMP_DIR/test.yaml" <<'EOF'
radp:
  log:
    rolling-policy:
      enabled: true
      max-history: 7
EOF

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/test.yaml" result

  [[ "${result[YAML_RADP_LOG_ROLLING_POLICY_ENABLED]}" == "true" ]]
  [[ "${result[YAML_RADP_LOG_ROLLING_POLICY_MAX_HISTORY]}" == "7" ]]
}

@test "__fw_yaml_to_env_vars: returns 0 for non-existent file" {
  local -A result=()
  run __fw_yaml_to_env_vars "$TEST_TEMP_DIR/nonexistent.yaml" result

  [[ "$status" -eq 0 ]]
}

@test "__fw_yaml_to_env_vars: handles empty YAML file" {
  touch "$TEST_TEMP_DIR/empty.yaml"

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/empty.yaml" result

  [[ ${#result[@]} -eq 0 ]]
}

@test "__fw_yaml_to_env_vars: converts lowercase to uppercase" {
  cat >"$TEST_TEMP_DIR/test.yaml" <<'EOF'
myapp:
  setting: value
EOF

  local -A result=()
  __fw_yaml_to_env_vars "$TEST_TEMP_DIR/test.yaml" result

  [[ "${result[YAML_MYAPP_SETTING]}" == "value" ]]
}

# =============================================================================
# Tests for __fw_merge_env_vars
# =============================================================================

@test "__fw_merge_env_vars: merges two arrays correctly" {
  local -A base=([YAML_A]="1" [YAML_B]="2")
  local -A override=([YAML_C]="3")
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ "${merged[YAML_A]}" == "1" ]]
  [[ "${merged[YAML_B]}" == "2" ]]
  [[ "${merged[YAML_C]}" == "3" ]]
}

@test "__fw_merge_env_vars: override takes precedence" {
  local -A base=([YAML_A]="base_value" [YAML_B]="2")
  local -A override=([YAML_A]="override_value")
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ "${merged[YAML_A]}" == "override_value" ]]
  [[ "${merged[YAML_B]}" == "2" ]]
}

@test "__fw_merge_env_vars: handles empty base array" {
  local -A base=()
  local -A override=([YAML_A]="1")
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ "${merged[YAML_A]}" == "1" ]]
  [[ ${#merged[@]} -eq 1 ]]
}

@test "__fw_merge_env_vars: handles empty override array" {
  local -A base=([YAML_A]="1")
  local -A override=()
  local -A merged=()

  __fw_merge_env_vars base override merged

  [[ "${merged[YAML_A]}" == "1" ]]
  [[ ${#merged[@]} -eq 1 ]]
}

@test "__fw_merge_env_vars: handles both empty arrays" {
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
  local -A vars=([YAML_TEST_VAR]="test_value")

  __fw_export_yaml_vars vars

  [[ "$YAML_TEST_VAR" == "test_value" ]]
}

@test "__fw_export_yaml_vars: exports multiple variables" {
  local -A vars=([YAML_VAR1]="value1" [YAML_VAR2]="value2")

  __fw_export_yaml_vars vars

  [[ "$YAML_VAR1" == "value1" ]]
  [[ "$YAML_VAR2" == "value2" ]]
}

@test "__fw_export_yaml_vars: handles empty array" {
  local -A vars=()

  run __fw_export_yaml_vars vars

  [[ "$status" -eq 0 ]]
}

@test "__fw_export_yaml_vars: expands environment variables like \$HOME" {
  local -A vars=([YAML_TEST_PATH]="\$HOME/some/path")

  __fw_export_yaml_vars vars

  [[ "$YAML_TEST_PATH" == "$HOME/some/path" ]]
  [[ "$YAML_TEST_PATH" != *'$HOME'* ]]
}

@test "__fw_export_yaml_vars: expands multiple environment variables" {
  export TEST_VAR="test_value"

  local -A vars=([YAML_COMBINED]="\$HOME/\$TEST_VAR/path")

  __fw_export_yaml_vars vars

  [[ "$YAML_COMBINED" == "$HOME/$TEST_VAR/path" ]]
  [[ "$YAML_COMBINED" == "$HOME/test_value/path" ]]
}

@test "__fw_export_yaml_vars: handles values without env vars unchanged" {
  local -A vars=([YAML_PLAIN]="plain_value")

  __fw_export_yaml_vars vars

  [[ "$YAML_PLAIN" == "plain_value" ]]
}

# =============================================================================
# Tests for configuration priority
# =============================================================================

@test "configuration priority: user config overrides framework config" {
  local -A fw_vars=([YAML_RADP_ENV]="default" [YAML_RADP_LOG_DEBUG]="false")
  local -A user_vars=([YAML_RADP_ENV]="dev")

  local -A merged=()
  __fw_merge_env_vars fw_vars user_vars merged

  [[ "${merged[YAML_RADP_ENV]}" == "dev" ]]
  [[ "${merged[YAML_RADP_LOG_DEBUG]}" == "false" ]]
}

@test "configuration priority: env-specific config overrides merged config" {
  local -A merged=([YAML_RADP_ENV]="dev" [YAML_RADP_LOG_DEBUG]="false")
  local -A env_vars=([YAML_RADP_LOG_DEBUG]="true")

  local -A final=()
  __fw_merge_env_vars merged env_vars final

  [[ "${final[YAML_RADP_LOG_DEBUG]}" == "true" ]]
  [[ "${final[YAML_RADP_ENV]}" == "dev" ]]
}

@test "configuration priority: full chain fw -> user -> env" {
  local -A fw_vars=([YAML_RADP_ENV]="default" [YAML_RADP_LOG_LEVEL]="info" [YAML_RADP_LOG_DEBUG]="false")
  local -A user_vars=([YAML_RADP_ENV]="dev")

  local -A merged1=()
  __fw_merge_env_vars fw_vars user_vars merged1

  local -A env_vars=([YAML_RADP_LOG_DEBUG]="true")

  local -A final=()
  __fw_merge_env_vars merged1 env_vars final

  [[ "${final[YAML_RADP_ENV]}" == "dev" ]]
  [[ "${final[YAML_RADP_LOG_LEVEL]}" == "info" ]]
  [[ "${final[YAML_RADP_LOG_DEBUG]}" == "true" ]]
}

# =============================================================================
# Integration tests with actual YAML files
# =============================================================================

@test "integration: parse actual framework_config.yaml" {
  local fw_yaml="$PROJECT_ROOT/src/main/shell/framework/config/framework_config.yaml"

  if [[ -f "$fw_yaml" ]]; then
    local -A result=()
    __fw_yaml_to_env_vars "$fw_yaml" result

    [[ ${#result[@]} -gt 0 ]]
    [[ -n "${result[YAML_RADP_ENV]:-}" ]]
  else
    skip "framework_config.yaml not found"
  fi
}

@test "integration: parse actual user config.yaml" {
  local user_yaml="$PROJECT_ROOT/src/main/shell/config/config.yaml"

  if [[ -f "$user_yaml" ]]; then
    local -A result=()
    __fw_yaml_to_env_vars "$user_yaml" result

    [[ ${#result[@]} -gt 0 ]]
  else
    skip "config.yaml not found"
  fi
}

# =============================================================================
# Tests for __fw_yaml_var_to_shell_var
# =============================================================================

@test "__fw_yaml_var_to_shell_var: converts YAML var to shell var" {
  local result
  result=$(__fw_yaml_var_to_shell_var "YAML_RADP_EXTEND_MY_VAR")

  [[ "$result" == "gr_radp_extend_my_var" ]]
}

@test "__fw_yaml_var_to_shell_var: handles nested keys" {
  local result
  result=$(__fw_yaml_var_to_shell_var "YAML_RADP_EXTEND_DATABASE_HOST")

  [[ "$result" == "gr_radp_extend_database_host" ]]
}

@test "__fw_yaml_var_to_shell_var: converts uppercase to lowercase" {
  local result
  result=$(__fw_yaml_var_to_shell_var "YAML_MYAPP_SETTING")

  [[ "$result" == "gr_myapp_setting" ]]
}

# =============================================================================
# Tests for __fw_yaml_var_to_env_var
# =============================================================================

@test "__fw_yaml_var_to_env_var: converts YAML var to env var" {
  local result
  result=$(__fw_yaml_var_to_env_var "YAML_RADP_EXTEND_MY_VAR")

  [[ "$result" == "GX_RADP_EXTEND_MY_VAR" ]]
}

@test "__fw_yaml_var_to_env_var: handles nested keys" {
  local result
  result=$(__fw_yaml_var_to_env_var "YAML_RADP_EXTEND_DATABASE_HOST")

  [[ "$result" == "GX_RADP_EXTEND_DATABASE_HOST" ]]
}

# =============================================================================
# Tests for __fw_generate_user_config
# =============================================================================

@test "__fw_generate_user_config: generates config.sh with extend vars" {
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  local -A vars=(
    [YAML_RADP_EXTEND_MY_VAR]="my_value"
    [YAML_RADP_EXTEND_DATABASE_HOST]="localhost"
  )

  __fw_generate_user_config vars

  [[ -f "$gr_fw_user_config_file" ]]

  grep -q 'declare -gr gr_radp_extend_my_var=' "$gr_fw_user_config_file"
  grep -q 'declare -gr gr_radp_extend_database_host=' "$gr_fw_user_config_file"
}

@test "__fw_generate_user_config: generates empty template without extend vars" {
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  local -A vars=(
    [YAML_RADP_LOG_DEBUG]="true"
    [YAML_RADP_ENV]="dev"
  )

  __fw_generate_user_config vars

  [[ -f "$gr_fw_user_config_file" ]]

  grep -q '# User configurable vars (auto-generated from YAML)' "$gr_fw_user_config_file"
  run grep -q 'declare -gr' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]
}

@test "__fw_generate_user_config: clears existing content when extend vars removed" {
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  local -A vars_with_extend=(
    [YAML_RADP_EXTEND_MY_VAR]="my_value"
  )
  __fw_generate_user_config vars_with_extend

  [[ -f "$gr_fw_user_config_file" ]]
  grep -q 'declare -gr gr_radp_extend_my_var=' "$gr_fw_user_config_file"

  local -A vars_without_extend=(
    [YAML_RADP_LOG_DEBUG]="true"
  )
  __fw_generate_user_config vars_without_extend

  [[ -f "$gr_fw_user_config_file" ]]
  run grep -q 'declare -gr gr_radp_extend_my_var=' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]

  grep -q '# User configurable vars (auto-generated from YAML)' "$gr_fw_user_config_file"
}

@test "__fw_generate_user_config: only includes extend vars in output" {
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  local -A vars=(
    [YAML_RADP_LOG_DEBUG]="true"
    [YAML_RADP_EXTEND_CUSTOM]="custom_value"
    [YAML_RADP_ENV]="dev"
  )

  __fw_generate_user_config vars

  [[ -f "$gr_fw_user_config_file" ]]

  grep -q 'gr_radp_extend_custom' "$gr_fw_user_config_file"
  run grep -q 'gr_radp_log_debug' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]
  run grep -q 'gr_radp_env' "$gr_fw_user_config_file"
  [[ "$status" -ne 0 ]]
}

@test "__fw_generate_user_config: generates correct declare format" {
  gr_fw_user_config_file="$TEST_TEMP_DIR/config.sh"

  local -A vars=(
    [YAML_RADP_EXTEND_TEST]="test_value"
  )

  __fw_generate_user_config vars

  grep -q 'declare -gr gr_radp_extend_test="${GX_RADP_EXTEND_TEST:-${YAML_RADP_EXTEND_TEST:-test_value}}"' "$gr_fw_user_config_file"
}

# =============================================================================
# Tests for __fw_resolve_yaml_references
# =============================================================================

@test "__fw_resolve_yaml_references: resolves simple reference" {
  local -A vars=(
    [YAML_RADP_FW_USER_EXTEND_PATH]="../../extend"
    [YAML_RADP_FW_USER_LIB_PATH]='${radp.fw.user.extend.path}/lib'
  )

  __fw_resolve_yaml_references vars

  [[ "${vars[YAML_RADP_FW_USER_LIB_PATH]}" == "../../extend/lib" ]]
}

@test "__fw_resolve_yaml_references: resolves multiple references in same value" {
  local -A vars=(
    [YAML_RADP_BASE_PATH]="/opt"
    [YAML_RADP_APP_NAME]="myapp"
    [YAML_RADP_FULL_PATH]='${radp.base.path}/${radp.app.name}/bin'
  )

  __fw_resolve_yaml_references vars

  [[ "${vars[YAML_RADP_FULL_PATH]}" == "/opt/myapp/bin" ]]
}

@test "__fw_resolve_yaml_references: resolves nested references" {
  local -A vars=(
    [YAML_RADP_ROOT]="/home/user"
    [YAML_RADP_APP_DIR]='${radp.root}/app'
    [YAML_RADP_LOG_DIR]='${radp.app.dir}/logs'
  )

  __fw_resolve_yaml_references vars

  [[ "${vars[YAML_RADP_APP_DIR]}" == "/home/user/app" ]]
  [[ "${vars[YAML_RADP_LOG_DIR]}" == "/home/user/app/logs" ]]
}

@test "__fw_resolve_yaml_references: handles non-existent reference gracefully" {
  local -A vars=(
    [YAML_RADP_PATH]='${radp.nonexistent.path}/lib'
  )

  __fw_resolve_yaml_references vars

  [[ "${vars[YAML_RADP_PATH]}" == '${radp.nonexistent.path}/lib' ]]
}

@test "__fw_resolve_yaml_references: handles empty array" {
  local -A vars=()

  run __fw_resolve_yaml_references vars

  [[ "$status" -eq 0 ]]
}

@test "__fw_resolve_yaml_references: preserves values without references" {
  local -A vars=(
    [YAML_RADP_SIMPLE]="simple_value"
    [YAML_RADP_NUMBER]="123"
  )

  __fw_resolve_yaml_references vars

  [[ "${vars[YAML_RADP_SIMPLE]}" == "simple_value" ]]
  [[ "${vars[YAML_RADP_NUMBER]}" == "123" ]]
}

@test "__fw_resolve_yaml_references: handles hyphenated keys" {
  local -A vars=(
    [YAML_RADP_LOG_ROLLING_POLICY_ENABLED]="true"
    [YAML_RADP_LOG_STATUS]='policy-enabled: ${radp.log.rolling-policy.enabled}'
  )

  __fw_resolve_yaml_references vars

  [[ "${vars[YAML_RADP_LOG_STATUS]}" == "policy-enabled: true" ]]
}

@test "__fw_resolve_yaml_references: integration with actual framework config pattern" {
  local -A vars=(
    [YAML_RADP_FW_USER_EXTEND_PATH]="../../extend"
    [YAML_RADP_FW_USER_LIB_PATH]='${radp.fw.user.extend.path}/lib'
  )

  __fw_resolve_yaml_references vars

  [[ "${vars[YAML_RADP_FW_USER_LIB_PATH]}" == "../../extend/lib" ]]
  [[ "${vars[YAML_RADP_FW_USER_EXTEND_PATH]}" == "../../extend" ]]
}
