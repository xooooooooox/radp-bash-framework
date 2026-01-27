# example-cli

A CLI tool built with [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework).

## Prerequisites

radp-bash-framework must be installed:

```bash
brew tap xooooooooox/radp
brew install radp-bash-framework
```

Or see: https://github.com/xooooooooox/radp-bash-framework#installation

## Installation

### Script (curl / wget)

```bash
curl -fsSL https://raw.githubusercontent.com/xooooooooox/example-cli/main/install.sh | bash
```

### Homebrew

```bash
brew tap xooooooooox/radp
brew install example-cli
```

### RPM (COPR)

```bash
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y example-cli
```

### From source

```bash
git clone https://github.com/xooooooooox/example-cli
cd example-cli
./bin/example-cli --help
```

## Usage

```bash
# Show help
example-cli --help

# Show version
example-cli version

# Example command
example-cli hello World

# Generate shell completion
example-cli completion bash > ~/.local/share/bash-completion/completions/example-cli
example-cli completion zsh > ~/.zfunc/_example-cli

# Verbose mode (show banner and info logs)
example-cli -v hello World
example-cli --verbose version

# Debug mode (show banner and debug logs)
example-cli --debug hello World
```

## Global Options

| Option | Description |
|--------|-------------|
| `-v`, `--verbose` | Enable verbose output (banner + info logs) |
| `--debug` | Enable debug output (banner + debug logs) |
| `-h`, `--help` | Show help |
| `--version` | Show version |

By default, the CLI runs in quiet mode (no banner, only error logs).

## Configuration

This project uses radp-bash-framework's YAML configuration system.

### Configuration Files

```
src/main/shell/config/
├── config.yaml          # Base configuration
└── config-dev.yaml      # Development environment overrides
```

### Configuration Structure

```yaml
radp:
  env: default           # Environment name (loads config-{env}.yaml)

  fw:                    # Framework settings
    banner-mode: on
    log:
      debug: false
      level: info

  extend:                # Application-specific settings
    example_cli:
      version: v0.1.0
      # Your custom config here
```

### Accessing Config in Code

Variables from `radp.extend.*` are available as `gr_radp_extend_*`:

```bash
# radp.extend.example_cli.version -> gr_radp_extend_example_cli_version
echo "$gr_radp_extend_example_cli_version"
```

### Environment Variables

Override any config with `GX_*` prefix:

```bash
GX_RADP_FW_LOG_DEBUG=true example-cli hello
```

## Adding Commands

Create new command files in `src/main/shell/commands/`:

```bash
# src/main/shell/commands/mycommand.sh

# @cmd
# @desc My command description
# @arg name! Required argument
# @option -u, --uppercase Convert output to uppercase
# @example mycommand foo
# @example mycommand --uppercase bar

cmd_mycommand() {
    local name="$1"

    if [[ "${opt_verbose:-}" == "true" ]]; then
        echo "Running in verbose mode"
    fi

    echo "Hello, $name!"
}
```

### Subcommands

Create a directory for subcommand groups:

```
src/main/shell/commands/
├── mygroup/
│   ├── create.sh    # example-cli mygroup create
│   └── delete.sh    # example-cli mygroup delete
└── hello.sh         # example-cli hello
```

## CI/CD

This project includes GitHub Actions workflows for automated releases.

### Workflow Chain

```
release-prep (manual trigger)
       │
       ▼
   PR merged
       │
       ▼
create-version-tag
       │
       ├──────────────────────┬──────────────────────┐
       ▼                      ▼                      ▼
update-spec-version    update-homebrew-tap    (GitHub Release)
       │
       ├──────────────┐
       ▼              ▼
build-copr-package  build-obs-package
```

### Release Process

1. Trigger `release-prep` workflow with bump_type (patch/minor/major/manual)
2. Review and merge the generated PR
3. Subsequent workflows run automatically

### Required Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

#### Homebrew Tap (required for `update-homebrew-tap`)

| Secret | Description |
|--------|-------------|
| `HOMEBREW_TAP_TOKEN` | GitHub Personal Access Token with `repo` scope for homebrew-radp repository |

#### COPR (required for `build-copr-package`)

| Secret | Description |
|--------|-------------|
| `COPR_LOGIN` | COPR API login (from <https://copr.fedorainfracloud.org/api/>) |
| `COPR_TOKEN` | COPR API token |
| `COPR_USERNAME` | COPR username |
| `COPR_PROJECT` | COPR project name (e.g., `radp`) |

#### OBS (required for `build-obs-package`)

| Secret | Description |
|--------|-------------|
| `OBS_USERNAME` | OBS username |
| `OBS_PASSWORD` | OBS password or API token |
| `OBS_PROJECT` | OBS project name |
| `OBS_PACKAGE` | OBS package name |
| `OBS_API_URL` | (Optional) OBS API URL, defaults to `https://api.opensuse.org` |

### Skipping Workflows

If you don't need certain distribution channels:
- Delete the corresponding workflow file from `.github/workflows/`
- Or leave secrets unconfigured (workflow will skip with missing secrets)

## License

MIT
