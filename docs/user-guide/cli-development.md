# CLI Development Guide

Complete guide to building CLI applications with radp-bash-framework.

## Quick Start

### Create a New Project

```bash
radp-bf new myapp
cd myapp
./bin/myapp --help
```

### Project Structure

```
myapp/
├── bin/myapp                      # CLI entry point
├── src/main/shell/
│   ├── commands/                  # Command implementations
│   │   ├── hello.sh               # myapp hello
│   │   ├── version.sh             # myapp version
│   │   └── completion.sh          # myapp completion (shell completion)
│   ├── config/
│   │   ├── config.yaml            # Base configuration
│   │   ├── config-dev.yaml        # Environment overrides
│   │   ├── _ide.sh                # IDE support & dev mode marker
│   │   └── _idecomp.sh            # Auto-generated IDE completion (in .gitignore)
│   └── libs/                      # Project-specific libraries
├── .radp-cli/                     # Scaffold metadata (for upgrade)
│   ├── version                    # Framework version when created
│   ├── name                       # Project name
│   └── checksums/                 # File checksums for modification detection
├── packaging/                     # Distribution packaging
└── install.sh                     # Installer script
```

### Upgrading Projects

When the framework updates, you can upgrade your project's scaffold files:

```bash
# Preview changes without applying
radp-bf upgrade --dry-run

# Upgrade current directory
radp-bf upgrade

# Upgrade specific project
radp-bf upgrade ./myapp

# Show file differences
radp-bf upgrade --diff

# Force overwrite modified files
radp-bf upgrade --force

# Upgrade specific components only
radp-bf upgrade entry ide
```

**Upgradable components:**

| Component   | Files                                | Description                                    |
|-------------|--------------------------------------|------------------------------------------------|
| `entry`     | `bin/<name>`                         | Entry script                                   |
| `ide`       | `src/main/shell/config/_ide.sh`      | IDE support file                               |
| `gitignore` | `.gitignore`                         | Git ignore patterns                            |
| `version`   | `src/main/shell/commands/version.sh` | Migrate version from config.yaml to version.sh |
| `workflows` | `.github/workflows/*.yml`            | GitHub Actions CI/CD workflows (8 files)       |

The upgrade command detects user modifications and skips those files unless `--force` is specified.

## Defining Commands

Commands use annotation-based metadata in `.sh` files under `commands/`.

### Basic Command

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

### Annotations Reference

| Annotation             | Description                     | Example                         |
|------------------------|---------------------------------|---------------------------------|
| `@cmd`                 | Mark file as command (required) | `# @cmd`                        |
| `@desc`                | Command description             | `# @desc Greet the user`        |
| `@arg name`            | Optional positional argument    | `# @arg name`                   |
| `@arg name!`           | Required positional argument    | `# @arg name!`                  |
| `@arg items~`          | Variadic argument (multiple)    | `# @arg files~`                 |
| `@option -s, --short`  | Boolean flag                    | `# @option -v, --verbose`       |
| `@option --name <val>` | Option with value               | `# @option --config <file>`     |
| `@example`             | Usage example                   | `# @example greet World`        |
| `@complete`            | Dynamic completion              | `# @complete name _complete_fn` |
| `@meta passthrough`    | Skip argument parsing           | `# @meta passthrough`           |

See [Command Annotations](annotations.md) for complete reference.

## Application Global Options

Application-level global options are options that are available to all commands in your CLI. Unlike command-specific
options (defined with `@option`), global options are defined once and automatically available everywhere.

### Defining Global Options

Create a `_globals.sh` file in your `commands/` directory:

```bash
# src/main/shell/commands/_globals.sh

#!/usr/bin/env bash
# Application-level global options
# These options are available to all commands

# @global -c, --config <dir> Configuration directory
# @global -e, --env <name> Environment name [default: local]
# @global -v, --verbose Enable verbose output
```

### Syntax

The `@global` annotation uses the same syntax as `@option`:

| Annotation                              | Description               | Variable       |
|-----------------------------------------|---------------------------|----------------|
| `@global -v, --verbose`                 | Boolean flag              | `gopt_verbose` |
| `@global --config <dir>`                | Option with value         | `gopt_config`  |
| `@global -e, --env <name>`              | Short and long with value | `gopt_env`     |
| `@global --timeout <sec> [default: 30]` | With default value        | `gopt_timeout` |

### Variable Naming

Global options use the `gopt_` prefix (not `opt_`):

```bash
# In any command file
cmd_list() {
  # Access global options
  local config_dir="${gopt_config:-}"
  local env="${gopt_env:-local}"

  # Access command-specific options
  local verbose="${opt_verbose:-false}"

  # ...
}
```

### Option Placement

Global options can be placed before or after the command:

```bash
# Before command
myapp -c /path/to/config list
myapp --config /path/to/config --env prod list

# After command
myapp list -c /path/to/config
myapp list --config /path/to/config --env prod

# Mixed (both work)
myapp -c /path list --env prod
```

### Help Display

Global options appear in the help output:

```
$ myapp --help

Usage: myapp <command> [options]

Commands:
  list        List available items
  install     Install a package
  version     Show version

Global Options:
  -c, --config <dir>    Configuration directory
  -e, --env <name>      Environment name [default: local]

Options:
  -h, --help            Show help
  -v, --verbose         Verbose output
  --debug               Debug output
```

### Use Cases

Common use cases for application global options:

1. **Configuration directory** — Override default config location
2. **Environment selection** — Switch between dev/staging/prod
3. **Output format** — JSON/YAML/text output
4. **Target selection** — Specify target host/cluster

### Example

```bash
# commands/_globals.sh
#!/usr/bin/env bash
# @global -c, --config <dir> Configuration directory
# @global -e, --env <name> Environment name [default: local]

# commands/list.sh
# @cmd
# @desc List available items
# @option -a, --all Show all items

cmd_list() {
  local show_all="${opt_all:-false}"

  # Use global options
  local config_dir="${gopt_config:-$HOME/.config/myapp}"
  local env="${gopt_env:-local}"

  echo "Config: $config_dir"
  echo "Environment: $env"

  # ... list logic using config_dir and env
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
│   └── _common.sh        # Shared helper (not a command)
└── vf/
    ├── init.sh           # myapp vf init
    └── template/
        ├── list.sh       # myapp vf template list
        └── show.sh       # myapp vf template show
```

### Function Naming Convention

| File Path                      | Function Name            | Invocation               |
|--------------------------------|--------------------------|--------------------------|
| `commands/hello.sh`            | `cmd_hello()`            | `myapp hello`            |
| `commands/db/migrate.sh`       | `cmd_db_migrate()`       | `myapp db migrate`       |
| `commands/vf/template/list.sh` | `cmd_vf_template_list()` | `myapp vf template list` |

### Internal Helper Files

Use `_`-prefixed files for shared logic (not discovered as commands):

```bash
# commands/db/_common.sh - shared DB utilities
db_connect() {
  # ... connection logic
}
```

```bash
# commands/db/migrate.sh
# @cmd

source "${BASH_SOURCE[0]%/*}/_common.sh"

cmd_db_migrate() {
  db_connect
  # ...
}
```

## Configuration

### YAML Configuration

```yaml
# config/config.yaml
radp:
  extend:
    myapp:
      api_url: https://api.example.com
      timeout: 30
```

Access in code:

```bash
echo "$gr_radp_extend_myapp_api_url" # https://api.example.com
```

Override via environment:

```bash
GX_RADP_EXTEND_MYAPP_API_URL=http://localhost:8080 myapp hello
```

See [Configuration](configuration.md) for complete reference.

### Version Management

The application version is defined in `commands/version.sh` as a single source of truth:

```bash
# src/main/shell/commands/version.sh

# @cmd
# @desc Show version information

# Application version - single source of truth
# Update this value when releasing a new version
declare -gr gr_app_version="v0.0.1"

cmd_version() {
  echo "myapp $(radp_get_install_version "${gr_app_version}")"
}
```

The CI workflows automatically update `gr_app_version` during releases. This design:

- Keeps version in version-controlled code
- Prevents accidental deletion (version.sh is a command file)
- Follows single responsibility principle

## User Libraries

The framework automatically loads user library files, eliminating the need for manual `source` commands.

### How It Works

Place `.sh` files in your project's `libs/` directory. For scaffold projects, the framework automatically detects and
loads them - no configuration needed.

### Automatic Detection (Scaffold Projects)

For projects created with `radp-bf new`, the framework automatically:

- Detects `$RADP_APP_ROOT/src/main/shell/libs` directory
- Adds it to the library search paths
- Sources all `.sh` files during bootstrap

No manual configuration required!

### Manual Configuration (Non-Scaffold Projects)

For custom setups, configure library paths via YAML or environment variable:

**YAML Configuration (recommended)**:

```yaml
# config/config.yaml
radp:
  fw:
    user:
      lib:
        paths:
          - /path/to/libs1
          - /path/to/libs2
```

**Environment Variable**:

```bash
# Colon-separated paths (like PATH)
export GX_RADP_FW_USER_LIB_PATHS="/path/to/libs1:/path/to/libs2"
```

Note: When both are set, paths are merged (union), not overwritten.

### Loading Order

Files are sorted by numeric prefix in their filename:

```
libs/
├── 01_init.sh        # Loaded first
├── 02_helpers.sh     # Loaded second
├── 10_api_client.sh  # Loaded third
└── utils.sh          # Loaded last (no prefix = 999999)
```

### Example

```bash
# libs/01_db.sh
db_connect() {
  local host="${gr_radp_extend_myapp_db_host}"
  # ... connection logic
}

db_query() {
  # ... query logic
}
```

```bash
# commands/migrate.sh
# @cmd
# @desc Run database migrations

cmd_migrate() {
  db_connect # Available automatically - no source needed!
  db_query "SELECT * FROM migrations"
}
```

### Debugging

Enable debug logging to see which libraries are loaded:

**Option 1: Command-line flag (recommended)**:

```bash
myapp --debug --help
```

**Option 2: YAML configuration**:

```yaml
# config/config.yaml
radp:
  fw:
    log:
      debug: true
```

**Option 3: Environment variable**:

```bash
GX_RADP_FW_LOG_DEBUG=true myapp --help
```

Output shows:

```
[DEBUG] Sourced external user lib scripts:
[DEBUG]   - /path/to/libs/01_db.sh
[DEBUG]   - /path/to/libs/02_helpers.sh
```

### Best Practices

1. **Use numeric prefixes** for load order control (`01_`, `02_`, etc.)
2. **Group related functions** in single files
3. **Avoid circular dependencies** between library files
4. **Use framework logging** (`radp_log_*`) instead of `echo`

## Shell Completion

### Generate Completion Scripts

```bash
# Bash
myapp completion bash >~/.local/share/bash-completion/completions/myapp

# Zsh
myapp completion zsh >~/.zfunc/_myapp
```

### Dynamic Completion

The `@complete` annotation enables dynamic shell completion for arguments and options. Completion values are generated
at runtime by calling a shell function.

#### Basic Syntax

```bash
# @complete <name> <function>
```

- `name` — Argument name or option long name (without `--`)
- `function` — Shell function that outputs completion values (one per line)

#### Completing Arguments

```bash
# @cmd
# @desc Install a package
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

When user types `myapp install <TAB>`, the shell shows: `fzf bat jq`

#### Completing Options

```bash
# @cmd
# @desc Deploy to environment
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

When user types `myapp deploy --env <TAB>`, the shell shows: `development staging production`

#### Dynamic Data Sources

Completion functions can fetch data dynamically:

```bash
# @cmd
# @desc Switch git branch
# @arg branch! Branch name
# @complete branch _complete_branches

cmd_checkout() {
  git checkout "$1"
}

_complete_branches() {
  git branch --format='%(refname:short)' 2>/dev/null
}
```

```bash
# @cmd
# @desc Connect to server
# @arg host! Server hostname
# @complete host _complete_hosts

cmd_connect() {
  ssh "$1"
}

_complete_hosts() {
  # From SSH config
  grep -E "^Host " ~/.ssh/config 2>/dev/null | awk '{print $2}' | grep -v '*'
}
```

#### Multiple Completions

Commands can have multiple `@complete` annotations:

```bash
# @cmd
# @desc Copy file to remote
# @arg src! Source file
# @arg dest! Destination path
# @option -H, --host <name>  Target host
# @complete src _complete_local_files
# @complete dest _complete_remote_paths
# @complete host _complete_hosts

cmd_copy() {
  local src="$1"
  local dest="$2"
  scp "$src" "${opt_host}:$dest"
}

_complete_local_files() {
  compgen -f # Built-in file completion
}

_complete_remote_paths() {
  # Could query remote filesystem
  echo "/var/log/"
  echo "/tmp/"
  echo "/home/"
}

_complete_hosts() {
  echo "server1"
  echo "server2"
}
```

#### Where to Define Completion Functions

**Option 1: In the command file** (simple, self-contained)

```bash
# commands/install.sh
# @cmd
# @arg pkg!
# @complete pkg _complete_packages

cmd_install() {
  ... }

  _complete_packages() {
    echo "package1"
    echo "package2"
  }
```

**Option 2: In user libraries** (reusable across commands)

```bash
# libs/01_completions.sh
_complete_packages() {
  curl -s https://api.example.com/packages | jq -r '.[].name'
}

_complete_envs() {
  echo "dev"
  echo "staging"
  echo "prod"
}
```

```bash
# commands/install.sh
# @cmd
# @arg pkg!
# @complete pkg _complete_packages  # Function from libs/

cmd_install() { ... }
```

#### Debugging Completions

Test completion functions directly:

```bash
# Test the function output
_complete_packages

# Generate and inspect the completion script
myapp completion bash | grep -A20 "_complete_packages"
```

#### Best Practices

1. **Keep completions fast** — Users expect instant feedback; avoid slow operations
2. **Handle errors gracefully** — Use `2>/dev/null` to suppress errors
3. **One value per line** — Output format must be one completion per line
4. **Use caching for slow sources** — Cache API responses or expensive computations
5. **Prefix with underscore** — Convention: `_complete_*` or `_myapp_complete_*`

## IDE Integration

The framework supports code completion in JetBrains IDEs via BashSupport Pro.

### Setup

1. Install BashSupport Pro plugin
2. Run your CLI once: `myapp --help`
3. Open project in IDE - completion works automatically

See [API Reference - IDE Integration](api.md#ide-integration-radp_ide_) for details.

## Testing Commands

### Unit Testing with BATS

The framework uses [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for testing.

```bash
# test/commands/hello.bats

setup() {
  load '../test_helper'
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "hello command outputs greeting" {
  run "$PROJECT_ROOT/bin/myapp" hello World
  [ "$status" -eq 0 ]
  [[ "$output" == *"Hello, World!"* ]]
}

@test "hello --loud outputs uppercase" {
  run "$PROJECT_ROOT/bin/myapp" hello World --loud
  [ "$status" -eq 0 ]
  [[ "$output" == *"HELLO, WORLD!"* ]]
}

@test "hello without argument shows error" {
  run "$PROJECT_ROOT/bin/myapp" hello
  [ "$status" -ne 0 ]
}
```

### Running Tests

```bash
# Run all tests
bats test/

# Run specific test file
bats test/commands/hello.bats

# Verbose output
bats --verbose-run test/
```

### Test Directory Structure

```
myapp/
├── test/
│   ├── test_helper.bash      # Common test utilities
│   ├── commands/
│   │   ├── hello.bats        # Tests for hello command
│   │   └── db/
│   │       └── migrate.bats  # Tests for db migrate
│   └── libs/
│       └── utils.bats        # Tests for library functions
```

## Troubleshooting

### Common Issues

| Issue                   | Cause                     | Solution                                                       |
|-------------------------|---------------------------|----------------------------------------------------------------|
| Command not found       | Missing `@cmd` marker     | Add `# @cmd` to the command file                               |
| Option not working      | Wrong variable name       | Use `opt_<long_name>` (e.g., `opt_verbose`)                    |
| Completion not updating | Cached completion script  | Regenerate: `myapp completion bash > ...`                      |
| Config not loading      | Wrong path or syntax      | Run `myapp --show-config` to check paths; validate YAML syntax |
| Library not loaded      | libs/ directory not found | Ensure `src/main/shell/libs/` exists in project root           |

### Debugging Tips

**Enable debug logging** (choose one):

```bash
# Option 1: Command-line flag (recommended)
myapp --debug hello

# Option 2: YAML config (persistent)
# In config/config.yaml:
#   radp:
#     fw:
#       log:
#         debug: true

# Option 3: Environment variable
GX_RADP_FW_LOG_DEBUG=true myapp hello
```

**Check configuration and paths:**

```bash
# Show core configuration
myapp --show-config

# Include extension configurations
myapp --show-config --all

# JSON format for scripting
myapp --show-config --json
myapp --show-config --all --json
```

**Check command discovery:**

```bash
# List all discovered commands
myapp --help

# Check specific command metadata
myapp <command >--help
```

**Test completion functions:**

```bash
# Source the command file and test directly
source src/main/shell/commands/install.sh
_complete_packages
```

## CI/CD Workflows

Projects created with `radp-bf new` include GitHub Actions workflows for automated releases.

### Included Workflows

| Workflow                      | Trigger                   | Purpose                        |
|-------------------------------|---------------------------|--------------------------------|
| `release-prep.yml`            | Manual on `main`          | Create release branch and PR   |
| `create-version-tag.yml`      | PR merge or manual        | Validate and create git tag    |
| `update-spec-version.yml`     | After tag creation        | Update spec Version field      |
| `build-copr-package.yml`      | After spec update         | Trigger COPR build             |
| `build-obs-package.yml`       | After spec update         | Sync to OBS and build          |
| `update-homebrew-tap.yml`     | Tag push                  | Update Homebrew formula        |
| `attach-release-packages.yml` | After package builds      | Upload packages to release     |
| `cleanup-branches.yml`        | Weekly schedule or manual | Delete stale workflow branches |

### Release Process

1. **Trigger release-prep** — Choose bump type (patch/minor/major) and run workflow
2. **Review PR** — Edit auto-generated changelog, then merge to `main`
3. **Automatic flow** — Tag creation, package builds, and release publishing happen automatically

### Upgrading Workflows

When workflow templates are updated, upgrade your project:

```bash
# Preview workflow changes
radp-bf upgrade --diff workflows

# Apply workflow updates
radp-bf upgrade workflows

# Force overwrite modified workflows
radp-bf upgrade --force workflows
```

### Required Secrets

Configure these in GitHub repository settings:

| Secret               | Purpose                     |
|----------------------|-----------------------------|
| `COPR_LOGIN`         | COPR API login              |
| `COPR_TOKEN`         | COPR API token              |
| `COPR_USERNAME`      | COPR username               |
| `COPR_PROJECT`       | COPR project (user/project) |
| `OBS_USERNAME`       | OBS username                |
| `OBS_PASSWORD`       | OBS password                |
| `OBS_PROJECT`        | OBS project name            |
| `OBS_PACKAGE`        | OBS package name            |
| `HOMEBREW_TAP_TOKEN` | GitHub token for tap repo   |

## Best Practices

1. **Keep commands focused** — One command per file, single responsibility
2. **Use meaningful descriptions** — `@desc` shown in help output
3. **Provide examples** — `@example` helps users understand usage
4. **Validate input early** — Check required config/args at command start
5. **Use framework logging** — `radp_log_info`, `radp_log_error` instead of `echo`
6. **Document configuration** — Comment what each config key does
7. **Handle errors gracefully** — Provide helpful error messages with context
8. **Write tests** — Use BATS for command and library testing
