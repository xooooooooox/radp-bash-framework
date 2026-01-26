#!/usr/bin/env bats
# =============================================================================
# Tests for toolkit/core/ modules
# =============================================================================
#
# Run these tests:
#   bats src/test/shell/toolkit_core.bats
#
# Add new tests:
#   1. Load required modules in setup() using load_toolkit
#   2. Write @test functions following existing patterns
#
# =============================================================================

setup() {
  load helpers/test_helper
  setup_test_env

  # Load the modules being tested
  load_toolkit core/02_array
}

teardown() {
  teardown_test_env
}

# =============================================================================
# radp_nr_arr_merge_unique
# =============================================================================

@test "radp_nr_arr_merge_unique: function exists" {
  assert_function_exists radp_nr_arr_merge_unique
}

@test "radp_nr_arr_merge_unique: merges single source array" {
  local -a src=("a" "b" "c")
  local -a dest=()

  radp_nr_arr_merge_unique dest src

  assert_array_equals dest "a" "b" "c"
}

@test "radp_nr_arr_merge_unique: merges multiple source arrays" {
  local -a src1=("a" "b")
  local -a src2=("c" "d")
  local -a dest=()

  radp_nr_arr_merge_unique dest src1 src2

  assert_array_equals dest "a" "b" "c" "d"
}

@test "radp_nr_arr_merge_unique: removes duplicates across arrays" {
  local -a src1=("a" "b" "c")
  local -a src2=("b" "c" "d")
  local -a dest=()

  radp_nr_arr_merge_unique dest src1 src2

  [[ ${#dest[@]} -eq 4 ]]
  # Check all expected values exist
  local has_a=false has_b=false has_c=false has_d=false
  for v in "${dest[@]}"; do
    case "$v" in
      a) has_a=true ;;
      b) has_b=true ;;
      c) has_c=true ;;
      d) has_d=true ;;
    esac
  done
  [[ "$has_a" == "true" && "$has_b" == "true" && "$has_c" == "true" && "$has_d" == "true" ]]
}

@test "radp_nr_arr_merge_unique: clears destination before merge" {
  local -a src=("x")
  local -a dest=("old" "values")

  radp_nr_arr_merge_unique dest src

  assert_array_equals dest "x"
}

@test "radp_nr_arr_merge_unique: handles empty source arrays" {
  local -a src1=()
  local -a src2=("a")
  local -a dest=()

  radp_nr_arr_merge_unique dest src1 src2

  assert_array_equals dest "a"
}

@test "radp_nr_arr_merge_unique: handles no source arrays" {
  local -a dest=("will" "be" "cleared")

  radp_nr_arr_merge_unique dest

  [[ ${#dest[@]} -eq 0 ]]
}

@test "radp_nr_arr_merge_unique: skips empty values" {
  local -a src=("a" "" "b" "" "c")
  local -a dest=()

  radp_nr_arr_merge_unique dest src

  assert_array_equals dest "a" "b" "c"
}
