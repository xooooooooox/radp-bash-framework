#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/io/ modules
# =============================================================================
#
# Run these tests:
#   bats src/test/shell/toolkit_io.bats
#
# =============================================================================

setup() {
  load helpers/test_helper
  setup_test_env

  # Load the modules being tested
  load_toolkit io/01_fs
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_io_get_path_abs
# =============================================================================

@test "radp_io_get_path_abs: function exists" {
  assert_function_exists radp_io_get_path_abs
}

@test "radp_io_get_path_abs: converts relative directory to absolute" {
  local subdir
  subdir=$(create_temp_dir "subdir")

  cd "$TEST_TEMP_DIR"
  local result
  result=$(radp_io_get_path_abs "./subdir")

  [[ "$result" == "$subdir" ]]
}

@test "radp_io_get_path_abs: keeps absolute path unchanged" {
  local result
  result=$(radp_io_get_path_abs "/usr/bin")

  [[ "$result" == "/usr/bin" ]]
}

@test "radp_io_get_path_abs: resolves parent directory references" {
  create_temp_dir "a/b"

  cd "$TEST_TEMP_DIR"
  local result
  result=$(radp_io_get_path_abs "./a/b/..")

  [[ "$result" == "$TEST_TEMP_DIR/a" ]]
}

@test "radp_io_get_path_abs: resolves current directory" {
  cd "$TEST_TEMP_DIR"
  local result
  result=$(radp_io_get_path_abs ".")

  [[ "$result" == "$TEST_TEMP_DIR" ]]
}

@test "radp_io_get_path_abs: handles file paths" {
  create_temp_file "test.txt" "content"

  cd "$TEST_TEMP_DIR"
  local result
  result=$(radp_io_get_path_abs "./test.txt")

  [[ "$result" == "$TEST_TEMP_DIR/test.txt" ]]
}

@test "radp_io_get_path_abs: handles nested file paths" {
  create_temp_dir "nested/dir"
  create_temp_file "nested/dir/file.txt" "content"

  cd "$TEST_TEMP_DIR"
  local result
  result=$(radp_io_get_path_abs "./nested/dir/file.txt")

  [[ "$result" == "$TEST_TEMP_DIR/nested/dir/file.txt" ]]
}
