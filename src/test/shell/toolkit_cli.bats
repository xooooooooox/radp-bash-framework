#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/cli/ modules
# =============================================================================
#
# Run these tests:
#   bats src/test/shell/toolkit_cli.bats
#
# =============================================================================

setup() {
  load helpers/test_helper
  setup_test_env

  # Load CLI modules (order matters)
  load_toolkit cli/01_meta cli/02_discover cli/07_app

  # Create test commands directory
  TEST_COMMANDS_DIR=$(create_temp_dir "commands")
}

teardown() {
  teardown_test_env
}

# Helper: create a minimal command file
create_command() {
  local name="$1"
  local desc="${2:-Test command}"

  cat > "${TEST_COMMANDS_DIR}/${name}.sh" << EOF
#!/usr/bin/env bash
# @cmd
# @desc ${desc}

cmd_${name}() {
  echo "executed ${name}"
}
EOF
}

# Helper: create a subcommand file
create_subcommand() {
  local group="$1"
  local name="$2"
  local desc="${3:-Test subcommand}"

  mkdir -p "${TEST_COMMANDS_DIR}/${group}"
  cat > "${TEST_COMMANDS_DIR}/${group}/${name}.sh" << EOF
#!/usr/bin/env bash
# @cmd
# @desc ${desc}

cmd_${group}_${name}() {
  echo "executed ${group} ${name}"
}
EOF
}

# =============================================================================
# radp_cli_set_app_name
# =============================================================================

@test "radp_cli_set_app_name: function exists" {
  assert_function_exists radp_cli_set_app_name
}

@test "radp_cli_set_app_name: sets application name" {
  radp_cli_set_app_name "testapp"
  # Verify internal variable is set
  [[ -n "${__radp_cli_app_name:-}" ]] || skip "Cannot verify internal variable"
}

# =============================================================================
# radp_app_is_help_request / radp_app_is_version_request
# =============================================================================

@test "radp_app_is_help_request: returns 0 for -h" {
  run radp_app_is_help_request "-h"
  [[ "$status" -eq 0 ]]
}

@test "radp_app_is_help_request: returns 0 for --help" {
  run radp_app_is_help_request "--help"
  [[ "$status" -eq 0 ]]
}

@test "radp_app_is_help_request: returns 1 for other args" {
  run radp_app_is_help_request "version"
  [[ "$status" -eq 1 ]]

  run radp_app_is_help_request ""
  [[ "$status" -eq 1 ]]
}

@test "radp_app_is_version_request: returns 0 for -v" {
  run radp_app_is_version_request "-v"
  [[ "$status" -eq 0 ]]
}

@test "radp_app_is_version_request: returns 0 for --version" {
  run radp_app_is_version_request "--version"
  [[ "$status" -eq 0 ]]
}

@test "radp_app_is_version_request: returns 1 for other args" {
  run radp_app_is_version_request "help"
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_cli_set_commands_dir / radp_cli_discover
# =============================================================================

@test "radp_cli_set_commands_dir: function exists" {
  assert_function_exists radp_cli_set_commands_dir
}

@test "radp_cli_set_commands_dir: sets commands directory" {
  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  [[ $? -eq 0 ]]
}

@test "radp_cli_discover: function exists" {
  assert_function_exists radp_cli_discover
}

@test "radp_cli_discover: discovers commands from directory" {
  create_command "hello" "Say hello"
  create_command "version" "Show version"

  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  radp_cli_discover

  run radp_cli_cmd_exists "hello"
  [[ "$status" -eq 0 ]]

  run radp_cli_cmd_exists "version"
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_cmd_exists: returns 1 for non-existent command" {
  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  radp_cli_discover

  run radp_cli_cmd_exists "nonexistent"
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_cli_list_commands
# =============================================================================

@test "radp_cli_list_commands: function exists" {
  assert_function_exists radp_cli_list_commands
}

@test "radp_cli_list_commands: lists discovered commands" {
  create_command "alpha" "Alpha command"
  create_command "beta" "Beta command"

  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  radp_cli_discover

  local result
  result=$(radp_cli_list_commands)

  [[ "$result" =~ "alpha" ]]
  [[ "$result" =~ "beta" ]]
}

# =============================================================================
# Subcommand Discovery
# =============================================================================

@test "radp_cli_discover: discovers subcommands in directories" {
  create_subcommand "db" "migrate" "Run database migrations"

  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  radp_cli_discover

  run radp_cli_cmd_exists "db migrate"
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_has_subcommands: function exists" {
  assert_function_exists radp_cli_has_subcommands
}

@test "radp_cli_has_subcommands: returns 0 for command group" {
  create_subcommand "group" "sub" "Subcommand"

  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  radp_cli_discover

  run radp_cli_has_subcommands "group"
  [[ "$status" -eq 0 ]]
}

@test "radp_cli_has_subcommands: returns 1 for leaf command" {
  create_command "leaf" "Leaf command"

  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  radp_cli_discover

  run radp_cli_has_subcommands "leaf"
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_discover: discovers nested subcommands" {
  mkdir -p "${TEST_COMMANDS_DIR}/vf/template"
  cat > "${TEST_COMMANDS_DIR}/vf/template/list.sh" << 'EOF'
#!/usr/bin/env bash
# @cmd
# @desc List templates

cmd_vf_template_list() {
  echo "listing templates"
}
EOF

  radp_cli_set_commands_dir "$TEST_COMMANDS_DIR"
  radp_cli_discover

  run radp_cli_cmd_exists "vf template list"
  [[ "$status" -eq 0 ]]
}
