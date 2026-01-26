# Contributing

## Development Setup

1. Clone the repository:

```shell
git clone https://github.com/xooooooooox/radp-bash-framework.git
cd radp-bash-framework
```

2. Source the framework directly:

```shell
source src/main/shell/framework/run.sh
```

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core).

```shell
# Run all tests
bats src/test/shell/

# Run specific test file
bats src/test/shell/toolkit_core.bats

# Run with verbose output
bats --verbose-run src/test/shell/toolkit_core.bats
```

See [src/test/shell/README.md](src/test/shell/README.md) for writing new tests.

## Code Style

- Entry scripts (`run.sh`, `preflight/*.sh`) use POSIX-compatible syntax
- Bootstrap and beyond use Bash features (`[[ ]]`, arrays, `mapfile`)
- Quote variables unless intentional word splitting
- Use `radp_log_*` functions instead of ad-hoc `echo` for output

### Naming Conventions

**Variables:**

| Prefix   | Scope           | Example                   |
|----------|-----------------|---------------------------|
| `gr_*`   | Global readonly | `gr_fw_root_path`         |
| `gw_*`   | Global writable | `gw_fw_run_initialized`   |
| `gwxa_*` | Global array    | `gwxa_fw_sourced_scripts` |

**Functions:**

| Pattern              | Meaning                 | Example                    |
|----------------------|-------------------------|----------------------------|
| `radp_*`             | Public API              | `radp_log_info`            |
| `radp_nr_*`          | Nameref (pass var name) | `radp_nr_arr_merge_unique` |
| `*_is_*` / `*_has_*` | Boolean (returns 0/1)   | `radp_app_is_help_request` |
| `__fw_*`             | Private/internal        | `__fw_bootstrap`           |

## Release Process

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
       │              │
       └──────┬───────┘
              ▼
  attach-release-packages
```

### 1. Prepare Release

Trigger `release-prep` workflow with `bump_type` (patch/minor/major/manual):

- Creates branch `workflow/vX.Y.Z`
- Updates `gr_fw_version`
- Syncs spec versions
- Inserts changelog entry
- Opens PR for review

### 2. Review and Merge

Edit changelog in PR, then merge to `main`.

### 3. Create Tag

`create-version-tag` runs automatically on merge:

- Validates version, changelog, spec versions
- Creates and pushes git tag

### 4. Build Packages

Tag triggers:

- `update-homebrew-tap` - Updates Homebrew formula
- `update-spec-version` - Updates spec Version field
- `build-copr-package` - Triggers COPR SCM build
- `build-obs-package` - Syncs to OBS and triggers build

### 5. Attach Assets

`attach-release-packages` downloads built packages from COPR/OBS and uploads to GitHub Release.

## GitHub Actions Reference

| Workflow                      | Trigger            | Purpose                      |
|-------------------------------|--------------------|------------------------------|
| `release-prep.yml`            | Manual on `main`   | Create release branch and PR |
| `create-version-tag.yml`      | PR merge or manual | Validate and create git tag  |
| `update-spec-version.yml`     | After tag creation | Update spec Version field    |
| `build-copr-package.yml`      | After spec update  | Trigger COPR build           |
| `build-obs-package.yml`       | After spec update  | Sync to OBS and build        |
| `update-homebrew-tap.yml`     | Tag push           | Update Homebrew formula      |
| `attach-release-packages.yml` | Release published  | Upload packages to release   |
