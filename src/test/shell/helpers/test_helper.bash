#!/usr/bin/env bash
# =============================================================================
# Test Helper for radp-bash-framework
# =============================================================================
#
# This file provides common utilities for bats tests. Source it in your test
# file's setup() function.
#
# Usage in *.bats files:
#
#   setup() {
#     load helpers/test_helper
#     setup_test_env
#     load_toolkit core/02_array
#   }
#
#   teardown() {
#     teardown_test_env
#   }
#
#   @test "my test" {
#     # test code here
#   }
#
# =============================================================================

# Project root path (computed once)
export TEST_PROJECT_ROOT
TEST_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

# Framework paths
export TEST_FRAMEWORK_ROOT="${TEST_PROJECT_ROOT}/src/main/shell/framework"
export TEST_TOOLKIT_DIR="${TEST_FRAMEWORK_ROOT}/bootstrap/context/libs/toolkit"
export TEST_VARS_DIR="${TEST_FRAMEWORK_ROOT}/bootstrap/context/vars"

# =============================================================================
# Setup / Teardown
# =============================================================================

# Initialize test environment. Call this in setup().
setup_test_env() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
}

# Clean up test environment. Call this in teardown().
teardown_test_env() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# =============================================================================
# Module Loading
# =============================================================================

# Load a toolkit module by path (e.g., "core/02_array", "io/01_fs")
#
# Example:
#   load_toolkit core/02_array
#   load_toolkit io/01_fs os/01_distro
#
load_toolkit() {
  local module
  for module in "$@"; do
    local path="${TEST_TOOLKIT_DIR}/${module}.sh"
    if [[ -f "$path" ]]; then
      # shellcheck source=/dev/null
      source "$path"
    else
      echo "Error: Toolkit module not found: $module" >&2
      echo "  Expected path: $path" >&2
      return 1
    fi
  done
}

# Load internal framework helpers (e.g., "dynamic/dynamic")
#
# Example:
#   load_internal dynamic/dynamic
#
load_internal() {
  local module
  for module in "$@"; do
    local path="${TEST_VARS_DIR}/${module}.sh"
    if [[ -f "$path" ]]; then
      # shellcheck source=/dev/null
      source "$path"
    else
      echo "Error: Internal module not found: $module" >&2
      echo "  Expected path: $path" >&2
      return 1
    fi
  done
}

# =============================================================================
# Test Utilities
# =============================================================================

# Create a temporary file with content
# Usage: create_temp_file "filename" "content"
# Returns: path to created file via stdout
create_temp_file() {
  local name="$1"
  local content="${2:-}"
  local path="${TEST_TEMP_DIR}/${name}"

  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" > "$path"
  echo "$path"
}

# Create a temporary directory
# Usage: create_temp_dir "dirname"
# Returns: path to created directory via stdout
create_temp_dir() {
  local name="$1"
  local path="${TEST_TEMP_DIR}/${name}"

  mkdir -p "$path"
  echo "$path"
}

# Assert that a function exists
# Usage: assert_function_exists "function_name"
assert_function_exists() {
  local func="$1"
  if ! declare -f "$func" &>/dev/null; then
    echo "Expected function '$func' to exist, but it doesn't" >&2
    return 1
  fi
}

# Assert arrays are equal
# Usage: assert_array_equals array_name "expected1" "expected2" ...
assert_array_equals() {
  local -n arr_ref=$1
  shift
  local -a expected=("$@")

  if [[ ${#arr_ref[@]} -ne ${#expected[@]} ]]; then
    echo "Array length mismatch: got ${#arr_ref[@]}, expected ${#expected[@]}" >&2
    echo "  Actual: ${arr_ref[*]}" >&2
    echo "  Expected: ${expected[*]}" >&2
    return 1
  fi

  local i
  for i in "${!expected[@]}"; do
    if [[ "${arr_ref[$i]}" != "${expected[$i]}" ]]; then
      echo "Array element mismatch at index $i: got '${arr_ref[$i]}', expected '${expected[$i]}'" >&2
      return 1
    fi
  done
}
