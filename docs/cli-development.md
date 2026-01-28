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
│   │   └── completion.sh          # myapp completion
│   ├── config/
│   │   ├── config.yaml            # Base configuration
│   │   └── config-dev.yaml        # Environment overrides
│   ├── libs/                      # Project-specific libraries
│   └── vars/
│       └── constants.sh           # Version constants
├── packaging/                     # Distribution packaging
└── install.sh                     # Installer script
```

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

## User Libraries

The framework automatically loads user library files, eliminating the need for manual `source` commands.

### How It Works

Place `.sh` files in your project's `libs/` directory. The framework sources them automatically during bootstrap.

### Configuration

Set the library path via environment variable or YAML config:

**Environment Variable (recommended for CLI projects)**:

```bash
# In bin/myapp entry script (set before sourcing framework)
export GX_RADP_FW_USER_LIB_PATH="$SCRIPT_DIR/../src/main/shell/libs"
```

**YAML Configuration**:

```yaml
# config/config.yaml
radp:
  fw:
    user:
      lib:
        path: ${gr_fw_root_path}/../libs
```

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

| Issue                   | Cause                    | Solution                                                 |
|-------------------------|--------------------------|----------------------------------------------------------|
| Command not found       | Missing `@cmd` marker    | Add `# @cmd` to the command file                         |
| Option not working      | Wrong variable name      | Use `opt_<long_name>` (e.g., `opt_verbose`)              |
| Completion not updating | Cached completion script | Regenerate: `myapp completion bash > ...`                |
| Config not loading      | Wrong path or syntax     | Check YAML syntax and `GX_RADP_FW_USER_CONFIG_PATH`      |
| Library not loaded      | Path not set             | Set `GX_RADP_FW_USER_LIB_PATH` before sourcing framework |

### Debugging Tips

**Enable debug logging:**

```bash
GX_RADP_FW_LOG_DEBUG=true myapp hello
```

**Check command discovery:**

```bash
# List all discovered commands
myapp --help

# Check specific command metadata
myapp <command >--help
```

**Verify configuration:**

```bash
# Print all config variables
env | grep -E "^(gr_radp_|GX_RADP_)"
```

**Test completion functions:**

```bash
# Source the command file and test directly
source src/main/shell/commands/install.sh
_complete_packages
```

## Best Practices

1. **Keep commands focused** — One command per file, single responsibility
2. **Use meaningful descriptions** — `@desc` shown in help output
3. **Provide examples** — `@example` helps users understand usage
4. **Validate input early** — Check required config/args at command start
5. **Use framework logging** — `radp_log_info`, `radp_log_error` instead of `echo`
6. **Document configuration** — Comment what each config key does
7. **Handle errors gracefully** — Provide helpful error messages with context
8. **Write tests** — Use BATS for command and library testing
