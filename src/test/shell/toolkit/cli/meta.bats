#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/cli/01_meta.sh
# =============================================================================

setup() {
  load ../../helpers/test_helper
  setup_test_env

  load_toolkit cli/01_meta

  TEST_COMMANDS_DIR=$(create_temp_dir "commands")
}

teardown() {
  teardown_test_env
}

# Helper: create a command file with meta annotations
create_meta_command() {
  local name="$1"
  shift
  local file="${TEST_COMMANDS_DIR}/${name}.sh"
  printf '%s\n' "$@" > "$file"
  echo "$file"
}

# =============================================================================
# radp_cli_parse_meta
# =============================================================================

@test "radp_cli_parse_meta: function exists" {
  assert_function_exists radp_cli_parse_meta
}

@test "radp_cli_parse_meta: parses @cmd and @desc" {
  local file
  file=$(create_meta_command "hello" \
    '#!/usr/bin/env bash' \
    '# @cmd' \
    '# @desc Say hello to the world' \
    '' \
    'cmd_hello() { echo "hello"; }')

  local -A meta=()
  radp_cli_parse_meta "$file" meta

  [[ "${meta[is_cmd]}" == "true" ]]
  [[ "${meta[desc]}" == "Say hello to the world" ]]
}

@test "radp_cli_parse_meta: returns 1 for non-existent file" {
  local -A meta=()
  run radp_cli_parse_meta "/nonexistent/file.sh" meta
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_parse_meta: returns 1 for file without @cmd" {
  local file
  file=$(create_meta_command "nocmd" \
    '#!/usr/bin/env bash' \
    '# @desc Not a command' \
    '' \
    'helper() { echo "helper"; }')

  run radp_cli_parse_meta "$file" meta
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_parse_meta: parses @arg annotations" {
  local file
  file=$(create_meta_command "deploy" \
    '#!/usr/bin/env bash' \
    '# @cmd' \
    '# @desc Deploy application' \
    '# @arg name! Application name' \
    '# @arg env Environment name' \
    '' \
    'cmd_deploy() { echo "deploy"; }')

  local -A meta=()
  radp_cli_parse_meta "$file" meta

  [[ "${meta[args]}" == *"name!"* ]]
  [[ "${meta[args]}" == *"env "* ]]
}

@test "radp_cli_parse_meta: parses @option and @flag" {
  local file
  file=$(create_meta_command "serve" \
    '#!/usr/bin/env bash' \
    '# @cmd' \
    '# @desc Start server' \
    '# @option -p, --port <number> Port number [default: 8080]' \
    '# @flag --verbose Enable verbose output' \
    '' \
    'cmd_serve() { echo "serve"; }')

  local -A meta=()
  radp_cli_parse_meta "$file" meta

  [[ "${meta[options]}" == *"--port"* ]]
  [[ "${meta[options]}" == *"--verbose"* ]]
}

@test "radp_cli_parse_meta: parses @example" {
  local file
  file=$(create_meta_command "build" \
    '#!/usr/bin/env bash' \
    '# @cmd' \
    '# @desc Build project' \
    '# @example build --release' \
    '' \
    'cmd_build() { echo "build"; }')

  local -A meta=()
  radp_cli_parse_meta "$file" meta

  [[ "${meta[examples]}" == *"build --release"* ]]
}

@test "radp_cli_parse_meta: parses @meta passthrough" {
  local file
  file=$(create_meta_command "exec" \
    '#!/usr/bin/env bash' \
    '# @cmd' \
    '# @desc Execute command' \
    '# @meta passthrough' \
    '' \
    'cmd_exec() { "$@"; }')

  local -A meta=()
  radp_cli_parse_meta "$file" meta

  [[ "${meta[metas]}" == *"passthrough"* ]]
}

# =============================================================================
# radp_cli_parse_arg_spec
# =============================================================================

@test "radp_cli_parse_arg_spec: function exists" {
  assert_function_exists radp_cli_parse_arg_spec
}

@test "radp_cli_parse_arg_spec: parses optional arg" {
  local -A arg=()
  radp_cli_parse_arg_spec "name The name" arg

  [[ "${arg[name]}" == "name" ]]
  [[ "${arg[desc]}" == "The name" ]]
  [[ "${arg[required]}" == "false" ]]
  [[ "${arg[variadic]}" == "false" ]]
}

@test "radp_cli_parse_arg_spec: parses required arg" {
  local -A arg=()
  radp_cli_parse_arg_spec "name! The name" arg

  [[ "${arg[name]}" == "name" ]]
  [[ "${arg[required]}" == "true" ]]
}

@test "radp_cli_parse_arg_spec: parses variadic arg" {
  local -A arg=()
  radp_cli_parse_arg_spec "files~ Input files" arg

  [[ "${arg[name]}" == "files" ]]
  [[ "${arg[variadic]}" == "true" ]]
}

# =============================================================================
# radp_cli_parse_option_spec
# =============================================================================

@test "radp_cli_parse_option_spec: function exists" {
  assert_function_exists radp_cli_parse_option_spec
}

@test "radp_cli_parse_option_spec: parses short and long option" {
  local -A opt=()
  radp_cli_parse_option_spec "-p, --port <number> Port number" opt

  [[ "${opt[short]}" == "p" ]]
  [[ "${opt[long]}" == "port" ]]
  [[ "${opt[value_name]}" == "number" ]]
  [[ "${opt[has_value]}" == "true" ]]
}

@test "radp_cli_parse_option_spec: parses long-only option" {
  local -A opt=()
  radp_cli_parse_option_spec "--output <dir> Output directory" opt

  [[ -z "${opt[short]}" ]]
  [[ "${opt[long]}" == "output" ]]
  [[ "${opt[value_name]}" == "dir" ]]
}

@test "radp_cli_parse_option_spec: parses flag (no value)" {
  local -A opt=()
  radp_cli_parse_option_spec "--verbose Enable verbose output" opt

  [[ "${opt[long]}" == "verbose" ]]
  [[ -z "${opt[value_name]}" ]]
  [[ "${opt[has_value]}" == "false" ]]
}

@test "radp_cli_parse_option_spec: extracts default value" {
  local -A opt=()
  radp_cli_parse_option_spec "-p, --port <number> Port number [default: 8080]" opt

  [[ "${opt[default]}" == "8080" ]]
}

# =============================================================================
# radp_cli_get_complete_func
# =============================================================================

@test "radp_cli_get_complete_func: function exists" {
  assert_function_exists radp_cli_get_complete_func
}

@test "radp_cli_get_complete_func: finds completion function" {
  local completes
  completes=$(printf 'name _complete_names\nenv _complete_envs')

  run radp_cli_get_complete_func "env" "$completes"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "_complete_envs" ]]
}

@test "radp_cli_get_complete_func: returns 1 when not found" {
  local completes="name _complete_names"

  run radp_cli_get_complete_func "missing" "$completes"
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_cli_get_arg_values
# =============================================================================

@test "radp_cli_get_arg_values: function exists" {
  assert_function_exists radp_cli_get_arg_values
}

@test "radp_cli_get_arg_values: finds arg values" {
  local arg_values
  arg_values=$(printf 'action start stop restart')

  run radp_cli_get_arg_values "action" "$arg_values"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "start stop restart" ]]
}

@test "radp_cli_get_arg_values: returns 1 when not found" {
  local arg_values="action start stop"

  run radp_cli_get_arg_values "missing" "$arg_values"
  [[ "$status" -eq 1 ]]
}

# =============================================================================
# radp_cli_extract_cmd_func
# =============================================================================

@test "radp_cli_extract_cmd_func: function exists" {
  assert_function_exists radp_cli_extract_cmd_func
}

@test "radp_cli_extract_cmd_func: extracts function name" {
  local file
  file=$(create_meta_command "hello" \
    '#!/usr/bin/env bash' \
    '# @cmd' \
    '' \
    'cmd_hello() {' \
    '  echo "hello"' \
    '}')

  run radp_cli_extract_cmd_func "$file"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "hello" ]]
}

@test "radp_cli_extract_cmd_func: extracts subcommand function name" {
  local file
  file=$(create_meta_command "migrate" \
    '#!/usr/bin/env bash' \
    '# @cmd' \
    '' \
    'cmd_db_migrate() {' \
    '  echo "migrating"' \
    '}')

  run radp_cli_extract_cmd_func "$file"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "db_migrate" ]]
}

@test "radp_cli_extract_cmd_func: returns 1 for non-existent file" {
  run radp_cli_extract_cmd_func "/nonexistent/file.sh"
  [[ "$status" -eq 1 ]]
}

@test "radp_cli_extract_cmd_func: returns 1 for file without cmd_ function" {
  local file
  file=$(create_meta_command "helper" \
    '#!/usr/bin/env bash' \
    '' \
    'helper_func() {' \
    '  echo "not a command"' \
    '}')

  run radp_cli_extract_cmd_func "$file"
  [[ "$status" -eq 1 ]]
}
