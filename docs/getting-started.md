# Getting Started

This guide helps you create your first CLI application with radp-bash-framework.

## Prerequisites

- Bash 4.3+
- GNU getopt (auto-installed if missing)
- [yq](https://github.com/mikefarah/yq) (auto-installed if missing)

## Installation

### Homebrew (macOS)

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### Script Install

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

See [Installation Guide](./installation.md) for more options.

## Create Your First CLI

### 1. Generate a Project

```shell
radp-bf new myapp
cd myapp
./bin/myapp --help
```

This creates:

```
myapp/
├── bin/myapp                 # Entry point
├── src/main/shell/
│   ├── commands/             # Command implementations
│   │   ├── hello.sh          # myapp hello
│   │   └── version.sh        # myapp version
│   └── config/
│       ├── config.yaml       # Configuration
│       └── _ide.sh           # IDE support
├── .radp-cli/                # Scaffold metadata
└── install.sh                # Installer script
```

### 2. Add a Command

Create `src/main/shell/commands/greet.sh`:

```bash
# @cmd
# @desc Greet someone
# @arg name!              Required argument
# @flag -l, --loud        Shout the greeting

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

### 3. Run Your Command

```shell
$ ./bin/myapp greet World
Hello, World!

$ ./bin/myapp greet --loud World
HELLO, WORLD!
```

### 4. Add Subcommands

Create directories for command groups:

```
commands/
├── db/
│   ├── migrate.sh    # myapp db migrate
│   └── seed.sh       # myapp db seed
└── hello.sh          # myapp hello
```

### 5. Add Configuration

Edit `config/config.yaml`:

```yaml
radp:
  extend:
    myapp:
      api_url: https://api.example.com
```

Access in code:

```bash
echo "$gr_radp_extend_myapp_api_url"
```

## Next Steps

- [CLI Development Guide](./user-guide/cli-development.md) - Complete guide to building CLI applications
- [Command Annotations](./user-guide/annotations.md) - Full annotation reference
- [Configuration System](./configuration.md) - YAML configuration and environment variables
- [API Reference](./reference/api.md) - Toolkit functions
