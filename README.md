# radp-bash-framework

```
    ____  ___    ____  ____     ____  ___   _____ __  __
   / __ \/   |  / __ \/ __ \   / __ )/   | / ___// / / /
  / /_/ / /| | / / / / /_/ /  / __  / /| | \__ \/ /_/ /
 / _, _/ ___ |/ /_/ / ____/  / /_/ / ___ |___/ / __  /
/_/ |_/_/  |_/_____/_/      /_____/_/  |_/____/_/ /_/

```

[![GitHub Release](https://img.shields.io/github/v/release/xooooooooox/radp-bash-framework?label=Release)](https://github.com/xooooooooox/radp-bash-framework/releases)
[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/radp-bash-framework/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)

[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

A modular Bash framework with two goals: **bring engineering practices to shell scripting** (structured bootstrapping,
configuration, logging, toolkit, code conventions) and **make it easy to build CLI applications** (scaffolding,
annotation-driven commands, auto-discovery, shell completion).

## Features

### Bash Engineering

- **Two-Stage Preflight + Bootstrap** - POSIX stage-1 validates Bash version; Bash stage-2 checks dependencies (
  `gnu-getopt`, `yq`); bootstrap wires everything together
- **YAML Configuration** - Layered config system (framework defaults → user config → environment variables) with
  automatic variable mapping
- **Logging** - Multi-level structured logging (`debug`/`info`/`warn`/`error`) with configurable format and output
- **Toolkit** - 7 domains, 40+ files, 60+ public functions: OS detection, dry-run execution, file I/O, network, YAML
  parsing, and more
- **IDE Support** - BashSupport Pro integration for framework function and variable completion

### Code Conventions

- **Variable Naming** - Scoped prefixes: `gr_*` (global readonly), `gw_*` (global writable), `gwxa_*` (global array)
- **Function Naming** - `radp_*` (public API), `radp_nr_*` (nameref), `__fw_*` (framework-internal)
- **POSIX vs Bash Layering** - Entry scripts and stage-1 preflight use POSIX; bootstrap and beyond use Bash features
- **ShellCheck Integration** - Annotations preserved throughout the codebase
- **Code Style** - 2-space indentation, quoted variables, `[[ ]]` over `[ ]` in Bash context

### CLI Development

- **CLI Scaffolding** - Generate complete CLI projects with `radp-bf new myapp`
- **CLI Scaffolding Upgrade** - Upgrade existing CLI projects to latest scaffold with `radp-bf upgrade`
- **Annotation-based Commands** - Define commands using comment metadata (`@cmd`, `@arg`, `@option`)
- **Auto-discovery** - Commands are discovered from directory structure, supports nested subcommands
- **Shell Completion** - Generate Bash/Zsh completion scripts automatically
- **Built-in Global Options** - `--config`, `--verbose`, `--debug` available for all CLI apps
- **Dev/Install Mode** - Automatic config path detection based on `_ide.sh` marker

## Requirements

- Bash 4.3+
- GNU getopt (for CLI argument parsing, auto-installed if missing)
  - Linux: included in `util-linux`
  - macOS: `brew install gnu-getopt`
- [yq](https://github.com/mikefarah/yq) (for YAML parsing, auto-installed if missing)

## Installation

### Homebrew (macOS)

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### Script (curl)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

### Portable Binary (Single File)

Download and run - no installation required:

```shell
# Standard version (~100KB) - macOS Apple Silicon
curl -fsSL -o radp-bf \
  https://github.com/xooooooooox/radp-bash-framework/releases/latest/download/radp-bf-portable-darwin-arm64
chmod +x radp-bf && sudo mv radp-bf /usr/local/bin/

# Full version (~20MB, zero dependencies) - macOS Apple Silicon
curl -fsSL -o radp-bf \
  https://github.com/xooooooooox/radp-bash-framework/releases/latest/download/radp-bf-portable-full-darwin-arm64
chmod +x radp-bf && sudo mv radp-bf /usr/local/bin/
```

Available platforms: `linux-amd64`, `linux-arm64`, `darwin-amd64`, `darwin-arm64`

See [Installation Guide](docs/installation.md) for more options (RPM, OBS, portable, manual install, upgrade).

## Quick Start

### Use as a Framework

Source `init.sh` to access the framework's engineering capabilities in any Bash script:

```bash
#!/usr/bin/env bash
source "$(radp-bf path init)"

# Logging
radp_log_info "Starting task..."
radp_log_debug "Debug details here"

# OS detection
distro=$(radp_os_get_distro_id)
arch=$(radp_os_get_distro_arch)
radp_log_info "Running on $distro ($arch)"

# YAML configuration (from your config.yaml)
echo "API URL: $gr_radp_extend_myapp_api_url"

# Dry-run mode
radp_set_dry_run "${DRY_RUN:-}"
radp_exec "Install package" apt-get install -y nginx
```

### Create a CLI Project

```shell
radp-bf new myapp
cd myapp
./bin/myapp --help
```

This generates:

```
myapp/
├── bin/myapp                 # Entry point
├── src/main/shell/
│   ├── commands/             # Command implementations
│   │   ├── hello.sh          # myapp hello
│   │   └── version.sh        # myapp version
│   └── config/
│       ├── config.yaml       # Configuration
│       └── _ide.sh           # IDE support & dev mode marker
├── .radp-cli/                # Scaffold metadata (for upgrade)
└── install.sh                # Installer script
```

### Upgrade Existing Projects

When the framework updates, upgrade your project's scaffold files:

```shell
radp-bf upgrade # Upgrade current directory
radp-bf upgrade ./myapp --dry-run # Preview changes
radp-bf upgrade --force # Overwrite modified files
radp-bf -v upgrade . # Upgrade with verbose output
```

The upgrade command tracks changes via `.radp-cli/` metadata directory and detects user modifications.

See [Upgrade CLI Projects](docs/installation.md#upgrade-cli-projects) for more options.

### Define Commands

Commands use annotation-based metadata:

```bash
# src/main/shell/commands/greet.sh

# @cmd
# @desc Greet someone
# @arg name!              Required argument
# @option -l, --loud      Shout the greeting

cmd_greet() {
  local name="$1"
  local msg="Hello, $name!"

  if [[ "${opt_loud:-}" == "true" ]]; then
    echo "${msg^^}"
  else
    echo "$msg"
  fi
}
```

```shell
$ myapp greet World
Hello, World!

$ myapp greet --loud World
HELLO, WORLD!
```

### Subcommands

Create directories for command groups:

```
commands/
├── db/
│   ├── migrate.sh    # myapp db migrate
│   └── seed.sh       # myapp db seed
└── hello.sh          # myapp hello
```

### Configuration

YAML configuration with automatic variable mapping:

```yaml
# config/config.yaml
radp:
  extend:
    myapp:
      api_url: https://api.example.com
```

Access in code:

```bash
echo "$gr_radp_extend_myapp_api_url" # https://api.example.com
```

Override via environment:

```shell
GX_RADP_EXTEND_MYAPP_API_URL=http://localhost:8080 myapp hello
```

### Shell Completion

```shell
# Bash
myapp completion bash >~/.local/share/bash-completion/completions/myapp

# Zsh
myapp completion zsh >~/.zfunc/_myapp
```

## Code Conventions

The framework establishes naming conventions to keep shell projects consistent and readable.

### Variable Naming

| Prefix   | Scope           | Example                   |
|----------|-----------------|---------------------------|
| `gr_*`   | Global readonly | `gr_fw_root_path`         |
| `gw_*`   | Global writable | `gw_fw_run_initialized`   |
| `gwxa_*` | Global array    | `gwxa_fw_sourced_scripts` |

CLI commands also use `opt_*`, `args_*`, and `gopt_*` variables (auto-generated from annotations).

### Function Naming

| Pattern       | Meaning                               | Example                    |
|---------------|---------------------------------------|----------------------------|
| `radp_*`      | Public API                            | `radp_log_info`            |
| `radp_nr_*`   | Nameref (caller passes variable name) | `radp_nr_arr_merge_unique` |
| `radp_*_is_*` | Boolean predicate (returns 0/1)       | `radp_os_is_pkg_installed` |
| `__fw_*`      | Framework-internal (not for users)    | `__fw_bootstrap`           |

See [Code Style Guide](docs/developer/code-style.md) for the full specification.

## radp-bf CLI

The `radp-bf` command-line tool manages framework operations:

```shell
radp-bf new <name >[dir] # Create new CLI project
radp-bf upgrade [dir] [opts] # Upgrade existing project scaffold
radp-bf path <name> # Print framework paths (init|launcher|root)
radp-bf completion <shell> # Generate shell completion (bash|zsh)
radp-bf upgrade # Upgrade to the latest version
radp-bf version # Show framework version
```

**Global options** (for any command):

```shell
radp-bf -v upgrade . # Verbose output (info logs)
radp-bf --debug upgrade . # Debug output (debug logs)
```

**Shell completion for radp-bf:**

```shell
# Bash
radp-bf completion bash >~/.local/share/bash-completion/completions/radp-bf

# Zsh
radp-bf completion zsh >~/.zfunc/_radp-bf
```

## Documentation

- [Installation Guide](docs/installation.md) - All installation methods and upgrade instructions
- [Getting Started](docs/getting-started.md) - Create your first CLI project
- [CLI Development Guide](docs/user-guide/cli-development.md) - Complete guide to building CLI applications
- [Command Annotations](docs/user-guide/annotations.md) - `@cmd`, `@arg`, `@option`, `@example` reference
- [Configuration](docs/configuration.md) - YAML config system and environment variables
- [API Reference](docs/reference/api.md) - Toolkit functions and IDE integration
- [Code Style Guide](docs/developer/code-style.md) - Variable/function naming, POSIX vs Bash layering, ShellCheck

## Toolkit API

The framework provides 60+ public functions organized by domain:

| Domain        | Key Functions                                                                                                                          | Description                                            |
|---------------|----------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------|
| `radp_log_*`  | `debug`, `info`, `warn`, `error`                                                                                                       | Structured logging                                     |
| `radp_os_*`   | `get_distro_id`, `get_distro_pm`, `get_distro_arch`, `is_pkg_installed`, `install_pkgs`, `disable_swap`, `sysctl_configure_persistent` | OS detection, package management, system configuration |
| `radp_io_*`   | `get_path_abs`, `download`, `extract`, `mktemp_dir`, `yaml_get_value`, `prompt_confirm`                                                | File I/O, downloads, YAML parsing                      |
| `radp_exec_*` | `exec`, `exec_sudo`, `set_dry_run`, `is_dry_run`, `retry`, `wait_until`                                                                | Command execution with dry-run support                 |
| `radp_net_*`  | `github_download_asset`, `github_latest_release`                                                                                       | Network and GitHub API utilities                       |
| `radp_cli_*`  | `discover`, `dispatch`, `help`, `parse_args`, `scaffold_new`, `upgrade`                                                                | CLI infrastructure                                     |
| `radp_core_*` | `get_fw_install_version`, `nr_arr_merge_unique`                                                                                        | Core utilities and array operations                    |
| `radp_ide_*`  | `ide_init`, `ide_add_commands_dir`                                                                                                     | IDE code completion support                            |

See [API Reference](docs/reference/api.md) for complete documentation.

## Related Projects

- [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework) - YAML-driven Vagrant framework
- [homelabctl](https://github.com/xooooooooox/homelabctl) - Homelab infrastructure CLI

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and release process.

## License

[MIT](LICENSE)
