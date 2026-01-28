# radp-bash-framework

```
    ____  ___    ____  ____     ____  ___   _____ __  __
   / __ \/   |  / __ \/ __ \   / __ )/   | / ___// / / /
  / /_/ / /| | / / / / /_/ /  / __  / /| | \__ \/ /_/ /
 / _, _/ ___ |/ /_/ / ____/  / /_/ / ___ |___/ / __  /
/_/ |_/_/  |_/_____/_/      /_____/_/  |_/____/_/ /_/

```

[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/radp-bash-framework/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)
[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

A modular Bash framework for building CLI applications with structured bootstrapping, configuration management, and a
comprehensive toolkit.

## Features

- **CLI Scaffolding** - Generate complete CLI projects with `radp-bf new myapp`
- **Annotation-based Commands** - Define commands using comment metadata (`@cmd`, `@arg`, `@option`)
- **Auto-discovery** - Commands are discovered from directory structure, supports nested subcommands
- **Shell Completion** - Generate Bash/Zsh completion scripts automatically
- **YAML Configuration** - Layered config system with environment variable overrides
- **Logging** - Structured logging with levels (debug/info/warn/error)
- **OS Detection** - Cross-platform utilities for distro, architecture, package manager detection
- **Path Utilities** - File system helpers, path resolution
- **IDE Code Completion** - BashSupport Pro integration for framework function and variable completion

## Requirements

- Bash 4.3+
- [yq](https://github.com/mikefarah/yq) (for YAML parsing, auto-installed if missing)

## Installation

### Homebrew (macOS/Linux)

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### Script (curl)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

Install from a specific branch or tag:

```shell
bash install.sh --ref main
bash install.sh --ref v1.0.0-rc1
```

### RPM (Fedora/RHEL/CentOS)

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework
```

See [Installation Guide](docs/installation.md) for more options (OBS, manual install, upgrade).

### Load the Framework

After installation, load the framework in your shell:

```shell
source "$(radp-bf path init)"
```

Add this to `~/.bashrc` for automatic loading.

## Quick Start

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
│       └── config.yaml       # Configuration
└── install.sh                # Installer script
```

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

## Documentation

- [Installation Guide](docs/installation.md) - All installation methods and upgrade instructions
- [CLI Development Guide](docs/cli-development.md) - Complete guide to building CLI applications
- [Command Annotations](docs/annotations.md) - `@cmd`, `@arg`, `@option`, `@example` reference
- [Configuration](docs/configuration.md) - YAML config system and environment variables
- [API Reference](docs/api.md) - Toolkit functions and IDE integration

## Toolkit API

The framework provides utility functions organized by domain:

| Domain       | Functions                                            | Description           |
|--------------|------------------------------------------------------|-----------------------|
| `radp_log_*` | `debug`, `info`, `warn`, `error`                     | Structured logging    |
| `radp_os_*`  | `get_distro_id`, `get_distro_pm`, `is_pkg_installed` | OS detection          |
| `radp_io_*`  | `get_path_abs`                                       | File system utilities |
| `radp_cli_*` | `discover`, `dispatch`, `help`                       | CLI infrastructure    |

See [API Reference](docs/api.md) for complete documentation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and release process.

## License

[MIT](LICENSE)
