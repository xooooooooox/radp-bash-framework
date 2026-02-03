# Multi-Agent Guidelines

This file provides guidance for AI agents working collaboratively on radp-bash-framework.

## Project Context

radp-bash-framework is a modular Bash framework for building CLI applications. It provides structured bootstrapping, configuration management, logging, and a comprehensive toolkit.

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | AI guidance for Claude Code |
| `src/main/shell/framework/init.sh` | Framework entry point |
| `src/main/shell/framework/bootstrap/` | Bootstrap and context loading |
| `src/main/shell/framework/bootstrap/context/libs/toolkit/` | Utility functions |
| `src/main/shell/commands/` | radp-bf CLI commands |
| `src/test/shell/` | BATS tests |

## Quick Commands

```bash
# Run tests
bats src/test/shell/

# Source framework
source src/main/shell/framework/init.sh

# Create CLI project
./bin/radp-bf new myapp
```

## Architecture Summary

```
init.sh → preflight (stage1: POSIX, stage2: Bash) → bootstrap → context
```

See [docs/developer/architecture.md](docs/developer/architecture.md) for details.

## Naming Conventions

| Pattern | Meaning |
|---------|---------|
| `gr_*` | Global readonly |
| `gw_*` | Global writable |
| `radp_*` | Public function |
| `__fw_*` | Internal function |

See [docs/developer/code-style.md](docs/developer/code-style.md) for full guidelines.

## Related Projects

- [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework) - YAML-driven Vagrant framework
- [homelabctl](https://github.com/xooooooooox/homelabctl) - Homelab infrastructure CLI

## Documentation

- [docs/index.md](docs/index.md) - Documentation index
- [docs/developer/architecture.md](docs/developer/architecture.md) - Architecture details
- [docs/developer/code-style.md](docs/developer/code-style.md) - Code style guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development and release process
