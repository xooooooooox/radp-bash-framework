# API Reference

The framework provides utility functions organized by domain under `src/main/shell/framework/bootstrap/context/libs/`.

## Overview

### Function Naming Conventions

| Pattern               | Meaning                                          | Example                    |
|-----------------------|--------------------------------------------------|----------------------------|
| `radp_<domain>_*`     | Public function                                  | `radp_os_get_distro_id`    |
| `radp_nr_*`           | Nameref function (pass variable name, not value) | `radp_nr_arr_merge_unique` |
| `radp_cli_*`          | CLI infrastructure                               | `radp_cli_dispatch`        |
| `radp_app_*`          | Application-level functions                      | `radp_app_run`             |
| `radp_ide_*`          | IDE integration                                  | `radp_ide_init`            |
| `*_is_*` / `*_has_*`  | Boolean check (0=true, 1=false)                  | `radp_os_is_pkg_installed` |
| `__fw_*` / `__radp_*` | Private/internal (do not use)                    | —                          |

### Variable Naming Conventions

| Pattern            | Meaning                      | Example                        |
|--------------------|------------------------------|--------------------------------|
| `gr_*`             | Global readonly paths/config | `gr_fw_root_path`              |
| `gw_*`             | Global writable state/flags  | `gw_fw_run_initialized`        |
| `gwxa_*`           | Global arrays                | `gwxa_fw_sourced_scripts`      |
| `gr_radp_fw_*`     | Framework config values      | `gr_radp_fw_log_level`         |
| `gr_radp_extend_*` | User extension config        | `gr_radp_extend_myapp_api_url` |

---

## Logging (`radp_log_*`)

**Location:** `libs/logger/logger.sh`

### Functions

| Function                                     | Description                                              |
|----------------------------------------------|----------------------------------------------------------|
| `radp_log_debug(msg [script] [func] [line])` | Log DEBUG message (requires `GX_RADP_FW_LOG_DEBUG=true`) |
| `radp_log_info(msg [script] [func] [line])`  | Log INFO message                                         |
| `radp_log_warn(msg [script] [func] [line])`  | Log WARN message                                         |
| `radp_log_error(msg [script] [func] [line])` | Log ERROR message                                        |
| `radp_log_raw(msg)`                          | Output raw content without formatting or level filtering |

### Parameters

All logging functions accept:

- `msg` — Log message (required)
- `script` — Script name (optional, auto-detected from `BASH_SOURCE`)
- `func` — Function name (optional, auto-detected from `FUNCNAME`)
- `line` — Line number (optional, auto-detected from `BASH_LINENO`)

### Configuration

| Variable                | Description          | Default         |
|-------------------------|----------------------|-----------------|
| `GX_RADP_FW_LOG_DEBUG`  | Enable debug logging | `false`         |
| `gr_radp_fw_log_level`  | Minimum log level    | `INFO`          |
| `gr_radp_fw_log_format` | Log format string    | `[%level] %msg` |

### Example

```bash
radp_log_debug "Connecting to database" # Only shown if GX_RADP_FW_LOG_DEBUG=true
radp_log_info "Server started on port 8080"
radp_log_warn "Config file not found, using defaults"
radp_log_error "Failed to connect to API"
radp_log_raw "Plain output without formatting"
```

---

## OS Detection (`radp_os_*`)

**Location:** `libs/toolkit/os/`

### Distro Information

| Function                       | Returns             | Example Output               |
|--------------------------------|---------------------|------------------------------|
| `radp_os_get_distro_os()`      | OS kernel name      | `Linux`, `Darwin`            |
| `radp_os_get_distro_arch()`    | System architecture | `x86_64`, `aarch64`, `arm64` |
| `radp_os_get_distro_id()`      | Distribution ID     | `ubuntu`, `fedora`, `osx`    |
| `radp_os_get_distro_name()`    | Distribution name   | `Ubuntu`, `Fedora`, `macOS`  |
| `radp_os_get_distro_version()` | Version string      | `22.04`, `39`, `14.0`        |
| `radp_os_get_distro_pm()`      | Package manager     | `apt-get`, `dnf`, `brew`     |

### Package Management

#### radp_os_is_pkg_installed

Check if a package is installed.

```bash
radp_os_is_pkg_installed (pm pkg)
```

**Parameters:**

- `pm` — Package manager (`yum`, `dnf`, `apt`, `apt-get`, `brew`)
- `pkg` — Package name

**Returns:** `0` if installed, `1` if not installed or unsupported PM

**Example:**

```bash
if radp_os_is_pkg_installed "$(radp_os_get_distro_pm)" git; then
  echo "git is installed"
fi
```

#### radp_os_install_pkgs

Install packages with cross-platform support.

```bash
radp_os_install_pkgs ([packages...] [options])
```

**Options:**

- `--update` — Update package cache before installing
- `--dry-run` — Print commands without executing
- `--check-only` — Only check for missing packages
- `--map <str>` — Package mapping (`"apt:pkg1,pkg2;dnf:pkg3"`)
- `--pm <pm> <pkg...> --` — Override packages for specific PM

**Returns:** `0` on success, `1` on error, `2` if missing packages (with `--check-only`)

**Examples:**

```bash
# Basic installation
radp_os_install_pkgs curl wget jq

# With package manager mapping
radp_os_install_pkgs curl --map "brew:curl;apt:curl,ca-certificates"

# Check only (no installation)
if ! radp_os_install_pkgs curl wget --check-only; then
  echo "Missing packages"
fi

# Dry run
radp_os_install_pkgs nginx --update --dry-run
```

---

## File System (`radp_io_*`)

**Location:** `libs/toolkit/io/`

### Path Functions

#### radp_io_get_path_abs

Resolve path to absolute with symlink expansion.

```bash
radp_io_get_path_abs ([target])
```

**Parameters:**

- `target` — File or directory path (defaults to caller's script path)

**Returns:** `0` on success

**Outputs:** Absolute resolved path

**Example:**

```bash
abs_path=$(radp_io_get_path_abs "./relative/path")
script_dir=$(radp_io_get_path_abs) # Current script's directory
```

### File Transfer

#### radp_io_download

Download file from URL with curl/wget fallback.

```bash
radp_io_download (url dest [--silent | --progress])
```

**Parameters:**

- `url` — URL to download from
- `dest` — Destination file path
- `--silent` — Suppress progress output (default)
- `--progress` — Show progress output

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
radp_io_download "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
radp_io_download "https://example.com/large.zip" "./large.zip" --progress
```

#### radp_io_extract

Extract archive to destination directory.

```bash
radp_io_extract (archive dest)
```

**Parameters:**

- `archive` — Archive file path
- `dest` — Destination directory (created if not exists)

**Supported formats:** `tar.gz`, `tgz`, `tar.xz`, `tar.bz2`, `zip`

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
radp_io_download "https://example.com/app.tar.gz" "/tmp/app.tar.gz"
radp_io_extract "/tmp/app.tar.gz" "/opt/app"
```

#### radp_io_mktemp_dir

Create temporary directory with auto-cleanup.

```bash
radp_io_mktemp_dir ([prefix])
```

**Parameters:**

- `prefix` — Directory name prefix (default: `radp`)

**Returns:** `0` on success, `1` on failure

**Outputs:** Path to created temporary directory

**Example:**

```bash
tmp_dir=$(radp_io_mktemp_dir "myapp")
# Use $tmp_dir...
# Directory is automatically cleaned up on script exit
```

---

## Network (`radp_net_*`)

**Location:** `libs/toolkit/net/`

### GitHub API

#### radp_net_github_latest_release

Get latest release version from GitHub repository.

```bash
radp_net_github_latest_release (repo [--with-v])
```

**Parameters:**

- `repo` — GitHub repository (`owner/repo` format)
- `--with-v` — Include leading `v` if present in tag

**Returns:** `0` on success, `1` on failure

**Outputs:** Version string (e.g., `1.2.3` or `v1.2.3` with `--with-v`)

**Example:**

```bash
version=$(radp_net_github_latest_release "junegunn/fzf")
echo "Latest fzf: $version" # e.g., "0.45.0"

version=$(radp_net_github_latest_release "cli/cli" --with-v)
echo "Latest gh: $version" # e.g., "v2.40.0"
```

#### radp_net_github_download_asset

Download asset from GitHub release.

```bash
radp_net_github_download_asset (repo asset_pattern dest [--version ver])
```

**Parameters:**

- `repo` — GitHub repository (`owner/repo` format)
- `asset_pattern` — Glob pattern to match asset name
- `dest` — Destination file path
- `--version <ver>` — Specific version (default: latest)

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
# Download latest fzf binary for current platform
radp_net_github_download_asset "junegunn/fzf" \
  "fzf-*-linux_amd64.tar.gz" \
  "/tmp/fzf.tar.gz"

# Download specific version
radp_net_github_download_asset "sharkdp/bat" \
  "bat-*-x86_64-unknown-linux-gnu.tar.gz" \
  "/tmp/bat.tar.gz" \
  --version "v0.24.0"
```

---

## Arrays (`radp_nr_*`)

**Location:** `libs/toolkit/core/`

### radp_nr_arr_merge_unique

Merge multiple arrays with deduplication.

```bash
radp_nr_arr_merge_unique (dest_name src_name [src_name...])
```

**Parameters:** (all are variable names without `$`)

- `dest_name` — Destination array variable name
- `src_name` — Source array variable names to merge

**Returns:** `0`

**Example:**

```bash
local -a src1=("a" "b" "c")
local -a src2=("b" "c" "d")
local -a src3=("d" "e")
local -a result=()

radp_nr_arr_merge_unique result src1 src2 src3
# result = ("a" "b" "c" "d" "e")
```

---

## CLI Infrastructure (`radp_cli_*`)

**Location:** `libs/toolkit/cli/`

### Application Bootstrap

#### radp_app_config

Configure application name, version, and description.

```bash
radp_app_config (name [version] [desc])
```

**Parameters:**

- `name` — Application name
- `version` — Application version (optional)
- `desc` — Application description (optional)

**Example:**

```bash
radp_app_config "myapp" "1.0.0" "My awesome CLI tool"
```

#### radp_app_bootstrap

Simplified bootstrap with auto-detection.

```bash
radp_app_bootstrap (app_root app_name [arguments...])
```

**Parameters:**

- `app_root` — Application root directory
- `app_name` — Application name
- `arguments` — Command-line arguments to pass

**Example:**

```bash
# In bin/myapp
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(radp-bf path init)"
radp_app_bootstrap "$SCRIPT_DIR/.." "myapp" "$@"
```

#### radp_app_run

Main application entry point.

```bash
radp_app_run ([arguments...])
```

**Parameters:**

- `arguments` — Command-line arguments

**Prerequisites:** Commands directory must be set via `radp_cli_set_commands_dir()`

**Example:**

```bash
radp_cli_set_commands_dir "/path/to/commands"
radp_app_config "myapp" "1.0.0"
radp_app_run "$@"
```

#### radp_app_version

Output application version.

```bash
radp_app_version()
```

**Outputs:** Application name and version

**Note:** Can be overridden by defining custom `radp_app_version()` before sourcing framework.

### Request Detection

#### radp_app_is_help_request

Check if help flag was passed.

```bash
radp_app_is_help_request ([arguments...])
```

**Returns:** `0` if `-h` or `--help` present, `1` otherwise

#### radp_app_is_version_request

Check if version flag was passed.

```bash
radp_app_is_version_request ([arguments...])
```

**Returns:** `0` if `-v` or `--version` present, `1` otherwise

**Example:**

```bash
if radp_app_is_help_request "$@"; then
  radp_cli_help
  exit 0
fi

if radp_app_is_version_request "$@"; then
  radp_app_version
  exit 0
fi
```

### Command Discovery

#### radp_cli_set_commands_dir

Set commands directory path.

```bash
radp_cli_set_commands_dir (commands_dir)
```

**Parameters:**

- `commands_dir` — Absolute path to `commands/` directory

**Returns:** `0` on success, `1` if directory not found

#### radp_cli_set_app_name

Set application name for help/completion.

```bash
radp_cli_set_app_name (app_name)
```

#### radp_cli_set_global_options

Set global options displayed in help.

```bash
radp_cli_set_global_options ([options...])
```

**Parameters:**

- `options` — Global option flags (e.g., `"-v"`, `"--verbose"`, `"--debug"`)

**Example:**

```bash
radp_cli_set_global_options "-v" "--verbose" "--debug"
```

#### radp_cli_discover

Discover all commands from commands directory.

```bash
radp_cli_discover()
```

**Returns:** `0` on success, `1` if commands directory not set

#### radp_cli_cmd_exists

Check if command exists.

```bash
radp_cli_cmd_exists (cmd_path)
```

**Parameters:**

- `cmd_path` — Command path (e.g., `"db migrate"`)

**Returns:** `0` if exists, `1` if not

#### radp_cli_has_subcommands

Check if command has subcommands.

```bash
radp_cli_has_subcommands (cmd)
```

**Returns:** `0` if has subcommands, `1` if not

#### radp_cli_list_commands

List all top-level commands.

```bash
radp_cli_list_commands()
```

**Outputs:** One command per line (sorted)

#### radp_cli_list_subcommands

List subcommands for parent command.

```bash
radp_cli_list_subcommands (parent_cmd)
```

**Outputs:** One subcommand per line (sorted)

#### radp_cli_get_cmd_file

Get command file path.

```bash
radp_cli_get_cmd_file (cmd_path)
```

**Returns:** `0` if found, `1` if not

**Outputs:** Absolute path to command file

#### radp_cli_get_cmd_meta

Get command metadata.

```bash
radp_cli_get_cmd_meta (cmd_path var_name)
```

**Parameters:**

- `cmd_path` — Command path
- `var_name` — Associative array variable name (nameref)

**Returns:** `0` on success, `1` if not found

### Metadata Parsing

#### radp_cli_parse_meta

Parse command metadata from file.

```bash
radp_cli_parse_meta (file_path var_name)
```

**Parameters:**

- `file_path` — Command file path
- `var_name` — Associative array variable name (nameref)

**Returns:** `0` on success, `1` if file not found or not a command

**Parsed keys:** `desc`, `args`, `options`, `examples`, `completes`, `passthrough`

#### radp_cli_parse_arg_spec

Parse `@arg` declaration.

```bash
radp_cli_parse_arg_spec (arg_spec var_name)
```

**Parameters:**

- `arg_spec` — Argument specification string
- `var_name` — Associative array for result (nameref)

**Parsed keys:** `name`, `required`, `variadic`, `desc`

#### radp_cli_parse_option_spec

Parse `@option` declaration.

```bash
radp_cli_parse_option_spec (opt_spec var_name)
```

**Parameters:**

- `opt_spec` — Option specification string
- `var_name` — Associative array for result (nameref)

**Parsed keys:** `short`, `long`, `has_value`, `value_name`, `default`, `desc`

### Argument Parsing

#### radp_cli_build_getopt_spec

Build getopt option strings from metadata.

```bash
radp_cli_build_getopt_spec (options_spec)
```

**Parameters:**

- `options_spec` — `@option` declarations (newline-separated)

**Sets globals:** `__radp_cli_getopt_short`, `__radp_cli_getopt_long`

#### radp_cli_parse_args

Parse command-line arguments.

```bash
radp_cli_parse_args (options_spec args_spec [arguments...])
```

**Parameters:**

- `options_spec` — `@option` declarations
- `args_spec` — `@arg` declarations
- `arguments` — Arguments to parse

**Sets globals:**

- `opt_<name>` — Option values (e.g., `opt_verbose`, `opt_config`)
- `__radp_cli_positional_args` — Positional arguments array
- `__radp_cli_show_help` — `true` if `--help` was passed

**Returns:** `0` on success, `1` on error

#### radp_cli_get_arg

Get positional argument by index.

```bash
radp_cli_get_arg (index [default])
```

**Parameters:**

- `index` — Argument index (0-based)
- `default` — Default value if not found (optional)

**Outputs:** Argument value or default

#### radp_cli_get_all_args

Get all positional arguments.

```bash
radp_cli_get_all_args()
```

**Outputs:** All arguments space-separated

#### radp_cli_get_remaining_args

Get arguments from index onwards.

```bash
radp_cli_get_remaining_args (start_index)
```

**Parameters:**

- `start_index` — Starting index

**Outputs:** Arguments one per line

### Help Generation

#### radp_cli_help

Auto-generate contextual help.

```bash
radp_cli_help ([cmd_path...])
```

**Parameters:**

- `cmd_path` — Command path for specific help (optional)

**Behavior:**

- No args: Show app-level help
- Command group: Show group help with subcommands
- Specific command: Show command help with args/options

#### radp_cli_help_app

Generate application-level help.

```bash
radp_cli_help_app()
```

#### radp_cli_help_command_group

Generate command group help.

```bash
radp_cli_help_command_group (cmd)
```

#### radp_cli_help_command

Generate specific command help.

```bash
radp_cli_help_command (cmd_path)
```

### Command Dispatch

#### radp_cli_dispatch

Route arguments to command handler.

```bash
radp_cli_dispatch ([arguments...])
```

**Parameters:**

- `arguments` — Command-line arguments

**Returns:** Command's return code

**Behavior:**

1. Parses command path from arguments
2. Sources command file
3. Parses options and arguments
4. Calls `cmd_<path>()` function

#### radp_cli_current_cmd

Get current executing command path.

```bash
radp_cli_current_cmd()
```

**Outputs:** Current command path (e.g., `"db migrate"`)

### Shell Completion

#### radp_cli_completion_generate

Generate shell completion script.

```bash
radp_cli_completion_generate (shell)
```

**Parameters:**

- `shell` — Shell type (`bash` or `zsh`)

**Returns:** `0` on success, `1` on invalid shell

**Outputs:** Complete shell completion script

**Example:**

```bash
# Generate and install bash completion
radp_cli_completion_generate bash >~/.local/share/bash-completion/completions/myapp

# Generate zsh completion
radp_cli_completion_generate zsh >~/.zfunc/_myapp
```

#### radp_cli_completion_bash

Generate bash completion script.

```bash
radp_cli_completion_bash()
```

#### radp_cli_completion_zsh

Generate zsh completion script.

```bash
radp_cli_completion_zsh()
```

#### radp_cli_parse_complete_spec

Parse `@complete` declaration.

```bash
radp_cli_parse_complete_spec (complete_spec var_name)
```

**Parameters:**

- `complete_spec` — Completion specification string (e.g., `"name _complete_func"`)
- `var_name` — Associative array for result (nameref)

**Parsed keys:** `name`, `func`

#### radp_cli_get_complete_func

Get completion function for a parameter or option.

```bash
radp_cli_get_complete_func (name completes)
```

**Parameters:**

- `name` — Parameter name or option long name
- `completes` — Completion specifications (newline-separated)

**Returns:** `0` if found, `1` if not found

**Outputs:** Completion function name

### Dynamic Completion

The `@complete` annotation enables dynamic shell completion for arguments and options.

#### Syntax

```bash
# @complete <name> <function>
```

- `name` — Argument name or option long name (without `--`)
- `function` — Shell function that outputs completion values (one per line)

#### Argument Completion

```bash
# @cmd
# @arg name! Package name
# @complete name _complete_packages

cmd_install() {
  local name="$1"
  # ...
}

_complete_packages() {
  echo "fzf"
  echo "bat"
  echo "jq"
}
```

#### Option Completion

```bash
# @cmd
# @option -e, --env <name>  Target environment
# @complete env _complete_envs

cmd_deploy() {
  local env="${opt_env:-production}"
  # ...
}

_complete_envs() {
  echo "development"
  echo "staging"
  echo "production"
}
```

#### Dynamic Data Sources

```bash
# Git branches
_complete_branches() {
  git branch --format='%(refname:short)' 2>/dev/null
}

# SSH hosts from config
_complete_hosts() {
  grep -E "^Host " ~/.ssh/config 2>/dev/null | awk '{print $2}' | grep -v '*'
}

# API data
_complete_users() {
  curl -s https://api.example.com/users | jq -r '.[].name' 2>/dev/null
}
```

#### Multiple Completions

```bash
# @cmd
# @arg src! Source file
# @arg dest! Destination
# @option -H, --host <name>  Target host
# @complete src _complete_files
# @complete dest _complete_paths
# @complete host _complete_hosts
```

#### Function Placement

Completion functions can be defined in:

1. **Command file** — Self-contained, simple commands
2. **User libraries** (`libs/`) — Reusable across commands, automatically loaded

See [CLI Development Guide - Dynamic Completion](cli-development.md#dynamic-completion) for detailed examples.

### Passthrough Mode

For commands wrapping external tools, use `@meta passthrough` to bypass argument parsing:

```bash
# @cmd
# @desc Run docker commands
# @meta passthrough

cmd_docker() {
  exec docker "$@" # All arguments passed through
}
```

**Behavior:**

- No getopt parsing (avoids conflicts with external tool options)
- `--help` still shows framework-generated help
- Use environment variables for wrapper-specific configuration

See [Command Annotations](annotations.md#meta-annotations) for details.

### Scaffolding

#### radp_cli_scaffold_new

Create new CLI project.

```bash
radp_cli_scaffold_new (project_name [target_dir])
```

**Parameters:**

- `project_name` — Project name (alphanumeric, underscore, hyphen; must start with letter)
- `target_dir` — Target directory (defaults to `project_name`)

**Returns:** `0` on success, `1` on failure

**Creates:**

- `bin/<name>` — Entry script
- `src/main/shell/commands/` — Command directory with examples
- `src/main/shell/config/` — Configuration files
- `src/main/shell/libs/` — User libraries directory
- `src/main/shell/vars/` — Constants file
- `packaging/` — Distribution packaging
- `.github/workflows/` — CI/CD workflows

**Example:**

```bash
radp_cli_scaffold_new "myapp" # Creates ./myapp/
radp_cli_scaffold_new "myapp" "/opt" # Creates /opt/myapp/
```

---

## IDE Integration (`radp_ide_*`)

**Location:** `libs/toolkit/ide/`

The framework provides IDE code completion support for [BashSupport Pro](https://www.bashsupport.com/pro/) (JetBrains
IDEs).

### Features

- Autocompletion for framework functions (`radp_*`)
- Autocompletion for framework variables (`gr_fw_*`, `gr_radp_fw_*`)
- Autocompletion for user-defined config variables (`gr_radp_extend_*`)
- Autocompletion for user library functions
- Autocompletion for command functions

### How It Works

The framework generates a `completion.sh` file containing `# shellcheck source=...` directives. BashSupport Pro uses
ShellCheck's source directives to resolve symbols and provide code completion.

**Generated file locations:**

- `$gr_fw_user_config_path/completion.sh` — User config directory
- `$gr_fw_context_cache_path/completion.sh` — Framework cache (for development)

### Setup

1. **Install BashSupport Pro** in your JetBrains IDE
2. **Run your CLI once** to generate the hints file:
   ```bash
   myapp --help
   ```
3. **Open your project** in the IDE — completion should work automatically

### API Functions

#### radp_ide_init

Initialize IDE hints file.

```bash
radp_ide_init()
```

Called automatically during bootstrap.

#### radp_ide_add_commands_dir

Add commands directory to IDE hints.

```bash
radp_ide_add_commands_dir (commands_dir)
```

Called automatically by `radp_cli_set_commands_dir()`.

### Troubleshooting

| Issue             | Solution                                                 |
|-------------------|----------------------------------------------------------|
| No completion     | Ensure `completion.sh` exists in user config path        |
| Stale completion  | Delete `completion.sh` and run CLI again                 |
| Read-only install | IDE hints are skipped for system installs (`/usr/lib64`) |

> **Note:** The `completion.sh` file uses absolute paths and should be added to `.gitignore`.
