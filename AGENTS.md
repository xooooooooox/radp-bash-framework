# Multi-Agent Guidelines

radp-bash-framework is a modular Bash framework for building CLI applications.

## Primary Reference

See [CLAUDE.md](CLAUDE.md) for complete AI guidance — project overview, architecture, naming
conventions, commands, and code style.

## Quick Commands

```bash
bats src/test/shell/              # Run all tests
source src/main/shell/framework/init.sh  # Source framework
./bin/radp-bf new myapp           # Create CLI project
```

## Architecture (one-liner)

`init.sh → preflight (stage1: POSIX, stage2: Bash) → bootstrap → context`

## Documentation

- [docs/developer/architecture.md](docs/developer/architecture.md) — Architecture details
- [docs/developer/code-style.md](docs/developer/code-style.md) — Code style guide (SSOT for naming conventions)
- [docs/reference/api.md](docs/reference/api.md) — Complete API reference
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development setup and release process
