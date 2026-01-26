# Command Annotations Reference

Commands are defined using comment-based annotations in `.sh` files under the `commands/` directory.

## Basic Annotations

### `@cmd`

Marks a file as containing a command. Required for command discovery.

```bash
# @cmd
cmd_hello() {
  echo "Hello!"
}
```

### `@desc`

Command description shown in help output.

```bash
# @cmd
# @desc Greet the user with a friendly message
```

## Arguments

### `@arg <name>`

Define a positional argument.

```bash
# @arg name           Optional argument
# @arg name!          Required argument (!)
# @arg items~         Variadic argument (multiple values)
```

Example:

```bash
# @cmd
# @desc Copy files to destination
# @arg src!           Source file (required)
# @arg dest!          Destination path (required)
# @arg extras~        Additional files to copy

cmd_copy() {
  local src="$1"
  local dest="$2"
  shift 2
  local -a extras=("$@")

  cp "$src" "$dest"
  for f in "${extras[@]}"; do
    cp "$f" "$dest"
  done
}
```

## Options

### `@option`

Define command-line options.

```bash
# Boolean flags (no value)
# @option -v, --verbose       Enable verbose output
# @option -q, --quiet         Suppress output

# Options with values
# @option -c, --config <file>   Configuration file
# @option -n, --count <num>     Number of iterations
# @option -e, --env <name>      Environment name
```

Options are available as `opt_<name>` variables:

```bash
# @cmd
# @desc Run with options
# @option -v, --verbose     Enable verbose mode
# @option -c, --config <file>  Config file path

cmd_run() {
  if [[ "${opt_verbose:-}" == "true" ]]; then
    echo "Verbose mode enabled"
  fi

  if [[ -n "${opt_config:-}" ]]; then
    echo "Using config: $opt_config"
  fi
}
```

## Dynamic Completion

### `@complete`

Define dynamic shell completion for arguments or options. The completion function is called at runtime to provide
completion values.

```bash
# @complete <name> <function>
```

- `name`: Argument name or option long name (without `--`)
- `function`: Shell function that outputs completion values (one per line)

Example:

```bash
# @cmd
# @desc Install a package
# @arg name! Package name
# @complete name _my_complete_packages
# @option -c, --category <name> Filter by category
# @complete category _my_complete_categories

cmd_install() {
  local name="$1"
  local category="${opt_category:-}"
  # ...
}

# Completion function for packages
_my_complete_packages() {
  echo "fzf"
  echo "bat"
  echo "jq"
}

# Completion function for categories
_my_complete_categories() {
  echo "cli-tools"
  echo "languages"
  echo "editors"
}
```

When the user presses TAB:

- `myapp install <TAB>` → shows: `fzf bat jq`
- `myapp install -c <TAB>` → shows: `cli-tools languages editors`

**Note:** The completion function must be available when the shell completion script runs. For built-in commands, define
completion functions in your project's libs. For user-facing features, ensure the functions are sourced in the entry
script.

## Examples

### `@example`

Show usage examples in help output.

```bash
# @cmd
# @desc Deploy application
# @arg env!           Target environment
# @option -f, --force   Force deployment
# @example deploy staging
# @example deploy production --force

cmd_deploy() {
  ...
}
```

## Complete Example

```bash
#!/usr/bin/env bash
# src/main/shell/commands/db/migrate.sh

# @cmd
# @desc Run database migrations
# @arg version        Target version (optional, defaults to latest)
# @option -n, --dry-run       Show what would be done without executing
# @option -v, --verbose       Show detailed output
# @option --env <name>        Target environment (default: development)
# @example db migrate
# @example db migrate 20240101
# @example db migrate --dry-run --verbose

cmd_db_migrate() {
  local version="${1:-latest}"
  local dry_run="${opt_dry_run:-false}"
  local verbose="${opt_verbose:-false}"
  local env="${opt_env:-development}"

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] Would migrate to version: $version"
    return 0
  fi

  if [[ "$verbose" == "true" ]]; then
    echo "Environment: $env"
    echo "Target version: $version"
  fi

  echo "Running migrations..."
}
```

## Subcommands

Create directories for command groups:

```
commands/
├── hello.sh              # myapp hello
├── db/
│   ├── migrate.sh        # myapp db migrate
│   ├── seed.sh           # myapp db seed
│   └── reset.sh          # myapp db reset
└── config/
    ├── get.sh            # myapp config get
    └── set.sh            # myapp config set
```

Function naming follows the path: `commands/db/migrate.sh` → `cmd_db_migrate()`

## Project Structure

When you create a new project with `radp-bf new myapp`, it generates:

```
myapp/
├── bin/myapp                      # CLI entry point
├── src/main/shell/
│   ├── commands/                  # Command implementations
│   │   ├── hello.sh
│   │   ├── version.sh
│   │   └── completion.sh
│   ├── config/                    # YAML configuration
│   │   ├── config.yaml            # Base configuration
│   │   └── config-dev.yaml        # Environment overrides
│   ├── libs/                      # Project-specific libraries
│   └── vars/
│       └── constants.sh           # Version constants
├── packaging/                     # Distribution packaging
└── install.sh                     # Installer script
```

The `config/` directory contains YAML configuration files that are automatically parsed by the framework.
See [Configuration](configuration.md) for details on the YAML configuration system.
