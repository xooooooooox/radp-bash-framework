# Testing Guide

This directory contains [bats](https://github.com/bats-core/bats-core) tests for radp-bash-framework.

## Running Tests

```bash
# Run all tests
bats src/test/shell/

# Run specific test file
bats src/test/shell/toolkit_core.bats

# Run with verbose output
bats --verbose-run src/test/shell/toolkit_core.bats
```

## Test Structure

```
src/test/shell/
├── helpers/
│   └── test_helper.bash    # Shared test utilities
├── toolkit_core.bats       # Tests for toolkit/core/
├── toolkit_io.bats         # Tests for toolkit/io/
├── toolkit_os.bats         # Tests for toolkit/os/
├── toolkit_cli.bats        # Tests for toolkit/cli/
├── autoconfigure.bats      # Tests for autoconfigure
├── logger.bats             # Tests for logger
└── README.md               # This file
```

## Writing New Tests

### 1. Create a New Test File

```bash
#!/usr/bin/env bats
# =============================================================================
# Tests for <module>
# =============================================================================

setup() {
  load helpers/test_helper
  setup_test_env

  # Load the modules you want to test
  load_toolkit <domain >/ <module_file>
}

teardown() {
  teardown_test_env
}

@test "function_name: description of test" {
  # Test code here
  [[ "expected" == "expected" ]]
}
```

### 2. Loading Modules

The `test_helper.bash` provides functions to load framework modules:

```bash
# Load toolkit modules (e.g., core/02_array, io/01_fs)
load_toolkit core/02_array
load_toolkit io/01_fs os/01_distro # Load multiple at once

# Load internal framework helpers (e.g., dynamic/dynamic)
load_internal dynamic/dynamic
```

### 3. Available Test Utilities

From `helpers/test_helper.bash`:

| Function                            | Description                                    |
|-------------------------------------|------------------------------------------------|
| `setup_test_env`                    | Initialize test environment (creates temp dir) |
| `teardown_test_env`                 | Clean up test environment                      |
| `create_temp_file "name" "content"` | Create a temp file, returns path               |
| `create_temp_dir "name"`            | Create a temp directory, returns path          |
| `assert_function_exists "func"`     | Assert a function is defined                   |
| `assert_array_equals arr "a" "b"`   | Assert array equals expected values            |

### 4. Test Naming Convention

```bash
@test "function_name: brief description" {
  ...
}
```

Examples:

- `@test "radp_io_get_path_abs: converts relative to absolute"`
- `@test "radp_cli_discover: discovers subcommands in directories"`

### 5. Using BATS Features

```bash
# Run command and capture status/output
run some_command arg1 arg2
[[ "$status" -eq 0 ]] # Check exit status
[[ "$output" =~ "pattern" ]] # Check output

# Skip platform-dependent tests
if [[ "$(uname)" != "Linux" ]]; then
  skip "Linux only"
fi
```

## Adding Tests for New Toolkit Functions

1. Identify which module file contains the function (e.g., `toolkit/core/02_array.sh`)
2. Add tests to the corresponding test file (e.g., `toolkit_core.bats`)
3. Load the module in `setup()`: `load_toolkit core/02_array`
4. Write tests following the patterns in existing files

Example:

```bash
# In toolkit_core.bats

@test "radp_nr_new_function: basic functionality" {
  # Arrange
  local -a input=("a" "b")

  # Act
  local result
  result=$(radp_nr_new_function input)

  # Assert
  [[ "$result" == "expected" ]]
}
```

## Debugging Tests

```bash
# Print debug output (visible with --show-output-of-passing-tests)
echo "Debug: value=$value" >&3

# Or use bats built-in
bats --show-output-of-passing-tests src/test/shell/toolkit_core.bats
```
