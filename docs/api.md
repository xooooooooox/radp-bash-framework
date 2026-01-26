# API Reference

The framework provides utility functions organized by domain under `src/main/shell/framework/bootstrap/context/libs/`.

## Logging (`radp_log_*`)

```bash
radp_log_debug "Debug message" # Requires GX_RADP_FW_LOG_DEBUG=true
radp_log_info "Info message"
radp_log_warn "Warning message"
radp_log_error "Error message"
radp_log_raw "Raw output" # No formatting
```

## OS Detection (`radp_os_*`)

| Function                     | Returns           | Example                   |
|------------------------------|-------------------|---------------------------|
| `radp_os_get_distro_os`      | OS type           | `Linux`, `Darwin`         |
| `radp_os_get_distro_arch`    | Architecture      | `x86_64`, `aarch64`       |
| `radp_os_get_distro_id`      | Distribution ID   | `ubuntu`, `fedora`, `osx` |
| `radp_os_get_distro_name`    | Distribution name | `Ubuntu`, `Fedora`        |
| `radp_os_get_distro_version` | Version string    | `22.04`, `39`             |
| `radp_os_get_distro_pm`      | Package manager   | `apt-get`, `dnf`, `brew`  |

```bash
# Check if package is installed (returns 0/1)
if radp_os_is_pkg_installed git; then
  echo "git is installed"
fi

# Install packages
radp_os_install_pkgs curl wget jq
```

## File System (`radp_io_*`)

```bash
# Convert relative path to absolute
abs_path=$(radp_io_get_path_abs "./relative/path")
```

## Arrays (`radp_nr_*`)

Nameref functions take variable names (without `$`) as first argument:

```bash
local -a src1=("a" "b")
local -a src2=("b" "c")
local -a dest=()

# Merge arrays with deduplication
radp_nr_arr_merge_unique dest src1 src2
# dest = ("a" "b" "c")
```

## CLI Infrastructure (`radp_cli_*`)

### Application Bootstrap

```bash
# In bin/myapp entry script
radp_app_bootstrap "$SCRIPT_DIR/.." "myapp"
```

### Command Discovery

```bash
radp_cli_set_app_name "myapp"
radp_cli_set_commands_dir "/path/to/commands"
radp_cli_discover

# Check if command exists
if radp_cli_cmd_exists "db migrate"; then
  echo "Command exists"
fi

# Check if command has subcommands
if radp_cli_has_subcommands "db"; then
  echo "db is a command group"
fi
```

### Help and Dispatch

```bash
radp_cli_help # Show help for current command
radp_cli_dispatch "$@" # Dispatch to command handler
```

### Shell Completion

```bash
radp_cli_completion_generate bash # Generate bash completion
radp_cli_completion_generate zsh # Generate zsh completion
```

### Scaffolding

```bash
radp_cli_scaffold_new "myapp" # Create new CLI project in current dir
radp_cli_scaffold_new "myapp" "/path/to/dir"
```

## IDE Integration (`radp_ide_*`)

Provides code completion hints for BashSupport Pro IDE plugin.

```bash
# Initialize IDE hints file (generates completion.sh)
# Called automatically during framework bootstrap
radp_ide_init

# Add commands directory to IDE hints
# Called automatically by radp_cli_set_commands_dir()
radp_ide_add_commands_dir "/path/to/commands"
```

The generated `completion.sh` file contains `# shellcheck source=...` directives that enable BashSupport Pro to provide
code completion for:

- Framework global variables (`gr_fw_*`, `gr_radp_fw_*`)
- Framework library functions (`radp_*`)
- User global variables (`gr_radp_extend_*`)
- User library functions
- User commands

> **Note:** The `completion.sh` file uses absolute paths and should be added to `.gitignore`.

## Request Detection (`radp_app_*`)

```bash
# Check for help/version flags
if radp_app_is_help_request "$1"; then
  radp_cli_help
  exit 0
fi

if radp_app_is_version_request "$1"; then
  radp_app_version
  exit 0
fi
```

## Naming Conventions

| Pattern               | Meaning                   | Example                    |
|-----------------------|---------------------------|----------------------------|
| `radp_<domain>_*`     | Public function           | `radp_os_get_distro_id`    |
| `radp_nr_*`           | Nameref function          | `radp_nr_arr_merge_unique` |
| `radp_ide_*`          | IDE integration           | `radp_ide_init`            |
| `*_is_*` / `*_has_*`  | Boolean (0=true, 1=false) | `radp_os_is_pkg_installed` |
| `__fw_*` / `__radp_*` | Private/internal          | Do not use directly        |
