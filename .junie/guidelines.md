# Repository Guidelines

This repository contains `radp-bash-framework`, a modular Bash framework.

## Project Structure

- `src/main/shell/framework/` — framework source code
    - `run.sh` — main entrypoint (sets paths, runs `preflight`, then `bootstrap`) and is idempotent via
      `gw_fw_run_initialized`.
    - `preflight/` — environment + dependency checks
        - `requirements/` — individual requirement checks (e.g. `require_bash.sh`, `require_yq.sh`).
    - `bootstrap/` — builds the runtime context by sourcing scripts
        - `bootstrap/bootstrap.sh` — sources context scripts and records what was sourced in `gwxa_fw_sourced_scripts`.
        - `bootstrap/context/` — framework context assembly
            - `context.sh` — central context loader (sourced by bootstrap)
            - `libs/` — internal libraries (e.g. logger)
            - `vars/` — global/constants/configurable/dynamic/runtime variables
- `src/main/shell/config/` — example/default user configuration YAMLs
- `src/main/shell/extend/` — extension entrypoints (e.g. completion)

### Sourcing & load order

- The bootstrap helper `__fw_source_scripts` supports sourcing either a single `.sh` file or all `.sh` files in a
  directory.
- When sourcing a directory, scripts are sorted by filename using an underscore delimiter and numeric prefix (see
  `find ... | sort -t '_' -k 1,1n`).
    - Prefer naming like `1_feature.sh`, `2_other_feature.sh` when deterministic order matters.

## Coding Style & Naming Conventions

### Shell dialect and safety

- Prefer Bash and follow the repository’s existing strictness:
    - Many scripts use `set -e` or `set -euo pipefail`.
    - Quote variables unless you intentionally want word splitting / globbing.
- Keep compatibility constraints in mind:
    - Per `src/main/shell/framework/run.sh`, the entry scripts (`bootstrap.sh` and `preflight/*.sh`) should use
      POSIX-compatible syntax as much as possible for portability.

### Naming conventions seen in this repo

- Framework private/internal functions commonly use a double-underscore prefix (e.g. `__fw_bootstrap_context`,
  `__fw_source_scripts`).
- Global variables tend to be prefixed:
    - `gr_...` — global readonly-ish paths/config (e.g. `gr_fw_root_path`)
    - `gw_...` — global writable state/flags (e.g. `gw_fw_run_initialized`)
    - `gwxa_...` — global arrays (e.g. `gwxa_fw_sourced_scripts`)
- Prefer `local` for function scope variables.

### Linting / quality

- Preserve and extend existing ShellCheck annotations (e.g. `# shellcheck source=...`, `# shellcheck disable=...`) when
  adding new `source`/`.` calls.
- Prefer using the existing logger functions (e.g. `radp_log_error`) rather than ad-hoc `echo` for errors.

## IDE (JetBrains) & BashSupport Pro

This repo is developed with JetBrains IDEs (IntelliJ IDEA / GoLand / PyCharm, etc.) using the **BashSupport Pro**
plugin.
The framework uses a lot of `source` to compose runtime context, so IDE configuration matters for navigation and
completion.

### Interpreter / Bash version

- Many framework scripts are `#!/usr/bin/env bash` and use Bash features such as `[[ ... ]]`, arrays, and `mapfile`.
- Some entry scripts are intentionally written in POSIX `sh` for portability (see `src/main/shell/framework/run.sh` and
  `src/main/shell/framework/preflight/*.sh`).
- In your JetBrains settings, point BashSupport Pro to the Bash interpreter you actually run with.

### Sourced files navigation / code completion

BashSupport Pro can resolve symbols across sourced files, but it cannot always infer dynamic `source` paths (e.g.
`source "$gr_fw_bootstrap_path"/bootstrap.sh`).
This repo uses a dedicated “hint” function to make IDE navigation and completion work reliably:

- See `src/main/shell/framework/bootstrap/context/context.sh` → `__fw_context_setup_code_completion()`.
    - It contains `# shellcheck source=...` lines for files that are sourced at runtime.
    - The function body is a no-op (`:`) and must remain side-effect free.
- When you add/remove important sourced scripts (especially for completion entrypoints), update these
  `# shellcheck source=...` hints.
- When adding `source` calls with computed paths, keep the nearest `# shellcheck source=...` annotation so both
  ShellCheck and the IDE can resolve the target.
    - Reference: https://www.bashsupport.com/manual/navigation/sourced-files/

### Run/Debug in JetBrains

- Prefer running the framework via `src/main/shell/framework/run.sh`.
- When creating a Run Configuration:
    - Script: `src/main/shell/framework/run.sh`
    - Working directory: repository root (so relative paths in configs/scripts remain stable)
    - Environment: set only what you need; keep runs reproducible

## Testing

- Tests live under `src/test/shell/` and use the `bats` testing framework.
  Reference: https://www.bashsupport.com/bats-core/
- Prefer fast, hermetic tests:
    - Avoid network calls and reliance on the host environment.
    - Use temp directories (e.g. `mktemp -d`) and clean up after each test.
- Cover:
    - Happy path (expected inputs)
    - Error path (missing deps, invalid config, non-zero exit)
    - Edge cases (empty values, whitespace, special characters)
- Define cases with `@test "..." { ... }` and use `setup`/`teardown` when helpful.
- Typical runs:
    - `bats test/shell`
    - `bats test/shell/<file>.bats`
- Keep tests file.
