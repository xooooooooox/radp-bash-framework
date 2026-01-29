# CHANGELOG

## v0.6.8

### feat
- Add dry-run mode support in exec toolkit (`04_dry_run.sh`)
    - `radp_set_dry_run()` - Enable/disable dry-run mode
    - `radp_is_dry_run()` - Check if dry-run mode is enabled
    - `radp_exec()` - Execute command or log in dry-run mode
    - `radp_exec_sudo()` - Execute with sudo or log in dry-run mode
    - `radp_dry_run_skip()` - Check and log for complex operations
- Add `radp_get_install_version()` helper function for accurate version display
- Add `radp_get_fw_install_version()` helper function for framework version
- Generate `.install-version` file during manual installation
- Update scaffold template to use version helper functions in banner

This allows applications installed via `--ref main` or `--ref <branch>` to display
accurate version info (e.g., `v0.6.5+main`) instead of the hardcoded source version.


## v0.6.7

### fix
- Fix passthrough mode intercepting `--help` instead of passing to underlying command

## v0.6.6

### fix
- Fix passthrough mode intercepting `--help` instead of passing to underlying command

### refactor

- refactor version mechanism

## v0.6.5

### fix

- fix preflight
- fix installer

## v0.6.4

### fix

- fix IDE code completion not work

## v0.6.3

### fix

- fix radp_os_install_pkgs
- fix IDE code completion not work

### chore
- add post-install message
- update install and uninstall

### docs

- update installation

## v0.6.2

### fix

- fix auto-generated ide hints file error on install-mode.

## v0.6.1

### feat

- update cli scaffold default banner

### test

- update cli scaffold example

## v0.6.0

### refactor

- refactor run.sh to init.sh and refactor radp-bf options

## v0.5.3

### feat

- update cli scaffold default banner
- optimize cli scaffold dynamic user config path

### test

- update cli scaffold example

## v0.5.2

### feat

- add cli example
- update cli scaffold .gitignore
- Add example-cli
- update cli scaffold config.yaml

### fix
- d14fe96 fix cli completions not work for zsh

## v0.5.1

### feat
- e2732ca Add global option in cli help

## v0.5.0

### feat
- 09771bd Consistence cli args

## v0.4.28

### feat

- Support global option

## v0.4.27

### feat

- Support customize banner

## v0.4.26

### chore

- Optimize install.sh

## v0.4.25

### fix

- fix default user config dir

## v0.4.24

### fix

- fix dynamic completion not work

## v0.4.23

### feat

- refactor zsh completion to use wrapper functions for dynamic args/options

## v0.4.22

### fix
- 013f7b1 remove trailing backslash from last _arguments parameter in zsh completion

## v0.4.21

- TODO: no commits found; add summary manually.

## v0.4.20

### fix
- 9f99a2f enhance completion logic with passthrough mode support

### docs
- 969fd0a document passthrough mode with examples

## v0.4.19

### feat

- add passthrough mode support and `@meta` annotations

## v0.4.18

### fix
- c3f991e prevent potential errors in argument index increment

## v0.4.17

### fix
- 882c1d1 prevent loading external libraries if user lib path is unset

## v0.4.16

### chore
- b87c920 update project dictionary to include "homelabctl"

### docs
- 459863c update IDE integration details in CLAUDE.md
- 7b9175b document IDE integration and completion hints

### refactor
- 4b50415 simplify user library path handling and improve scaffold initialization
- 25ec2f6 reorganize IDE completion hints handling and improve modularity

## v0.4.14

### feat
- 58bf50e enhance IDE completion hints generation and command integration

## v0.4.13

### feat
- 1a449d1 add file transfer and GitHub API utility modules

## v0.4.12

### docs

- provide complete configuration reference with examples
- expand CONTRIBUTING.md and annotations documentation
- add detailed documentation for annotations, API, configuration, and installation
- add CONTRIBUTING.md and restructure README files
- add utility libraries and naming conventions sections

### test

- add comprehensive test suite and helper utilities

## v0.4.11

### fix

- fix cli toolkit for subcmd group and shell completion not work well.

## v0.4.10

### feat

- improve subcommand matching and error handling

### docs
- add CLI command discovery and nested command group documentation

## v0.4.9

### feat

- dynamically resolve cache path for system-wide installations
- Update cli generated scaffold

## v0.4.8

### feat

- add package manager detection and installation support

### docs

- improve installation guide and variable descriptions
- add framework description to README and README_CN

## v0.4.7 - 2026-01-25

### chore

- add shebang to scaffolded command scripts

## v0.4.6

### refactor

- improve argument handling and add empty input safeguards

## v0.4.5

### feat

- add global option parsing for verbose and debug modes

## v0.4.4

### feat
- add Homebrew support and improve scaffolding structure
- add Homebrew formula for radp-bash-framework

## v0.4.3

### refactor

- update completion script paths for bash and zsh
- improve scaffolding and completion script handling

## v0.4.2

### refactor

- 867e58a enhance CLI scaffolding

## v0.4.1

### refactor

- consolidate and rewrite CLI framework modules
- consolidate and rewrite CLI framework modules

## v0.4.0

### feat

- distro libs optimize func radp_os_get_distro_pm and radp_os_install_pkgs
- core libs add func radp_nr_arr_merge_unique
- os libs add func radp_os_is_pkg_installed and radp_os_install_pkgs
- Optimize os libs func radp_os_get_distro_xx
- Add distro libs
- Optimize context completion
- rename func to __fw_os_get_distro_info
- dynamic vars add gr_distro_xx and add func radp_os_get_distro_info
- remove pkg toolkit
- Add func radp_io_get_path_abs
- Optimize func __fw_source_scripts
- Create toolkit skeleton

## v0.3.6

### feat

- Optimize completion

## v0.3.5

### feat
- Support user completion
- Optimize func `__fw_source_scripts`
- Create toolkit skeleton
  - Add func `radp_io_get_path_abs`
  - Add func `radp_os_get_distro_xx`
  - Add func `radp_os_install_pkgs` and `radp_os_is_pkg_installed`
  - Add func `radp_nr_arr_merge_unique`

## v0.3.4

### fix

- fix preflight_helper.sh no such file or directory

## v0.3.3

### fix

- fix prefilght not work well.

## v0.3.2

### fix

- fix failed to create user completion hint file

## v0.3.1

### fix

- fix user custom config and lib completion not work

## v0.3.0

### feat

- Optimize logger
  - Add radp_log_raw func
  - Optimize banner print
  - Support disable/enable console log and logfile
  - Refactor log config var name, `radp.fw.log.file` to `radp.fw.log.file.name`

## v0.2.4

### chore
- Support multi install/upgrade method.
- Add Github workflow
  - Support auto-update version and changelog before release.
  - Support auto-create a valid tag.
  - Support auto-build copr/obs package.
  - Support auto-upload pre-built package to release assets.
