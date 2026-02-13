# Testing Guide

This directory contains [bats-core](https://github.com/bats-core/bats-core) tests for radp-bash-framework.

## Prerequisites

- **bats-core** 1.13.0+ (`brew install bats-core` on macOS)

## Running Tests

```bash
# Run all tests (recursive)
bats --recursive src/test/shell/

# Run by domain
bats --recursive src/test/shell/framework/
bats --recursive src/test/shell/toolkit/
bats --recursive src/test/shell/toolkit/cli/

# Run a single file
bats src/test/shell/framework/logger.bats
bats src/test/shell/toolkit/core/array.bats

# Verbose output
bats --verbose-run src/test/shell/toolkit/core/array.bats

# Filter tests by name
bats --filter "radp_cli_version_lt" --recursive src/test/shell/

# Show output from passing tests (useful for debug prints)
bats --show-output-of-passing-tests src/test/shell/toolkit/exec/dry_run.bats
```

## Test Directory Structure

The test layout mirrors the source tree:

```
src/test/shell/
├── README.md
├── helpers/
│   └── test_helper.bash          # Shared test infrastructure
├── framework/
│   ├── logger.bats               # logger/logger.sh
│   └── autoconfigure.bats        # vars/configurable/autoconfigure.sh
└── toolkit/
    ├── core/
    │   ├── array.bats            # core/02_array.sh
    │   └── version.bats          # core/05_version.sh
    ├── exec/
    │   ├── dry_run.bats          # exec/04_dry_run.sh
    │   └── retry.bats            # exec/02_retry.sh
    ├── io/
    │   ├── fs.bats               # io/01_fs.sh
    │   └── yaml.bats             # io/05_yaml.sh
    ├── os/
    │   └── distro.bats           # os/01_distro.sh
    └── cli/
        ├── discover.bats         # cli/01_meta + 02_discover + 07_app
        ├── meta.bats             # cli/01_meta.sh
        └── upgrade_cli.bats      # cli/12_upgrade_cli.sh
```

### Source Module Mapping

| Test File | Source Module |
|-----------|-------------|
| `framework/logger.bats` | `bootstrap/context/libs/logger/logger.sh` |
| `framework/autoconfigure.bats` | `bootstrap/context/vars/configurable/autoconfigure.sh` |
| `toolkit/core/array.bats` | `toolkit/core/02_array.sh` |
| `toolkit/core/version.bats` | `toolkit/core/05_version.sh` |
| `toolkit/exec/dry_run.bats` | `toolkit/exec/04_dry_run.sh` |
| `toolkit/exec/retry.bats` | `toolkit/exec/02_retry.sh` |
| `toolkit/io/fs.bats` | `toolkit/io/01_fs.sh` |
| `toolkit/io/yaml.bats` | `toolkit/io/05_yaml.sh` |
| `toolkit/os/distro.bats` | `toolkit/os/01_distro.sh` |
| `toolkit/cli/discover.bats` | `toolkit/cli/01_meta + 02_discover + 07_app` |
| `toolkit/cli/meta.bats` | `toolkit/cli/01_meta.sh` |
| `toolkit/cli/upgrade_cli.bats` | `toolkit/cli/12_upgrade_cli.sh` |

## Module Loading Patterns

There are three patterns for loading source code in tests, depending on the module type.

### Pattern 1: `load_toolkit` — Simple toolkit modules

For modules under `toolkit/` that define functions without side effects:

```bash
setup() {
  load ../../helpers/test_helper   # relative to test file
  setup_test_env
  load_toolkit core/02_array
}
```

Multiple modules can be loaded at once: `load_toolkit cli/01_meta cli/02_discover`

### Pattern 2: `load_source_with_main_noop` — Files with `__main()`

For files like `logger.sh` that have a `__main()` entry point invoked at file end. This strips the bare `__main` call so all function definitions load but `__main()`'s side effects are skipped:

```bash
setup() {
  load ../helpers/test_helper
  setup_test_env
  # Set globals the module expects
  export gr_radp_fw_log_file_name="$TEST_TEMP_DIR/test.log"
  export gr_radp_fw_log_level="info"
  # ...
  load_source_with_main_noop "$TEST_LOGGER_FILE"
}
```

### Pattern 3: sed extraction — Files with heavy file-scope code

For files like `autoconfigure.sh` that execute significant code at source-time (readonly declarations, `__fw_normalize_path` calls). Extract individual functions via sed:

```bash
source_autoconfigure_functions() {
  local f="$TEST_AUTOCONFIGURE_FILE"
  eval "$(sed -n '/^__fw_yaml_to_env_vars()/,/^}/p' "$f")"
  eval "$(sed -n '/^__fw_merge_env_vars()/,/^}/p' "$f")"
  # ...
}
```

### Cross-module dependency stubs

When a module calls functions from other modules (e.g., `radp_log_info`, `radp_ide_add_commands_dir`), use stubs:

```bash
setup() {
  load ../../helpers/test_helper
  setup_test_env
  stub_logger        # no-op radp_log_{debug,info,warn,error}
  stub_ide           # no-op radp_ide_add_commands_dir, radp_ide_init
  load_toolkit cli/02_discover
}
```

## Available Assertion Helpers

| Function | Description |
|----------|-------------|
| `assert_function_exists "func"` | Assert a function is defined |
| `assert_array_equals arr "a" "b"` | Assert array equals expected values |
| `assert_output_contains "text"` | Assert `$output` contains substring (use after `run`) |
| `assert_status N` | Assert `$status` equals N (use after `run`) |

## Available Test Utilities

| Function | Description |
|----------|-------------|
| `setup_test_env` | Creates `$TEST_TEMP_DIR` |
| `teardown_test_env` | Removes `$TEST_TEMP_DIR` |
| `create_temp_file "name" "content"` | Create a temp file, returns path |
| `create_temp_dir "name"` | Create a temp directory, returns path |
| `stub_logger` | No-op logger stubs |
| `stub_ide` | No-op IDE stubs |
| `load_toolkit <module>...` | Load toolkit modules by path |
| `load_internal <module>...` | Load internal framework modules |
| `load_source_with_main_noop <file>` | Source file, skip `__main` invocation |

## Naming Conventions

Tests follow the pattern `"function_name: brief description"`:

```bash
@test "radp_io_get_path_abs: converts relative to absolute" {
  ...
}

@test "radp_cli_discover: discovers subcommands in directories" {
  ...
}
```

Use the Arrange-Act-Assert (AAA) pattern within tests:

```bash
@test "radp_nr_arr_merge_unique: merges two arrays" {
  # Arrange
  local -a src1=("a" "b")
  local -a src2=("b" "c")
  local -a result=()

  # Act
  radp_nr_arr_merge_unique result src1 src2

  # Assert
  assert_array_equals result "a" "b" "c"
}
```

## Debugging Tests

```bash
# Print debug info to fd3 (visible with --show-output-of-passing-tests)
echo "Debug: value=$value" >&3

# Run with debug output
bats --show-output-of-passing-tests src/test/shell/toolkit/core/array.bats

# Filter to run a single test
bats --filter "specific test name" --recursive src/test/shell/
```

## Platform Notes

- Tests run on macOS (BSD) and Linux
- Linux-only modules (`os/02_security` through `os/10_user`) are not tested — they require systemd/SELinux/sudo
- Network-dependent modules (`net/*`) are not tested
- Some tests use `skip` for platform-specific behavior (e.g., package manager detection)

## Common Pitfalls

### `run` vs direct invocation

Use `run` when you need to capture exit status and output. Use direct invocation when you need to modify the calling shell's state (e.g., set variables via nameref):

```bash
# Use run - captures status/output in subshell
run radp_cli_version_lt "1.0" "2.0"
[[ "$status" -eq 0 ]]

# Direct invocation - modifies caller's variables
local -A meta=()
radp_cli_parse_meta "$file" meta
[[ "${meta[desc]}" == "expected" ]]
```

### `set -e` interaction

`load_source_with_main_noop` temporarily disables `set -e` during sourcing because module-level code may reference undefined globals. Shell options are restored afterward.

### `load` paths are relative

Bats `load` resolves relative to the test file's directory:
- `framework/*.bats` → `load ../helpers/test_helper`
- `toolkit/<domain>/*.bats` → `load ../../helpers/test_helper`
