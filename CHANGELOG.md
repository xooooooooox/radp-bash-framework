# CHANGELOG

## v0.4.11 - 2026-01-26

### fix
- ddeca22 fix cli toolkit for subcmd group and shell completion not work well.

## v0.4.10 - 2026-01-25

### feat
- d62c42d improve subcommand matching and error handling

### docs
- 5fcc35b add CLI command discovery and nested command group documentation

## v0.4.9 - 2026-01-25

### feat
- d8b5d20 dynamically resolve cache path for system-wide installations
- f531294 Update cli generated scaffold

## v0.4.8 - 2026-01-25

### feat
- 3cde3d6 add package manager detection and installation support

### docs
- ff9466a improve installation guide and variable descriptions
- a075d86 add framework description to README and README_CN

## v0.4.7 - 2026-01-25

### chore
- 5677093 add shebang to scaffolded command scripts

## v0.4.6 - 2026-01-25

### refactor
- eaa0e46 improve argument handling and add empty input safeguards

## v0.4.5 - 2026-01-25

### feat
- ae9773c add global option parsing for verbose and debug modes

## v0.4.4 - 2026-01-25

### feat
- 78a484d add Homebrew support and improve scaffolding structure
- a35f6b1 add Homebrew formula for radp-bash-framework

## v0.4.3 - 2026-01-24

### refactor
- 86b7df1 update completion script paths for bash and zsh
- 2cba3c0 improve scaffolding and completion script handling

## v0.4.2 - 2026-01-24

### refactor
- 867e58a enhance CLI scaffolding

## v0.4.1 - 2026-01-24

### refactor
- 5303563 consolidate and rewrite CLI framework modules
- e4d0b16 consolidate and rewrite CLI framework modules

## v0.4.0 - 2026-01-17

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

## v0.3.6 - 2026-01-18

### feat

- Optimize completion

## v0.3.5 - 2026-01-17

### feat
- Support user completion
- Optimize func `__fw_source_scripts`
- Create toolkit skeleton
  - Add func `radp_io_get_path_abs`
  - Add func `radp_os_get_distro_xx`
  - Add func `radp_os_install_pkgs` and `radp_os_is_pkg_installed`
  - Add func `radp_nr_arr_merge_unique`

## v0.3.4 - 2026-01-12

### fix

- fix preflight_helper.sh no such file or directory

## v0.3.3 - 2026-01-12

### fix

- fix prefilght not work well.

## v0.3.2 - 2026-01-09

### fix

- fix failed to create user completion hint file

## v0.3.1 - 2026-01-09

### fix

- fix user custom config and lib completion not work

## v0.3.0 - 2026-01-08

### feat

- Optimize logger
  - Add radp_log_raw func
  - Optimize banner print
  - Support disable/enable console log and logfile
  - Refactor log config var name, `radp.fw.log.file` to `radp.fw.log.file.name`

## v0.2.4 - 2026-01-08

### chore
- Support multi install/upgrade method.
- Add Github workflow
  - Support auto-update version and changelog before release.
  - Support auto-create a valid tag.
  - Support auto-build copr/obs package.
  - Support auto-upload pre-built package to release assets.
