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
source src/main/shell/framework/init.sh              # Source framework directly
source "$(./src/main/shell/bin/radp-bf path init)"    # Via CLI wrapper
source "$(radp-bf path launcher)" "$@"                # App launcher (thin entry script)
```

### CLI Commands
```bash
radp-bf new <name> [dir]           # Create a new CLI project
radp-bf upgrade [dir] [opts]       # Upgrade existing project to latest scaffold
radp-bf path init                  # Print path to init.sh (framework initializer)
radp-bf path launcher              # Print path to launcher.sh (app launcher)
radp-bf path root                  # Print framework root path
radp-bf resolve-root <script>      # Resolve project root from script path
radp-bf version                    # Print version
radp-bf help                       # Show help

# Upgrade examples
radp-bf upgrade                    # Upgrade current directory
radp-bf upgrade ./my-cli --dry-run # Preview changes
radp-bf upgrade --diff entry       # Show entry script diff
radp-bf upgrade --force            # Overwrite user-modified files
```

### Global Options (for apps using launcher.sh)

All CLI applications built on radp-bash-framework support these global options:

```bash
myapp --config          # Show configuration (paths, framework, extensions)
myapp --config --json   # Show configuration in JSON format
myapp -v, --verbose     # Enable verbose output (banner + info logs)
myapp --debug           # Enable debug output (banner + debug logs)
```

**Example output of `--config`:**
```
homelabctl Configuration
========================

[Paths]
  User config dir        ~/.config/homelabctl
  Config file            ~/.config/homelabctl/config.yaml (not found)
  User lib dir           <not set>
  Framework root         /usr/local/opt/radp-bash-framework/libexec

[Framework]
  Version                v1.0.0
  Banner mode            off
  Log level              error
  Log debug              false

[Application: homelabctl]
  version                v0.1.6

[Application: homelabctl.gitlab]
  type                   gitlab-ce
  default_version        latest
  ...
```

## Architecture

### Execution Flow
```
init.sh (idempotent via gw_fw_run_initialized)
  ↓
preflight/ (two-stage dependency checking)
  ├─ stage1/ (POSIX shell) → bash check/install
  └─ stage2/ (Bash) → gnu-getopt, yq check/install
  ↓
bootstrap/bootstrap.sh (context builder)
  ↓
context/context.sh (injects globals, libs, config)
  ├─ libs/logger/ (logging system)
  ├─ libs/toolkit/ (6 domains: core, exec, io, net, os, cli)
  ├─ vars/global_vars.sh (all variable declarations)
  └─ config autoconfiguration (YAML → shell vars)
```

### Preflight Two-Stage Design
- **Stage 1** (POSIX shell): Checks/installs bash 4.3+. Re-execs with new bash if installed.
- **Stage 2** (Bash): Checks/installs other dependencies using bash features for cleaner code.

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
- **exec** — Command execution with logging, retry strategies, dry-run mode
- **io** — File operations, interactive prompts, text banners
- **net** — Connectivity checks, interface queries, SSH operations
- **os** — Distro detection, security (SELinux/firewall), user management
- **cli** — Argument parsing, help generation, command dispatch

### Dry-Run Mode Support

The exec toolkit provides dry-run support for safe command execution preview:

```bash
# Enable dry-run mode (typically from CLI flag)
radp_set_dry_run "${opt_dry_run:-}"

# Execute command or log in dry-run mode
radp_exec "Install nginx package" apt-get install -y nginx
radp_exec "Set timezone to $tz" timedatectl set-timezone "$tz"

# Execute with sudo (uses $gr_sudo)
radp_exec_sudo "Enable chronyd service" systemctl enable chronyd

# For complex operations that can't be wrapped
if radp_dry_run_skip "Configure complex settings"; then
  return 0
fi
# ... actual implementation ...
```

**Available functions:**

| Function | Description |
|----------|-------------|
| `radp_set_dry_run [true\|false]` | Enable/disable dry-run mode |
| `radp_is_dry_run` | Check if dry-run mode is enabled (returns 0/1) |
| `radp_exec <desc> <cmd...>` | Execute command or log `[dry-run] <desc>` |
| `radp_exec_sudo <desc> <cmd...>` | Like `radp_exec` but prepends `$gr_sudo` |
| `radp_dry_run_skip <desc>` | Log and return 0 if dry-run, else return 1 |

**Global variable:**
- `gw_dry_run` — Writable global tracking dry-run state

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
- Dispatch uses longest-match: `myapp vf template show --verbose` matches `vf template show`
- `_`-prefixed files can be used as shared helpers (not discovered as commands)

See [docs/annotations.md](docs/annotations.md#subcommands) for the full subcommand authoring guide.

## Banner Customization

Applications can customize the startup banner ASCII art (shown when `banner-mode: on`).
The framework automatically appends version information.

### Priority Order (ASCII Art)
1. `radp_app_banner_art()` function - defined before sourcing framework
2. `$gr_fw_user_config_path/banner.txt` - user config path banner file
3. Framework default banner - `config/banner.txt`

### Hook Function Example
```bash
# Define BEFORE sourcing framework (ASCII art only)
radp_app_banner_art() {
  cat << 'EOF'
    __  ___      ___
   /  |/  /_  __/   |  ____  ____
  / /|_/ / / / / /| | / __ \/ __ \
 / /  / / /_/ / ___ |/ /_/ / /_/ /
/_/  /_/\__, /_/  |_/ .___/ .___/
       /____/      /_/   /_/
EOF
}

source "$(radp-bf path launcher)" "$@"
```

The framework will automatically append:
```
 :: my_app :: (v1.0.0)
 :: radp-bash-framework :: (v0.6.11)
```

## Code Style

- Entry scripts (`init.sh`, `preflight/*.sh`) use POSIX-compatible syntax
- Bootstrap and beyond use Bash features (`[[ ]]`, arrays, `mapfile`)
- Quote variables unless intentional word splitting
- Preserve existing ShellCheck annotations (`# shellcheck source=...`)
- Use `radp_log_*` functions instead of ad-hoc `echo` for output

## IDE Integration

For BashSupport Pro navigation:
- IDE code completion is handled by `libs/toolkit/ide/01_hints.sh`
- `radp_ide_init()` generates `_idecomp.sh` with framework and user sources
- `radp_ide_add_commands_dir()` appends user commands to the hints file
- Working directory should be repository root for stable relative paths
