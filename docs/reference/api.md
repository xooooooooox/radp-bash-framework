# API Reference

The framework provides utility functions organized by domain under `src/main/shell/framework/bootstrap/context/libs/`.

## Table of Contents

- [Overview](#overview)
  - [Function Naming Conventions](#function-naming-conventions)
  - [Variable Naming Conventions](#variable-naming-conventions)
  - [Return Code Conventions](#return-code-conventions)
- [Logging (`radp_log_*`)](#logging-radp_log_)
- [OS Detection (`radp_os_*`)](#os-detection-radp_os_)
- [System Security (`radp_os_*`)](#system-security-radp_os_)
- [System Resources (`radp_os_*`)](#system-resources-radp_os_)
- [Cron Management (`radp_os_crontab_*`)](#cron-management-radp_os_crontab_)
- [File System (`radp_io_*`)](#file-system-radp_io_)
- [YAML Parsing (`radp_io_yaml_*`)](#yaml-parsing-lightweight)
- [User Prompts (`radp_io_prompt_*`)](#user-prompts-radp_io_prompt_)
- [Retry/Wait (`radp_wait_until`, `radp_retry`)](#retrywait)
- [Sysctl Management (`radp_os_sysctl_*`)](#sysctl-management-radp_os_sysctl_)
- [Kernel Module Management (`radp_os_*`)](#kernel-module-management-radp_os_)
- [Service Management (`radp_os_service_*`)](#service-management-radp_os_service_)
- [User/Group Management (`radp_os_*`)](#usergroup-management-radp_os_)
- [Network (`radp_net_*`)](#network-radp_net_)
- [Arrays (`radp_nr_*`)](#arrays-radp_nr_)
- [Dry-Run Mode (`radp_exec_*`)](#dry-run-mode-radp_exec_)
- [CLI Infrastructure (`radp_cli_*`)](#cli-infrastructure-radp_cli_)
  - [Application Bootstrap](#application-bootstrap)
  - [Request Detection](#request-detection)
  - [Command Discovery](#command-discovery)
  - [Metadata Parsing](#metadata-parsing)
  - [Argument Parsing](#argument-parsing)
  - [Help Generation](#help-generation)
  - [Command Dispatch](#command-dispatch)
  - [Shell Completion](#shell-completion)
  - [Dynamic Completion](#dynamic-completion)
  - [Passthrough Mode](#passthrough-mode)
  - [Scaffolding](#scaffolding)
- [IDE Integration (`radp_ide_*`)](#ide-integration-radp_ide_)

---

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
| `opt_*`            | Command option (auto-set)    | `opt_dry_run`                  |
| `args_*`           | Command argument (auto-set)  | `args_name`                    |
| `gopt_*`           | App global option (auto-set) | `gopt_config`                  |

### Return Code Conventions

| Code | Meaning                                       |
|------|-----------------------------------------------|
| `0`  | Success / True (for boolean functions)        |
| `1`  | General error / False (for boolean functions) |
| `2`  | Missing or invalid arguments                  |

### Common Global Variables

| Variable                   | Description                                            |
|----------------------------|--------------------------------------------------------|
| `gr_fw_root_path`          | Framework installation root directory                  |
| `gr_fw_version`            | Framework version string                               |
| `gr_fw_user_config_path`   | User configuration directory                           |
| `gr_fw_app_config_path`    | App bundled config directory (always points to source) |
| `gr_fw_context_cache_path` | Framework cache directory                              |
| `gw_fw_run_initialized`    | Framework initialization flag                          |
| `gwxa_fw_sourced_scripts`  | Array of sourced script paths                          |

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

| Variable               | Description          | Default |
|------------------------|----------------------|---------|
| `GX_RADP_FW_LOG_DEBUG` | Enable debug logging | `false` |
| `GX_RADP_FW_LOG_LEVEL` | Minimum log level    | `info`  |
| `gr_radp_fw_log_level` | Log level (readonly) | `info`  |

**Enable debug logging** (choose one):

```bash
# CLI flag (for scaffold apps)
myapp --debug hello

# YAML config (recommended for persistent settings)
# radp.fw.log.debug: true

# Environment variable
GX_RADP_FW_LOG_DEBUG=true myapp hello
```

### Example

```bash
radp_log_debug "Connecting to database" # Only shown when debug is enabled
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

## System Security (`radp_os_*`)

**Location:** `libs/toolkit/os/02_security.sh`

### radp_os_disable_selinux

Disable SELinux. Sets SELinux to permissive mode temporarily and disables it in config.

```bash
radp_os_disable_selinux()
```

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success or already disabled, `1` on failure

**Note:** Only applicable on systems with SELinux (RHEL, CentOS, Fedora, etc.). On systems without SELinux, returns `0`
immediately.

**Example:**

```bash
radp_os_disable_selinux || {
  radp_log_error "Failed to disable SELinux"
  return 1
}
```

### radp_os_disable_firewalld

Disable firewalld. Stops and disables the firewalld service.

```bash
radp_os_disable_firewalld()
```

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success or already disabled, `1` on failure

**Note:** Only applicable on systems with firewalld (RHEL, CentOS, Fedora, etc.). On systems without firewalld, returns
`0` immediately.

**Example:**

```bash
radp_os_disable_firewalld || {
  radp_log_error "Failed to disable firewalld"
  return 1
}
```

---

## System Resources (`radp_os_*`)

**Location:** `libs/toolkit/os/03_resource.sh`

### radp_os_check_min_cpu_cores

Check if system has at least the specified number of CPU cores.

```bash
radp_os_check_min_cpu_cores (min_cores)
```

**Parameters:**

- `min_cores` — Minimum required CPU cores

**Returns:** `0` if system meets requirement, `1` if not

**Outputs:** Warning message if requirement not met

**Example:**

```bash
if ! radp_os_check_min_cpu_cores 4; then
  radp_log_error "Insufficient CPU cores for this application"
  exit 1
fi
```

### radp_os_check_min_ram

Check if system has at least the specified amount of RAM.

```bash
radp_os_check_min_ram (min_ram)
```

**Parameters:**

- `min_ram` — Minimum required RAM (supports GB, G, MB, M suffixes)
  - Examples: `"4GB"`, `"4G"`, `"4096MB"`, `"4096M"`, `"4096"` (MB default)

**Returns:** `0` if system meets requirement, `1` if not

**Outputs:** Warning message if requirement not met

**Example:**

```bash
radp_os_check_min_ram 4GB || {
  radp_log_error "System requires at least 4GB RAM"
  exit 1
}

radp_os_check_min_ram 4G
radp_os_check_min_ram 4096M
```

### radp_os_get_total_ram_mb

Get total system RAM in MB.

```bash
radp_os_get_total_ram_mb()
```

**Returns:** `0` on success, `1` if unable to determine

**Outputs:** Total RAM in MB to stdout

**Example:**

```bash
ram_mb=$(radp_os_get_total_ram_mb)
echo "System has ${ram_mb}MB RAM"

ram_gb=$((ram_mb / 1024))
echo "System has ${ram_gb}GB RAM"
```

### radp_os_get_cpu_cores

Get total CPU cores count.

```bash
radp_os_get_cpu_cores()
```

**Returns:** `0` on success, `1` if unable to determine

**Outputs:** Number of CPU cores to stdout

**Example:**

```bash
cores=$(radp_os_get_cpu_cores)
echo "System has $cores CPU cores"
```

---

## Cron Management (`radp_os_crontab_*`)

**Location:** `libs/toolkit/os/07_cron.sh`

### radp_os_crontab_add

Add or update crontab from a file. Merges contents of a crontab file into user's crontab.

```bash
radp_os_crontab_add (user crontab_file)
```

**Parameters:**

- `user` — User to update crontab for
- `crontab_file` — Path to crontab file to merge

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
# Create a crontab file
cat >/tmp/my-crontab <<'EOF'
# Backup every day at 4 AM
0 4 * * * /usr/local/bin/backup.sh
EOF

radp_os_crontab_add "root" "/tmp/my-crontab"
```

### radp_os_create_or_update_crontab

Create or replace crontab from content string.

```bash
radp_os_create_or_update_crontab (user content)
```

**Parameters:**

- `user` — User to update crontab for
- `content` — Crontab content (multiline string)

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
crontab_content=$(
  cat <<'EOF'
# Daily backup at 4 AM
0 4 * * * /usr/local/bin/backup.sh
# Weekly cleanup on Saturday at 8 PM
0 20 * * 6 /usr/local/bin/cleanup.sh
EOF
)

radp_os_create_or_update_crontab "vagrant" "$crontab_content"
```

### radp_os_crontab_remove

Remove crontab entries matching pattern.

```bash
radp_os_crontab_remove (user pattern)
```

**Parameters:**

- `user` — User to update crontab for
- `pattern` — Grep pattern to match lines to remove

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
# Remove all backup-related cron entries
radp_os_crontab_remove "root" "backup.sh"

# Remove all gitlab-related cron entries
radp_os_crontab_remove "vagrant" "gitlab"
```

### radp_os_crontab_list

List user's crontab entries.

```bash
radp_os_crontab_list ([user])
```

**Parameters:**

- `user` — User to list crontab for (optional, defaults to current user)

**Returns:** `0` on success, `1` on failure or no crontab

**Outputs:** Crontab contents to stdout

**Example:**

```bash
# List current user's crontab
radp_os_crontab_list

# List root's crontab
radp_os_crontab_list "root"

# Check if crontab has entries
if radp_os_crontab_list "vagrant" | grep -q "backup"; then
  echo "Backup cron is configured"
fi
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

### File Content

#### radp_io_append_line_unique

Append a line to file if it doesn't already exist (deduplication).

```bash
radp_io_append_line_unique (file_path line)
```

**Parameters:**

- `file_path` — Path to the file
- `line` — Line content to append

**Globals:**

- `gr_sudo` — Sudo command prefix (optional, used if file requires elevated permissions)

**Returns:** `0` on success (line added or already exists), `1` on failure

**Example:**

```bash
radp_io_append_line_unique "/etc/hosts" "127.0.0.1 myhost"
radp_io_append_line_unique "$HOME/.bashrc" "export PATH=\$PATH:/opt/bin"
```

### YAML Parsing (Lightweight)

**Location:** `libs/toolkit/io/05_yaml.sh`

Simple YAML parsing using only grep/sed (no external dependencies like `yq`).

> **Note:** For complex YAML operations (nested structures, variable references, merging),
> use the `yq`-based functions in `autoconfigure.sh` instead.

**Limitations:**

- Only supports simple `key: value` pairs (no nested objects)
- Only supports simple lists (`- item` format)
- Does not handle multi-line values
- Does not handle YAML anchors/aliases

#### radp_io_yaml_get_value

Extract a scalar value from YAML content.

```bash
radp_io_yaml_get_value (key [content])
```

**Parameters:**

- `key` — The YAML key to extract (required)
- `content` — YAML content (optional, reads from stdin if not provided)

**Returns:** `0` on success

**Outputs:** The value for the specified key (quotes stripped)

**Example:**

```bash
# From variable
version=$(radp_io_yaml_get_value "version" "$yaml_content")

# From file via stdin
name=$(radp_io_yaml_get_value "name" <config.yaml)

# From pipe
author=$(echo "$yaml" | radp_io_yaml_get_value "author")
```

#### radp_io_yaml_get_list

Extract list items from YAML content.

```bash
radp_io_yaml_get_list
```

**Parameters:** None (reads from stdin)

**Returns:** `0` on success

**Outputs:** List items, one per line (leading `- ` stripped)

**Example:**

```bash
# Parse list items
echo "$yaml_list" | radp_io_yaml_get_list

# Given input:
#   - foo
#   - bar
# Returns:
#   foo
#   bar
```

#### radp_io_yaml_get_section

Extract a specific section from YAML content.

```bash
radp_io_yaml_get_section (key [content])
```

**Parameters:**

- `key` — The section key to extract (required)
- `content` — YAML content (optional, reads from stdin if not provided)

**Returns:** `0` on success

**Outputs:** All lines belonging to the section (including nested content)

**Example:**

```bash
# Extract dependencies section, then parse as list
deps=$(radp_io_yaml_get_section "dependencies" "$yaml" | radp_io_yaml_get_list)
```

#### radp_io_yaml_has_key

Check if a key exists in YAML content.

```bash
radp_io_yaml_has_key (key [content])
```

**Parameters:**

- `key` — The YAML key to check (required)
- `content` — YAML content (optional, reads from stdin if not provided)

**Returns:** `0` if key exists, `1` if not found

**Example:**

```bash
if radp_io_yaml_has_key "enabled" "$yaml_content"; then
  echo "Key 'enabled' exists"
fi
```

---

## User Prompts (`radp_io_prompt_*`)

**Location:** `libs/toolkit/io/02_prompt.sh`

### radp_io_prompt_confirm

Confirmation prompt (y/N style). Displays a message and waits for user confirmation.

```bash
radp_io_prompt_confirm (--msg <string >[--default <Y | N >] [--timeout <sec >] [--level <info | warn | error >])
```

**Parameters:**

- `--msg <string>` — Prompt message (required)
- `--default <Y|N>` — Default answer if user presses Enter (default: `N`)
- `--timeout <sec>` — Timeout in seconds (default: `0`, no timeout)
- `--level <info|warn|error>` — Log level for the prompt (default: `info`)

**Returns:** `0` if user confirmed (y/Y or default Y on timeout/empty input), `1` if user declined or timeout with
default N

**Example:**

```bash
radp_io_prompt_confirm --msg "Continue?" --default Y
radp_io_prompt_confirm --msg "Delete file?" --level warn --timeout 30

if radp_io_prompt_confirm --msg "Proceed with installation? (y/N)"; then
  echo "Installing..."
fi
```

### radp_nr_io_prompt_input

Input prompt with nameref. Prompts user for input and stores result in a variable.

```bash
radp_nr_io_prompt_input (
  nameref --msg <string >[--default <value >] [--timeout <sec >] [--level <info | warn | error >]
)
```

**Parameters:**

- `nameref` — Variable name to store user input (required, first positional argument)
- `--msg <string>` — Prompt message (required)
- `--default <value>` — Default value if user presses Enter
- `--timeout <sec>` — Timeout in seconds (default: `0`, no timeout)
- `--level <info|warn|error>` — Log level for the prompt (default: `info`)

**Returns:** `0` on success, `1` on timeout or error

**Example:**

```bash
local user_name
radp_nr_io_prompt_input user_name --msg "Enter your name:" --default "anonymous"
echo "Hello, $user_name"

local choice
radp_nr_io_prompt_input choice --msg "Select option:" --timeout 60
```

---

## Retry/Wait

**Location:** `libs/toolkit/exec/02_retry.sh`

Functions for waiting on conditions and retrying commands with configurable attempts and intervals.

### radp_wait_until

Wait until a condition becomes true.

```bash
radp_wait_until (condition_cmd [--max-attempts N] [--interval N] [--message MSG])
```

**Parameters:**

- `condition_cmd` — Command to check (exit 0 = success)
- `--max-attempts N` — Maximum attempts (default: `10`)
- `--interval N` — Sleep interval in seconds (default: `5`)
- `--message MSG` — Progress message (optional)

**Returns:** `0` if condition became true, `1` if timeout (max attempts reached)

**Example:**

```bash
# Wait for Kubernetes cluster to be ready
radp_wait_until "kubectl cluster-info" --max-attempts 5 --interval 10

# Wait for network interface with custom message
radp_wait_until "ip link show flannel.1" \
  --max-attempts 15 \
  --interval 10 \
  --message "Waiting for flannel..."
```

### radp_retry

Retry a command until it succeeds.

```bash
radp_retry (command [--max-attempts N] [--interval N] [--message MSG])
```

**Parameters:**

- `command` — Command to execute
- `--max-attempts N` — Maximum attempts (default: `3`)
- `--interval N` — Sleep interval between retries (default: `2`)
- `--message MSG` — Progress message (optional)

**Returns:** Exit code of the last command execution

**Example:**

```bash
# Retry curl with custom retry settings
radp_retry "curl -fsSL https://example.com" --max-attempts 5 --interval 3

# Retry with progress message
radp_retry "wget https://example.com/file.tar.gz" \
  --max-attempts 3 \
  --message "Downloading file..."
```

---

## Sysctl Management (`radp_os_sysctl_*`)

**Location:** `libs/toolkit/os/04_sysctl.sh`

Functions for managing kernel parameters via sysctl.

### radp_os_sysctl_set

Set a sysctl parameter temporarily (does not persist across reboots).

```bash
radp_os_sysctl_set (key value)
```

**Parameters:**

- `key` — sysctl parameter name (e.g., `net.ipv4.ip_forward`)
- `value` — Value to set

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
radp_os_sysctl_set "net.ipv4.ip_forward" "1"
radp_os_sysctl_set "net.bridge.bridge-nf-call-iptables" "1"
```

### radp_os_sysctl_check

Check if a sysctl parameter has the expected value.

```bash
radp_os_sysctl_check (key expected)
```

**Parameters:**

- `key` — sysctl parameter name
- `expected` — Expected value

**Returns:** `0` if parameter matches expected value, `1` if not or error

**Example:**

```bash
if radp_os_sysctl_check "net.ipv4.ip_forward" "1"; then
  echo "IP forwarding is enabled"
fi
```

### radp_os_sysctl_configure_persistent

Configure sysctl parameters persistently. Creates a config file in `/etc/sysctl.d/` and applies settings.

```bash
radp_os_sysctl_configure_persistent (config_name key=value [key=value...])
```

**Parameters:**

- `config_name` — Name for the config file (without `.conf` extension)
- `key=value` — One or more sysctl parameters to configure

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
# Configure Kubernetes networking requirements
radp_os_sysctl_configure_persistent "k8s" \
  "net.bridge.bridge-nf-call-iptables=1" \
  "net.bridge.bridge-nf-call-ip6tables=1" \
  "net.ipv4.ip_forward=1"

# Creates /etc/sysctl.d/k8s.conf and applies settings
```

---

## Kernel Module Management (`radp_os_*`)

**Location:** `libs/toolkit/os/08_kernel.sh`

Functions for loading and configuring kernel modules.

### radp_os_is_kernel_module_loaded

Check if a kernel module is currently loaded.

```bash
radp_os_is_kernel_module_loaded (module)
```

**Parameters:**

- `module` — Kernel module name

**Returns:** `0` if module is loaded, `1` if not

**Example:**

```bash
if radp_os_is_kernel_module_loaded "overlay"; then
  echo "overlay module is loaded"
fi
```

### radp_os_load_kernel_modules

Load one or more kernel modules.

```bash
radp_os_load_kernel_modules (module [module...])
```

**Parameters:**

- `module` — One or more kernel module names to load

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` if all modules loaded successfully, `1` if any failed

**Example:**

```bash
# Load modules required for Kubernetes
radp_os_load_kernel_modules "overlay" "br_netfilter"
```

### radp_os_configure_kernel_modules

Configure kernel modules to load at boot. Creates a config file in `/etc/modules-load.d/`.

```bash
radp_os_configure_kernel_modules (config_name module [module...])
```

**Parameters:**

- `config_name` — Name for the config file (without `.conf` extension)
- `module` — One or more kernel module names to configure

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
# Configure modules for boot persistence
radp_os_configure_kernel_modules "k8s" "overlay" "br_netfilter"
# Creates /etc/modules-load.d/k8s.conf
```

### radp_os_setup_kernel_modules

Configure and load kernel modules (combines `configure_kernel_modules` and `load_kernel_modules`).

```bash
radp_os_setup_kernel_modules (config_name module [module...])
```

**Parameters:**

- `config_name` — Name for the config file (without `.conf` extension)
- `module` — One or more kernel module names

**Globals:**

- `gr_sudo` — Sudo command prefix

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
# Configure for boot and load immediately
radp_os_setup_kernel_modules "k8s" "overlay" "br_netfilter"
```

---

## Service Management (`radp_os_service_*`)

**Location:** `libs/toolkit/os/09_service.sh`

Functions for managing systemd services.

### radp_os_service_enable_start

Enable and start a systemd service.

```bash
radp_os_service_enable_start (service_name)
```

**Parameters:**

- `service_name` — Name of the service (with or without `.service` suffix)

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
radp_os_service_enable_start "docker"
radp_os_service_enable_start "containerd.service"
```

### radp_os_service_restart

Restart a systemd service.

```bash
radp_os_service_restart (service_name)
```

**Parameters:**

- `service_name` — Name of the service (with or without `.service` suffix)

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
radp_os_service_restart "docker"
```

### radp_os_service_stop_disable

Stop and disable a systemd service.

```bash
radp_os_service_stop_disable (service_name)
```

**Parameters:**

- `service_name` — Name of the service (with or without `.service` suffix)

**Returns:** `0` on success

**Example:**

```bash
radp_os_service_stop_disable "firewalld"
```

### radp_os_service_configure_http_proxy

Configure HTTP proxy for a systemd service. Creates a drop-in file for proxy environment variables.

```bash
radp_os_service_configure_http_proxy (service_name http_proxy [https_proxy] [no_proxy])
```

**Parameters:**

- `service_name` — Name of the service (e.g., `docker`, `containerd`)
- `http_proxy` — HTTP proxy URL (required)
- `https_proxy` — HTTPS proxy URL (optional, defaults to `http_proxy`)
- `no_proxy` — Comma-separated list of hosts to bypass (optional, defaults to `localhost,127.0.0.1`)

**Returns:** `0` on success, `1` on failure

**Example:**

```bash
# Configure proxy for Docker
radp_os_service_configure_http_proxy "docker" \
  "http://proxy.example.com:8080" \
  "http://proxy.example.com:8080" \
  "localhost,127.0.0.1,10.0.0.0/8"

# Creates /etc/systemd/system/docker.service.d/http-proxy.conf
```

### radp_os_service_remove_http_proxy

Remove HTTP proxy configuration for a systemd service.

```bash
radp_os_service_remove_http_proxy (service_name)
```

**Parameters:**

- `service_name` — Name of the service (e.g., `docker`, `containerd`)

**Returns:** `0` on success

**Example:**

```bash
radp_os_service_remove_http_proxy "docker"
# Removes /etc/systemd/system/docker.service.d/http-proxy.conf
```

---

## User/Group Management (`radp_os_*`)

**Location:** `libs/toolkit/os/10_user.sh`

Functions for managing users and groups.

### radp_os_user_in_group

Check if a user belongs to a specific group.

```bash
radp_os_user_in_group (user group)
```

**Parameters:**

- `user` — Username to check
- `group` — Group name to check membership in

**Returns:** `0` if user is in the group, `1` if not or error

**Example:**

```bash
if radp_os_user_in_group "vagrant" "docker"; then
  echo "User can run Docker commands"
fi
```

### radp_os_ensure_group

Ensure a group exists, creating it if necessary.

```bash
radp_os_ensure_group (group)
```

**Parameters:**

- `group` — Group name to ensure exists

**Returns:** `0` if group exists or was created, `1` on failure

**Example:**

```bash
radp_os_ensure_group "docker"
```

### radp_os_user_add_to_group

Add a user to a group.

```bash
radp_os_user_add_to_group (user group)
```

**Parameters:**

- `user` — Username to add
- `group` — Group name to add user to

**Returns:** `0` if user added or already in group, `1` on failure

**Note:** User needs to log out and back in for group membership to take effect.

**Example:**

```bash
# Add user to docker group for rootless Docker access
radp_os_user_add_to_group "vagrant" "docker"
```

### radp_os_user_remove_from_group

Remove a user from a group.

```bash
radp_os_user_remove_from_group (user group)
```

**Parameters:**

- `user` — Username to remove
- `group` — Group name to remove user from

**Returns:** `0` if user removed or not in group, `1` on failure

**Example:**

```bash
radp_os_user_remove_from_group "testuser" "docker"
```

### radp_os_get_current_user

Get the current username.

```bash
radp_os_get_current_user()
```

**Outputs:** Current username

**Example:**

```bash
current_user=$(radp_os_get_current_user)
echo "Running as: $current_user"
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

## Dry-Run Mode (`radp_exec_*`)

**Location:** `libs/toolkit/exec/04_dry_run.sh`

The dry-run mode support provides wrapper functions for command execution that respect a global dry-run flag. When
dry-run mode is enabled, commands are logged instead of executed.

### Global Variable

| Variable     | Description                                              |
|--------------|----------------------------------------------------------|
| `gw_dry_run` | Global writable flag for dry-run mode (`"true"` or `""`) |

### Functions

#### radp_set_dry_run

Enable or disable dry-run mode.

```bash
radp_set_dry_run ([enabled])
```

**Parameters:**

- `enabled` — `"true"`, `"1"`, or empty to enable; any other value to disable (default: `"true"`)

**Example:**

```bash
# Enable from CLI flag
radp_set_dry_run "${opt_dry_run:-}"

# Explicitly enable
radp_set_dry_run true

# Explicitly disable
radp_set_dry_run false
```

#### radp_is_dry_run

Check if dry-run mode is enabled.

```bash
radp_is_dry_run()
```

**Returns:** `0` if dry-run mode is enabled, `1` otherwise

**Example:**

```bash
if radp_is_dry_run; then
  echo "Would perform operation..."
else
  perform_operation
fi
```

#### radp_exec

Execute command or log in dry-run mode.

```bash
radp_exec (description command [args...])
```

**Parameters:**

- `description` — Human-readable description of the operation
- `command` — Command to execute
- `args` — Command arguments

**Returns:** `0` in dry-run mode, otherwise the command's exit code

**Example:**

```bash
radp_exec "Create config directory" mkdir -p /etc/myapp
radp_exec "Install package" apt-get install -y nginx
radp_exec "Start service" systemctl start nginx
```

#### radp_exec_sudo

Execute command with sudo or log in dry-run mode.

```bash
radp_exec_sudo (description command [args...])
```

**Parameters:**

- `description` — Human-readable description of the operation
- `command` — Command to execute (will be prefixed with `${gr_sudo:-}`)
- `args` — Command arguments

**Returns:** `0` in dry-run mode, otherwise the command's exit code

**Note:** Uses `${gr_sudo:-}` which is set by the framework based on whether the current user is root.

**Example:**

```bash
radp_exec_sudo "Update package cache" apt-get update -qq
radp_exec_sudo "Install nginx" apt-get install -y nginx
radp_exec_sudo "Enable service" systemctl enable nginx
```

#### radp_dry_run_skip

Check and log for complex operations that can't use `radp_exec`.

```bash
radp_dry_run_skip (description)
```

**Parameters:**

- `description` — Human-readable description of the operation being skipped

**Returns:** `0` if dry-run mode is enabled (operation should be skipped), `1` otherwise (proceed with operation)

**Example:**

```bash
if radp_dry_run_skip "Configure yadm repository"; then
  radp_log_info "[dry-run]   - Repository: $repo_url"
  radp_log_info "[dry-run]   - Would run bootstrap after clone"
  return 0
fi

# Complex operations that can't be wrapped in radp_exec
yadm clone "$repo_url"
yadm bootstrap
```

### Usage Pattern

Typical usage in a CLI command with `--dry-run` flag:

```bash
# @cmd
# @desc Configure system settings
# @flag --dry-run Show what would be done without making changes

cmd_configure() {
  # Enable dry-run from flag
  radp_set_dry_run "${opt_dry_run:-}"

  # Simple commands - use radp_exec or radp_exec_sudo
  radp_exec_sudo "Install required packages" apt-get install -y curl wget

  # Complex operations - use radp_dry_run_skip
  if radp_dry_run_skip "Apply configuration changes"; then
    radp_log_info "[dry-run]   - Would modify /etc/myapp/config"
    radp_log_info "[dry-run]   - Would restart service"
    return 0
  fi

  # Actual complex logic here
  configure_application
  restart_services
}
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

#### Entry Script (Recommended)

For scaffold projects, use `launcher.sh` which handles all setup automatically:

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! command -v radp-bf &>/dev/null; then
  echo "Error: radp-bash-framework not found." >&2
  exit 1
fi

export RADP_APP_ROOT="$(radp-bf resolve-root "${BASH_SOURCE[0]}")"
source "$(radp-bf path launcher)" "$@"
```

The launcher automatically:

- Detects dev/installed mode via `_ide.sh` marker
- Sets config and library paths
- Parses global options (`-v`, `--debug`, `--show-config`)
- Runs command dispatch

#### radp_app_bootstrap (Legacy)

Simplified bootstrap with auto-detection. Use `launcher.sh` for new projects.

```bash
radp_app_bootstrap (app_root app_name [arguments...])
```

**Parameters:**

- `app_root` — Application root directory
- `app_name` — Application name
- `arguments` — Command-line arguments to pass

#### radp_app_run

Main application entry point.

```bash
radp_app_run ([arguments...])
```

**Parameters:**

- `arguments` — Command-line arguments

**Prerequisites:** Commands directory must be set via `radp_cli_set_commands_dir()`

**Note:** When using `launcher.sh`, this is called automatically.

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

#### radp_app_show_config

Display application configuration information. Outputs app info, framework settings, config paths, log settings, and
optionally extension configurations.

```bash
radp_app_show_config()
```

**Output formats:**

- **Text** (default): Docker info style grouped sections
- **JSON**: Machine-readable format (set `__RADP_APP_CONFIG_JSON=true`)
- **With extensions**: Include extension configs (set `__RADP_APP_CONFIG_ALL=true`)

**Example output (text):**

```
App:         myapp
Version:     v1.0.0
Environment: local

Framework:
 Version:    v0.6.29
 Root:       /usr/local/opt/radp-bash-framework/libexec

Config:
 Directory:  /home/user/.config/myapp
 File:       /home/user/.config/myapp/config.yaml (exists)
 Libs:       /home/user/myapp/src/main/shell/libs

Settings:
 Banner:     off

Log:
 Level:      info
 Debug:      false
 Console:    enabled
 File:       enabled
 File Path:  /home/user/logs/radp/myapp.log

Log Rolling:
 Enabled:       true
 Max History:   7
 Max File Size: 10MB
 Total Size:    5GB
```

**Usage:** This function is typically invoked via `myapp --show-config` global option (handled by `launcher.sh`). Use
`--show-config --all` to include extension configurations.

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

### Application Global Options

Application-level global options are defined in `commands/_globals.sh` using `@global` annotations. These options are
available to all commands and use the `gopt_` variable prefix.

#### radp_cli_load_app_global_options

Load application-level global options from `_globals.sh`.

```bash
radp_cli_load_app_global_options()
```

**Behavior:**

- Scans `commands/_globals.sh` for `@global` annotations
- Populates `__radp_cli_app_global_options` (space-separated list for completion)
- Populates `__radp_cli_app_global_options_spec` (array of option specs)

**Called automatically** by `launcher.sh` before command dispatch.

#### radp_cli_parse_app_global_options

Parse application global options from arguments (before command).

```bash
radp_cli_parse_app_global_options (args_var_name)
```

**Parameters:**

- `args_var_name` — Name of array variable containing arguments (modified in place)

**Behavior:**

- Extracts global options from the beginning of arguments
- Sets `gopt_<name>` variables for each found option
- Removes parsed options from the input array

**Example:**

```bash
local -a args=("-c" "/path" "list" "--verbose")
radp_cli_parse_app_global_options args
# gopt_config="/path"
# args=("list" "--verbose")
```

#### radp_cli_extract_app_global_options

Extract application global options from arguments (after command).

```bash
radp_cli_extract_app_global_options (args_var_name)
```

**Parameters:**

- `args_var_name` — Name of array variable containing command arguments (modified in place)

**Behavior:**

- Scans command arguments for global options
- Sets `gopt_<name>` variables for each found option
- Removes extracted options from the input array

**Note:** This handles the case where global options appear after the command name (e.g., `myapp list -c /path`).

#### radp_cli_app_global_options_help

Generate help text for application global options.

```bash
radp_cli_app_global_options_help()
```

**Returns:** `0` if global options exist, `1` if none defined

**Outputs:** Formatted help text for global options section

**Example output:**

```
Global Options:
  -c, --config <dir>    Configuration directory
  -e, --env <name>      Environment name [default: local]
```

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

The framework generates a `_idecomp.sh` file containing `# shellcheck source=...` directives. BashSupport Pro uses
ShellCheck's source directives to resolve symbols and provide code completion.

**Generated file locations:**

- `$gr_fw_user_config_path/_idecomp.sh` — User config directory
- `$gr_fw_context_cache_path/_idecomp.sh` — Framework cache (for development)

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
| No completion     | Ensure `_idecomp.sh` exists in user config path          |
| Stale completion  | Delete `_idecomp.sh` and run CLI again                   |
| Read-only install | IDE hints are skipped for system installs (`/usr/lib64`) |

> **Note:** The `_idecomp.sh` file uses absolute paths and should be added to `.gitignore`.
