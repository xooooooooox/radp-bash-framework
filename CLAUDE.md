# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

radp-bash-framework is a modular Bash framework providing structured context, configuration management, logging, and a
comprehensive toolkit for shell scripting.

## Commands

### Testing

```bash
bats src/test/shell # Run all tests
bats src/test/shell/ <file >.bats # Run specific test file
```

### Framework Entry

```bash
source src/main/shell/framework/init.sh # Source framework directly
source "$(./bin/radp-bf path init)" # Via CLI wrapper
source "$(radp-bf path launcher)" "$@" # App launcher (thin entry script)
```

### CLI Commands

```bash
radp-bf new <name >[dir] # Create a new CLI project
radp-bf upgrade [dir] [opts] # Upgrade existing project to latest scaffold
radp-bf path init # Print path to init.sh
radp-bf path launcher # Print path to launcher.sh
radp-bf version # Print version
```

### Global Options (for apps using launcher.sh)

```bash
myapp -v, --verbose # Enable verbose output
myapp --debug # Enable debug output
myapp --show-config # Show configuration
myapp --show-config --all # Show configuration with extensions
```

## Architecture

```
init.sh (idempotent via gw_fw_run_initialized)
  ↓
preflight/ (two-stage)
  ├─ stage1/ (POSIX) → bash check
  └─ stage2/ (Bash) → gnu-getopt, yq
  ↓
bootstrap/bootstrap.sh
  ↓
context/context.sh
  ├─ libs/logger/
  ├─ libs/toolkit/ (core, exec, io, net, os, cli)
  └─ config autoconfiguration
```

### Key Directories

| Directory                   | Purpose               |
|-----------------------------|-----------------------|
| `src/main/shell/framework/` | Framework source      |
| `src/main/shell/config/`    | Default configuration |
| `src/test/shell/`           | BATS tests            |
| `src/main/shell/commands/`  | radp-bf commands      |

### Configuration Layering

1. `framework_config.yaml` - Framework defaults
2. User `config.yaml` - Overrides via `radp.fw.*` or `radp.extend.*`
3. Environment variables - `GX_RADP_FW_*` prefix

## Naming Conventions

### Variables

| Prefix   | Scope                    | Example                   |
|----------|--------------------------|---------------------------|
| `gr_*`   | Global readonly          | `gr_fw_root_path`         |
| `gw_*`   | Global writable          | `gw_fw_run_initialized`   |
| `gwxa_*` | Global array             | `gwxa_fw_sourced_scripts` |
| `__fw_*` | Internal/private         | `__fw_config_cache`       |
| `opt_*`  | Command option (auto-set)  | `opt_dry_run`           |
| `args_*` | Command argument (auto-set) | `args_name`            |
| `gopt_*` | App global option (auto-set) | `gopt_config`         |

### Functions

| Pattern       | Meaning                 | Example                    |
|---------------|-------------------------|----------------------------|
| `radp_*`      | Public API              | `radp_log_info`            |
| `radp_nr_*`   | Nameref (pass var name) | `radp_nr_arr_merge_unique` |
| `radp_*_is_*` | Boolean (0/1)           | `radp_os_is_pkg_installed` |
| `__fw_*`      | Internal                | `__fw_bootstrap`           |

## Toolkit Domains

| Domain   | Functions                  |
|----------|----------------------------|
| **core** | Variables, arrays, strings |
| **exec** | Command execution, dry-run |
| **io**   | File operations            |
| **net**  | Network utilities          |
| **os**   | Distro detection           |
| **cli**  | Argument parsing, dispatch |

## CLI Command Discovery

Commands auto-discovered from `commands/` directory:

```
commands/
├── _globals.sh             # Application-level global options
├── version.sh              # mycli version
├── db/
│   ├── migrate.sh          # mycli db migrate
│   └── seed.sh             # mycli db seed
```

- Must contain `# @cmd` marker
- Function: `commands/db/migrate.sh` → `cmd_db_migrate()`
- `_`-prefixed files ignored (except `_globals.sh`)

## Application Global Options

Define application-level global options in `commands/_globals.sh`:

```bash
#!/usr/bin/env bash
# @global -c, --config <dir> Configuration directory
# @global -e, --env <name> Environment name [default: local]
```

- Uses `@global` annotation (same syntax as `@option`/`@flag`)
- Variables available as `gopt_<name>` (e.g., `gopt_config`, `gopt_env`)
- Options can be placed before or after the command:
  - `mycli -c /path list`
  - `mycli list -c /path`

## Dry-Run Mode

```bash
radp_set_dry_run "${opt_dry_run:-}"
radp_exec "Install nginx" apt-get install -y nginx
radp_exec_sudo "Enable service" systemctl enable nginx

if radp_dry_run_skip "Complex operation"; then
  return 0
fi
```

## Code Style

- Entry scripts (`init.sh`, `preflight/stage1/`) use POSIX syntax
- Bootstrap and beyond use Bash features (`[[ ]]`, arrays, `mapfile`)
- Quote variables unless intentional word splitting
- Use `radp_log_*` functions instead of `echo`
- Preserve ShellCheck annotations

## CI/CD Workflows

| Workflow                  | Purpose                      |
|---------------------------|------------------------------|
| `release-prep.yml`        | Create release branch and PR |
| `create-version-tag.yml`  | Create git tag               |
| `build-copr-package.yml`  | COPR build                   |
| `build-obs-package.yml`   | OBS build                    |
| `update-homebrew-tap.yml` | Update Homebrew              |

See [CONTRIBUTING.md](CONTRIBUTING.md) for release process.

## See Also

- [docs/developer/architecture.md](docs/developer/architecture.md) - Detailed architecture
- [docs/developer/code-style.md](docs/developer/code-style.md) - Full code style guide
- [docs/reference/api.md](docs/reference/api.md) - Complete API reference
- [AGENTS.md](AGENTS.md) - Multi-agent guidelines
