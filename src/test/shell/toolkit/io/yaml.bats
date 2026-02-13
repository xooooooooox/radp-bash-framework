#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/io/05_yaml.sh
# =============================================================================

setup() {
  load ../../helpers/test_helper
  setup_test_env

  load_toolkit io/05_yaml
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_io_yaml_get_value
# =============================================================================

@test "radp_io_yaml_get_value: function exists" {
  assert_function_exists radp_io_yaml_get_value
}

@test "radp_io_yaml_get_value: extracts simple value" {
  local yaml="name: myapp"

  run radp_io_yaml_get_value "name" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "myapp" ]]
}

@test "radp_io_yaml_get_value: extracts value with leading whitespace" {
  local yaml="  version: 1.2.3"

  run radp_io_yaml_get_value "version" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "1.2.3" ]]
}

@test "radp_io_yaml_get_value: strips double quotes" {
  local yaml='name: "hello world"'

  run radp_io_yaml_get_value "name" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "hello world" ]]
}

@test "radp_io_yaml_get_value: strips single quotes" {
  local yaml="name: 'hello world'"

  run radp_io_yaml_get_value "name" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "hello world" ]]
}

@test "radp_io_yaml_get_value: returns first match only" {
  local yaml=$'name: first\nname: second'

  run radp_io_yaml_get_value "name" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "first" ]]
}

@test "radp_io_yaml_get_value: returns empty for missing key" {
  local yaml="name: myapp"

  run radp_io_yaml_get_value "missing" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}

@test "radp_io_yaml_get_value: reads from stdin when no content arg" {
  local result
  result=$(echo "author: john" | radp_io_yaml_get_value "author")
  [[ "$result" == "john" ]]
}

@test "radp_io_yaml_get_value: handles multi-line yaml" {
  local yaml
  yaml=$(printf 'name: myapp\nversion: 2.0\nauthor: jane')

  run radp_io_yaml_get_value "version" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "2.0" ]]
}

# =============================================================================
# radp_io_yaml_get_list
# =============================================================================

@test "radp_io_yaml_get_list: function exists" {
  assert_function_exists radp_io_yaml_get_list
}

@test "radp_io_yaml_get_list: extracts list items" {
  local yaml
  yaml=$(printf '  - foo\n  - bar\n  - baz')

  local result
  result=$(echo "$yaml" | radp_io_yaml_get_list)

  [[ "$result" == *"foo"* ]]
  [[ "$result" == *"bar"* ]]
  [[ "$result" == *"baz"* ]]
}

@test "radp_io_yaml_get_list: strips leading dash and whitespace" {
  local result
  result=$(printf '%s\n' '- hello world' '- test item' | radp_io_yaml_get_list)

  local first_line
  first_line=$(echo "$result" | head -1)
  [[ "$first_line" == "hello world" ]]
}

@test "radp_io_yaml_get_list: ignores non-list lines" {
  local yaml
  yaml=$(printf 'key: value\n- item1\nnot a list\n- item2')

  local result
  result=$(echo "$yaml" | radp_io_yaml_get_list)

  local count
  count=$(echo "$result" | wc -l | tr -d ' ')
  [[ "$count" -eq 2 ]]
}

# =============================================================================
# radp_io_yaml_get_section
# =============================================================================

@test "radp_io_yaml_get_section: function exists" {
  assert_function_exists radp_io_yaml_get_section
}

@test "radp_io_yaml_get_section: extracts section with nested content" {
  local yaml
  yaml=$(printf 'dependencies:\n  - foo\n  - bar\nother: value')

  run radp_io_yaml_get_section "dependencies" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"dependencies:"* ]]
  [[ "$output" == *"foo"* ]]
  [[ "$output" == *"bar"* ]]
  [[ "$output" != *"other: value"* ]]
}

@test "radp_io_yaml_get_section: stops at next top-level key" {
  local yaml
  yaml=$(printf 'first:\n  a: 1\n  b: 2\nsecond:\n  c: 3')

  run radp_io_yaml_get_section "first" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"a: 1"* ]]
  [[ "$output" == *"b: 2"* ]]
  [[ "$output" != *"c: 3"* ]]
}

@test "radp_io_yaml_get_section: returns empty for missing section" {
  local yaml="name: myapp"

  run radp_io_yaml_get_section "missing" "$yaml"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}

# =============================================================================
# radp_io_yaml_has_key
# =============================================================================

@test "radp_io_yaml_has_key: function exists" {
  assert_function_exists radp_io_yaml_has_key
}

@test "radp_io_yaml_has_key: returns 0 for existing key" {
  local yaml="enabled: true"

  run radp_io_yaml_has_key "enabled" "$yaml"
  [[ "$status" -eq 0 ]]
}

@test "radp_io_yaml_has_key: returns 1 for missing key" {
  local yaml="enabled: true"

  run radp_io_yaml_has_key "missing" "$yaml"
  [[ "$status" -eq 1 ]]
}

@test "radp_io_yaml_has_key: matches nested key with indentation" {
  local yaml
  yaml=$(printf 'root:\n  nested: value')

  run radp_io_yaml_has_key "nested" "$yaml"
  [[ "$status" -eq 0 ]]
}
