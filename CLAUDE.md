# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

radp-bash-framework is a modular Bash framework providing structured context, configuration management, logging, and a comprehensive toolkit for shell scripting.

## Commands

### Testing
```bash
bats src/test/shell                    # Run all tests
bats src/test/shell/<file>.bats        # Run specific test file
```

### Framework Entry
```bash
source src/main/shell/framework/run.sh              # Source framework directly
source "$(./src/main/shell/bin/radp-bf --print-run)" # Via CLI wrapper
```

### CLI Options
```bash
radp-bf --print-run    # Print path to run.sh
radp-bf --print-root   # Print framework root path
radp-bf --version      # Print version
```

## Architecture

### Execution Flow
```
run.sh (idempotent via gw_fw_run_initialized)
  ↓
preflight/ (environment & dependency checks)
  ↓
bootstrap/bootstrap.sh (context builder)
  ↓
context/context.sh (injects globals, libs, config)
  ├─ libs/logger/ (logging system)
  ├─ libs/toolkit/ (6 domains: core, exec, io, net, os, cli)
  ├─ vars/global_vars.sh (all variable declarations)
  └─ config autoconfiguration (YAML → shell vars)
```

### Key Directories
- `src/main/shell/framework/` — Framework source
- `src/main/shell/config/` — Default configuration YAMLs
- `src/test/shell/` — BATS tests

### Sourcing & Load Order
- `__fw_source_scripts` sources all `.sh` files in a directory
- Files sorted by numeric prefix: `1_feature.sh`, `2_other.sh`
- Sourced files recorded in `gwxa_fw_sourced_scripts` array

### Configuration Layering
1. `framework_config.yaml` — Framework defaults
2. User `config.yaml` — Overrides via `radp.fw.*` or `radp.extend.*`
3. Environment variables — `GX_RADP_FW_*` or `YAML_*` prefix
4. Final config cached in `cache/final_config.sh`

## Naming Conventions

### Variables
- `gr_*` — Global readonly paths/config (e.g., `gr_fw_root_path`)
- `gw_*` — Global writable state/flags (e.g., `gw_fw_run_initialized`)
- `gwxa_*` — Global arrays (e.g., `gwxa_fw_sourced_scripts`)
- Use `local` for function-scoped variables

### Functions
- `__fw_*` — Framework private/internal (double underscore)
- `radp_*` — Public framework functions
- `radp_nr_*` — Functions using nameref (pass variable name, not `$value`)
- `radp_*_is_*` — Boolean checks returning 0/1

## Toolkit Domains

The toolkit is organized into 6 domains under `libs/toolkit/`:
- **core** — Variables, arrays, maps, strings, version comparison
- **exec** — Command execution with logging, retry strategies
- **io** — File operations, interactive prompts, text banners
- **net** — Connectivity checks, interface queries, SSH operations
- **os** — Distro detection, security (SELinux/firewall), user management
- **cli** — Argument parsing, help generation, command dispatch

## CLI Command Discovery

Commands are auto-discovered from the `commands/` directory:
```
commands/
├── version.sh              # Top-level: mycli version
├── vf/
│   ├── init.sh             # Subcommand: mycli vf init
│   ├── list.sh             # Subcommand: mycli vf list
│   └── template/
│       ├── list.sh         # Nested: mycli vf template list
│       └── show.sh         # Nested: mycli vf template show
```

### Command File Requirements
- Must contain `# @cmd` marker to be discovered
- Function name follows path: `commands/vf/init.sh` → `cmd_vf_init()`
- Files starting with `_` are ignored (internal use)

### Nested Command Groups
- Supports arbitrary nesting depth (`vf template list`)
- Command groups without a `.sh` file show "Missing subcommand" with correct path
- Help is auto-generated for command groups showing available subcommands

## Banner Customization

Applications can customize the startup banner (shown when `banner-mode: on`):

### Priority Order
1. `radp_app_banner()` function - defined before sourcing framework
2. `$gr_fw_user_config_path/banner.txt` - user config path banner file
3. Framework default banner - `config/banner.txt`

### Hook Function Example
```bash
# Define BEFORE sourcing framework
radp_app_banner() {
  cat << 'EOF'
    __  __         _
   |  \/  |_   _  / \   _ __  _ __
   | |\/| | | | |/ _ \ | '_ \| '_ \
   | |  | | |_| / ___ \| |_) | |_) |
   |_|  |_|\__, /_/   \_\ .__/| .__/
           |___/        |_|   |_|
EOF
  printf ' :: MyApp ::                (%s)\n' "$gr_myapp_version"
  printf ' :: radp-bash-framework ::  (%s)\n' "$gr_fw_version"
}

source "$(radp-bf --print-run)"
```

The hook function has access to all framework variables (`$gr_fw_version`, etc.) since it's called after context initialization.

## Code Style

- Entry scripts (`run.sh`, `preflight/*.sh`) use POSIX-compatible syntax
- Bootstrap and beyond use Bash features (`[[ ]]`, arrays, `mapfile`)
- Quote variables unless intentional word splitting
- Preserve existing ShellCheck annotations (`# shellcheck source=...`)
- Use `radp_log_*` functions instead of ad-hoc `echo` for output

## IDE Integration

For BashSupport Pro navigation:
- IDE code completion is handled by `libs/toolkit/ide/01_hints.sh`
- `radp_ide_init()` generates `completion.sh` with framework and user sources
- `radp_ide_add_commands_dir()` appends user commands to the hints file
- Working directory should be repository root for stable relative paths
