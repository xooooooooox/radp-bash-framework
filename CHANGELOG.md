# CHANGELOG

## v0.7.18

### refactor

- Rename framework global option `--config` to `--show-config` to avoid conflicts with application-level `--config` options
- Refactor `radp-bf` CLI to standard command-based structure
  - Move command logic from case statements to individual command files in `commands/`
  - New structure: `src/main/shell/commands/{new,upgrade,path,resolve-root,completion,self-update,version}.sh`
  - Add `src/main/shell/config/config.yaml` for radp-bf specific configuration
  - Add `src/main/shell/config/_ide.sh` for IDE completion support
  - Use standard CLI dispatch: `radp_cli_set_commands_dir` + `radp_app_run`
  - Maintain fast path for `path` and `resolve-root` commands (handled before framework loading)
  - All commands, arguments, options, and output formats remain backward compatible
  - Update packaging scripts to include new `commands/` and `config/` directories:
    - `install.sh` - manual installation
    - `packaging/copr/radp-bash-framework.spec` - Fedora/RHEL RPM
    - `packaging/obs/radp-bash-framework.spec` - openSUSE/Debian packages
    - `packaging/binary/build-portable.sh` - portable binary build

### feat

- Add application-level global options support
  - Applications can define global options in `commands/_globals.sh` using `@global` annotations
  - Global options available as `gopt_<name>` variables (e.g., `gopt_config`, `gopt_env`)
  - Options can be placed before or after the command (`mycli -c /path list` or `mycli list -c /path`)
  - New CLI functions: `radp_cli_load_app_global_options()`, `radp_cli_parse_app_global_options()`, `radp_cli_extract_app_global_options()`
  - Help and completion systems updated to include application global options
- Add `globals` component to `upgrade` command to add `_globals.sh` to existing projects
- Add `_globals.sh` template to `new` scaffold command
- Add portable single-file executable build support
  - Standard version (~100KB): requires system bash 4.3+, gnu-getopt, yq
  - Full version (~20MB): bundled bash, gnu-getopt, yq - zero external dependencies
  - Supported platforms: linux-amd64, linux-arm64, darwin-amd64, darwin-arm64
  - Cache-based extraction to `~/.cache/radp-bf/` for fast subsequent runs
- Add `radp-bf self-update` command for portable installations
  - Check for updates: `radp-bf self-update --check`
  - Update to latest: `radp-bf self-update`
  - Force update: `radp-bf self-update --force`
  - Switch to full version: `radp-bf self-update --full`
- Add GitHub workflow for building portable binaries on release
- Skip dependency checks when using bundled deps (RADP_BF_BUNDLED_DEPS)
- Add IO module enhancements
  - `radp_io_append_line_unique()` - Append line to file with deduplication
  - `radp_io_prompt_confirm()` - Y/N confirmation prompt with timeout support
  - `radp_nr_io_prompt_input()` - Input prompt with nameref for user input
- Add YAML parsing module (`io/05_yaml.sh`)
  - `radp_io_yaml_get_value()` - Extract scalar value from YAML content
  - `radp_io_yaml_get_list()` - Extract list items from YAML content
  - `radp_io_yaml_get_section()` - Extract specific section from YAML
  - `radp_io_yaml_has_key()` - Check if key exists in YAML content
- Add OS security module (`02_security.sh`)
  - `radp_os_disable_selinux()` - Disable SELinux (permissive + config)
  - `radp_os_disable_firewalld()` - Stop and disable firewalld service
- Add OS resource module (`03_resource.sh`)
  - `radp_os_check_min_cpu_cores()` - Check minimum CPU cores requirement
  - `radp_os_check_min_ram()` - Check minimum RAM requirement (supports GB/MB)
  - `radp_os_get_total_ram_mb()` - Get total system RAM in MB
  - `radp_os_get_cpu_cores()` - Get CPU cores count
- Add sysctl management module (`os/04_sysctl.sh`)
  - `radp_os_sysctl_set()` - Set sysctl parameter temporarily
  - `radp_os_sysctl_check()` - Check if sysctl parameter has expected value
  - `radp_os_sysctl_configure_persistent()` - Configure sysctl parameters persistently
- Add cron management module (`07_cron.sh`)
  - `radp_os_crontab_add()` - Merge crontab file into user's crontab
  - `radp_os_create_or_update_crontab()` - Create/replace crontab from string
  - `radp_os_crontab_remove()` - Remove crontab entries by pattern
  - `radp_os_crontab_list()` - List user's crontab entries
- Add kernel module management (`os/08_kernel.sh`)
  - `radp_os_is_kernel_module_loaded()` - Check if kernel module is loaded
  - `radp_os_load_kernel_modules()` - Load kernel modules
  - `radp_os_configure_kernel_modules()` - Configure modules for boot
  - `radp_os_setup_kernel_modules()` - Configure and load kernel modules
- Add systemd service management (`os/09_service.sh`)
  - `radp_os_service_enable_start()` - Enable and start systemd service
  - `radp_os_service_restart()` - Restart systemd service
  - `radp_os_service_stop_disable()` - Stop and disable systemd service
  - `radp_os_service_configure_http_proxy()` - Configure HTTP proxy for service
  - `radp_os_service_remove_http_proxy()` - Remove HTTP proxy configuration
- Add user/group management (`os/10_user.sh`)
  - `radp_os_user_in_group()` - Check if user belongs to group
  - `radp_os_ensure_group()` - Ensure group exists
  - `radp_os_user_add_to_group()` - Add user to group
  - `radp_os_user_remove_from_group()` - Remove user from group
  - `radp_os_get_current_user()` - Get current username
- Add retry/wait utilities (`exec/02_retry.sh`)
  - `radp_wait_until()` - Wait until condition becomes true
  - `radp_retry()` - Retry command until success

### fix

- Fix CLI project bash completion not working when installed via package manager on Linux
  - Add completion files to scaffold packaging templates (spec, debian install)
  - Completions now installed to system directories for auto-loading
- Fix `radp-bf upgrade --force` not creating packaging directory when it doesn't exist
  - Now creates `packaging/` and all packaging files when `--force` is used
  - Without `--force`, shows hint message to use `--force` to create
- Fix `radp-bf upgrade` missing debian packaging files
  - Add `obs/debian/changelog`, `obs/debian/copyright`, `obs/debian/source/format` to upgrade list
  - Now creates all debian files that scaffold creates

## v0.6.32

### feat

- Add `gr_fw_app_config_path` variable for app bundled config path
  - New environment variable `GX_RADP_FW_APP_CONFIG_PATH` (set by launcher.sh)
  - Always points to `$RADP_APP_ROOT/src/main/shell/config` regardless of dev/install mode
  - Ensures app bundled `banner.txt` works in both development and installed modes
- Enhance banner art loading with 4-level priority:
  1. `radp_app_banner_art()` function (code-level customization)
  2. `$gr_fw_user_config_path/banner.txt` (user override, e.g., `~/.config/myapp/banner.txt`)
  3. `$gr_fw_app_config_path/banner.txt` (app bundled, shipped with app)
  4. `$gr_fw_banner_file` (framework default)
- Add `workflows` component to `radp-bf upgrade` command
  - Upgrades GitHub Actions workflows to latest templates
  - Supports 8 workflow files: release-prep, create-version-tag, update-spec-version, build-copr-package,
    build-obs-package, update-homebrew-tap, attach-release-packages, cleanup-branches
  - Uses checksum-based user modification detection (skips modified files unless `--force`)
  - Templates use new version scheme (`gr_app_version` in `version.sh`)
- Add `attach-release-packages.yml` workflow to scaffold
- Add `cleanup-branches.yml` workflow to scaffold
  - Automatically deletes stale `workflow/v*` branches older than 14 days
  - Supports scheduled (weekly) and manual trigger with configurable days and dry-run mode
- Refactor workflow templates to shared content generator functions (`radp_workflow_content_*`)
  - Both `radp-bf new` and `radp-bf upgrade workflows` now use the same templates
- Add `-q`/`--quiet` global option to disable banner and console log output
  - Useful for shell completion scripts and scripting use cases
  - Sets `GX_RADP_FW_BANNER_MODE=off` and `GX_RADP_FW_LOG_CONSOLE_ENABLED=false`
- Redesign `--config` global option with Docker info style output
  - New output format: App, Framework, Config, Settings, Log, Log Rolling sections
  - Add `--config --all` option to include extension configurations (default: hidden)
  - Supports `--config --json` and `--config --all --json` for JSON output
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
- Shell completion is automatically installed with all installation methods (Homebrew, dnf, apt, install.sh).

### fix

- Fix automap generating empty shell variables for null/empty YAML keys
  - Root cause: `radp.extend.xxx:` with no value was being converted to `gr_radp_extend_xxx=""`
  - Solution: skip null/empty values during variable generation in autoconfigure.sh
- Fix YAML config merge losing `radp.extend.*` keys when env-specific config exists
  - Root cause: bash nameref doesn't support chained pass-through
  - When `config.yaml` has `radp.extend.*` but `config-{env}.yaml` doesn't, the extend keys were lost after merge
  - Solution: pass original variable name (`$1`/`$2`) instead of nameref variable to merge functions
- Fix CLI argument parsing fails on macOS due to BSD getopt
- Fix passthrough mode intercepting `--help` instead of passing to underlying command
- Fix preflight no such file or directory error
- Fix IDE code completion not work
- Fix radp_os_install_pkgs
- Fix auto-generated ide hints file error on install-mode
- Fix zsh completion not working for subcommand arguments
  - Fix `radp-bf upgrade <tab>` not showing options/components
  - Fix generated zsh completion for CLI apps

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
