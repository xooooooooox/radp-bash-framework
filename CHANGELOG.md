# CHANGELOG

## v0.6.14

### feat

- Add `--config` global option to display application configuration
  - Shows paths, framework settings, and application extensions
  - Supports `--config --json` for JSON output
  - Available for all CLI applications built on radp-bash-framework
- Add dry-run mode support in exec toolkit (`04_dry_run.sh`)
  - `radp_set_dry_run()` - Enable/disable dry-run mode
  - `radp_is_dry_run()` - Check if dry-run mode is enabled
  - `radp_exec()` - Execute command or log in dry-run mode
  - `radp_exec_sudo()` - Execute with sudo or log in dry-run mode
  - `radp_dry_run_skip()` - Check and log for complex operations
- Add `radp_get_install_version()` helper function for accurate version display
- Add `radp_get_fw_install_version()` helper function for framework version
- Generate `.install-version` file during manual installation
- Add GNU getopt preflight check to ensure CLI works on macOS (BSD getopt incompatible)
  - Auto-detect and use GNU getopt path
  - Auto-install via Homebrew on macOS if missing
- Add post-uninstall note about user config directory
- Add `_ide.sh` as development mode marker for automatic config path detection
  - Development mode (source): uses `$RADP_APP_ROOT/src/main/shell/config`
  - Installed mode: uses `~/.config/$RADP_APP_NAME`
- Add `radp-bf upgrade` command to upgrade existing CLI projects
  - Supports `--dry-run`, `--force`, `--diff` options
  - Upgradable components: entry, ide, gitignore
  - Tracks scaffold version in `.radp-cli/` metadata
- Add `radp-bf completion` command to generate completion for Bash/Zsh.

### fix

- Fix CLI argument parsing fails on macOS due to BSD getopt
- Fix passthrough mode intercepting `--help` instead of passing to underlying command
- Fix preflight no such file or directory error
- Fix IDE code completion not work
- Fix radp_os_install_pkgs
- Fix auto-generated ide hints file error on install-mode

### refactor

- Refactor `radp-bf` CLI to unified subcommand style
  - Add `resolve-root <path>` command for entry script simplification
  - Change `--version` to `version` subcommand (keep alias)
  - Change `--help` to `help` subcommand (keep `-h`/`--help` aliases)
  - Remove `path` no-argument verbose output
- Simplify scaffold entry script from ~28 lines to ~12 lines using `resolve-root`
- Refactor preflight to two-stage architecture for better maintainability
  - Stage 1 (POSIX shell): bash check/install only
  - Stage 2 (Bash): other dependencies with cleaner bash syntax
- Refactor version mechanism
- Refactor run.sh to init.sh
- Refactor banner: separate ASCII art from version info with auto-alignment
- Rename IDE hints file from `completion.sh` to `_idecomp.sh`
- Support multiple user lib paths with union merge
- Scaffold: Move version from `vars/constants.sh` to `config/config.yaml` (`radp.extend.xxx.version`)
- Scaffold: Remove `vars` directory, add `config/_ide.sh` for IDE code completion support
- Scaffold: Update workflows to use `yq` for YAML version management
- Scaffold: Remove `_ide.sh` during installation (manual/rpm/deb/homebrew)

### chore

- Add post-install message
- Update install and uninstall

### docs

- Update installation
- Update CLI commands documentation

### test

- Update cli scaffold example

## v0.5.3

### feat

- Update cli scaffold default banner
- Optimize cli scaffold dynamic user config path
- Add cli example
- Update cli scaffold .gitignore
- Add example-cli
- Update cli scaffold config.yaml
- Add global option in cli help
- Consistence cli args

### fix

- Fix cli completions not work for zsh

### test

- Update cli scaffold example

## v0.4.28

### feat

- Support global option
- Support customize banner
- Refactor zsh completion to use wrapper functions for dynamic args/options
- Add passthrough mode support and `@meta` annotations
- Enhance IDE completion hints generation and command integration
- Add file transfer and GitHub API utility modules
- Improve subcommand matching and error handling
- Dynamically resolve cache path for system-wide installations
- Update cli generated scaffold
- Add package manager detection and installation support
- Add global option parsing for verbose and debug modes
- Add Homebrew support and improve scaffolding structure
- Add Homebrew formula for radp-bash-framework
- Distro libs optimize func radp_os_get_distro_pm and radp_os_install_pkgs
- Core libs add func radp_nr_arr_merge_unique
- Os libs add func radp_os_is_pkg_installed and radp_os_install_pkgs
- Optimize os libs func radp_os_get_distro_xx
- Add distro libs
- Optimize context completion
- Rename func to __fw_os_get_distro_info
- Dynamic vars add gr_distro_xx and add func radp_os_get_distro_info
- Remove pkg toolkit
- Add func radp_io_get_path_abs
- Optimize func __fw_source_scripts
- Create toolkit skeleton

### fix

- Fix default user config dir
- Fix dynamic completion not work
- Remove trailing backslash from last _arguments parameter in zsh completion
- Enhance completion logic with passthrough mode support
- Prevent potential errors in argument index increment
- Prevent loading external libraries if user lib path is unset
- Fix cli toolkit for subcmd group and shell completion not work well

### chore

- Optimize install.sh
- Update project dictionary to include "homelabctl"
- Add shebang to scaffolded command scripts

### docs

- Document passthrough mode with examples
- Update IDE integration details in CLAUDE.md
- Document IDE integration and completion hints
- Provide complete configuration reference with examples
- Expand CONTRIBUTING.md and annotations documentation
- Add detailed documentation for annotations, API, configuration, and installation
- Add CONTRIBUTING.md and restructure README files
- Add utility libraries and naming conventions sections
- Add CLI command discovery and nested command group documentation
- Improve installation guide and variable descriptions
- Add framework description to README and README_CN

### refactor

- Simplify user library path handling and improve scaffold initialization
- Reorganize IDE completion hints handling and improve modularity
- Improve argument handling and add empty input safeguards
- Update completion script paths for bash and zsh
- Improve scaffolding and completion script handling
- Enhance CLI scaffolding
- Consolidate and rewrite CLI framework modules

### test

- Add comprehensive test suite and helper utilities

## v0.3.6

### feat

- Optimize completion
- Support user completion
- Optimize func `__fw_source_scripts`
- Create toolkit skeleton
  - Add func `radp_io_get_path_abs`
  - Add func `radp_os_get_distro_xx`
  - Add func `radp_os_install_pkgs` and `radp_os_is_pkg_installed`
  - Add func `radp_nr_arr_merge_unique`
- Optimize logger
  - Add radp_log_raw func
  - Optimize banner print
  - Support disable/enable console log and logfile
  - Refactor log config var name, `radp.fw.log.file` to `radp.fw.log.file.name`

### fix

- Fix preflight_helper.sh no such file or directory
- Fix preflight not work well
- Fix failed to create user completion hint file
- Fix user custom config and lib completion not work

## v0.2.4

### chore

- Support multi install/upgrade method
- Add Github workflow
  - Support auto-update version and changelog before release
  - Support auto-create a valid tag
  - Support auto-build copr/obs package
  - Support auto-upload pre-built package to release assets
