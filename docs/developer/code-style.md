# Code Style Guide

This document describes the coding conventions and style guidelines for radp-bash-framework.

## Shell Compatibility

| Component | Shell | Features |
|-----------|-------|----------|
| `init.sh`, `preflight/stage1/` | POSIX | `test`, `[ ]`, no `local` arrays |
| `preflight/stage2/`, `bootstrap/` | Bash 4.3+ | `[[ ]]`, arrays, `local`, `mapfile` |

## Naming Conventions

### Variables

| Prefix | Scope | Mutability | Example |
|--------|-------|------------|---------|
| `gr_*` | Global | Readonly | `gr_fw_root_path` |
| `gw_*` | Global | Writable | `gw_fw_run_initialized` |
| `gwxa_*` | Global | Writable array | `gwxa_fw_sourced_scripts` |
| `__fw_*` | Internal | Private | `__fw_config_cache` |

**Best practices:**

- Use `local` for function-scoped variables
- Quote variables unless intentional word splitting: `"$var"`
- Use `${var:-default}` for default values
- Use `${var:?error}` for required variables

### Functions

| Pattern | Meaning | Example |
|---------|---------|---------|
| `radp_*` | Public API | `radp_log_info` |
| `radp_nr_*` | Nameref (pass var name) | `radp_nr_arr_merge_unique` |
| `radp_<domain>_*` | Domain-specific | `radp_os_get_distro_id` |
| `*_is_*` / `*_has_*` | Boolean (returns 0/1) | `radp_os_is_pkg_installed` |
| `__fw_*` | Internal/private | `__fw_bootstrap` |

### Commands

| Pattern | Example |
|---------|---------|
| File location | `commands/db/migrate.sh` |
| Function name | `cmd_db_migrate()` |
| Invocation | `myapp db migrate` |

## Code Formatting

### Indentation

- Use 2 spaces for indentation
- No tabs

### Line Length

- Aim for 100 characters max
- Break long pipelines at `|`
- Break long strings with `\`

### Quoting

```bash
# Always quote variables
echo "$variable"
cp "$source" "$dest"

# Use single quotes for literal strings
grep -E '^Host '

# Use $'...' for escape sequences
echo $'line1\nline2'
```

### Conditionals

```bash
# Prefer [[ ]] over [ ] in Bash code
if [[ -n "$var" ]]; then
  # ...
fi

# Use [[ ]] for pattern matching
if [[ "$str" == *"pattern"* ]]; then
  # ...
fi

# Boolean functions return 0/1
radp_os_is_pkg_installed() {
  command -v "$1" &>/dev/null
}
```

### Functions

```bash
# Function declaration
my_function() {
  local arg1="$1"
  local arg2="${2:-default}"

  # Implementation
}

# Document complex functions
# Description of what the function does
# Args:
#   $1 - First argument description
#   $2 - Second argument description (optional)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Writes result to stdout
```

## Logging

Use framework logging functions instead of `echo`:

```bash
# Correct
radp_log_debug "Processing file: $file"
radp_log_info "Server started on port $port"
radp_log_warn "Config file not found, using defaults"
radp_log_error "Failed to connect to database"

# Incorrect
echo "Processing file: $file"
echo "ERROR: Failed to connect"
```

## Error Handling

```bash
# Check command success
if ! command -v yq &>/dev/null; then
  radp_log_error "yq not found"
  return 1
fi

# Use set -e with caution (prefer explicit checks)
# set -e can cause unexpected exits

# Handle cleanup with traps
cleanup() {
  rm -f "$temp_file"
}
trap cleanup EXIT
```

## ShellCheck

Preserve existing ShellCheck directives:

```bash
# shellcheck source=./lib.sh
source "./lib.sh"

# shellcheck disable=SC2034  # Variable used by sourced script
local __result="value"
```

Run ShellCheck before committing:

```bash
shellcheck src/main/shell/**/*.sh
```

## YAML Configuration Keys

| Style | Usage |
|-------|-------|
| `dash-case` | Framework config keys: `banner-mode`, `log-level` |
| `snake_case` | Plugin options (match Vagrant): `auto_update` |

## Testing

Tests use [BATS](https://github.com/bats-core/bats-core):

```bash
# Run all tests
bats src/test/shell/

# Run specific test file
bats src/test/shell/toolkit_core.bats
```

See [src/test/shell/README.md](../../src/test/shell/README.md) for writing tests.

## See Also

- [Architecture](./architecture.md) - Framework architecture
- [API Reference](../reference/api.md) - Complete function reference
