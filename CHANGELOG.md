# CHANGELOG

## v0.6.3 - 2026-01-27

### fix
- 967294e fix IDE code completion not work
- 6f6cd39 fix IDE code completion not work
- b6b46c1 fix IDE code completion not work
- 4826dcd fix radp_os_install_pkgs
- 34fbcdf fix IDE code completion not work

### chore
- e5edf8b add post-install message
- af44d32 update install and uninstall

### docs
- 56e6672 update installation
- 4262444 update installation

## v0.6.2 - 2026-01-27

### fix
- bc83a7a fix auto-generated ide hints file error on install-mode.

### docs
- ae700c2 update ClAUDE

## v0.6.1 - 2026-01-27

### feat
- fd96eb4 update cli scaffold default banner

### test
- 625a440 update cli scaffold example

## v0.6.0 - 2026-01-27

### refactor
- dc613b5 refactor run.sh to init.sh and refactor radp-bf options

## v0.5.3 - 2026-01-27

### feat
- dd43b6d update cli scaffold default banner
- 4c960c2 optimize cli scaffold dynamic user config path

### test
- de41968 update cli scaffold example

## v0.5.2 - 2026-01-27

### feat
- e602c24 add cli example
- 37ebc73 update cli scaffold .gitignore
- 2f64d2b Add example-cli
- 1e08544 update cli scaffold config.yaml

### fix
- d14fe96 fix cli completions not work for zsh

## v0.5.1 - 2026-01-27

### feat
- e2732ca Add global option in cli help

## v0.5.0 - 2026-01-27

### feat
- 09771bd Consistence cli args

## v0.4.28 - 2026-01-27

### feat
- 8b87f19 Support global option

## v0.4.27 - 2026-01-27

### feat
- 748b0ee Support customize banner
- 4abd0d2 Support customize banner

## v0.4.26 - 2026-01-27

### chore
- e47a4c1 Optimize install.sh

## v0.4.25 - 2026-01-27

### fix
- 50a3b44 fix default user config dir

## v0.4.24 - 2026-01-27

### fix
- 9dafe37 fix dynamic completion not work

## v0.4.23 - 2026-01-26

### feat
- 1bff70b refactor zsh completion to use wrapper functions for dynamic args/options

## v0.4.22 - 2026-01-26

### fix
- 013f7b1 remove trailing backslash from last _arguments parameter in zsh completion

## v0.4.21 - 2026-01-26

- TODO: no commits found; add summary manually.

## v0.4.20 - 2026-01-26

### fix
- 9f99a2f enhance completion logic with passthrough mode support

### docs
- 969fd0a document passthrough mode with examples

## v0.4.19 - 2026-01-26

### feat
- f218fea add passthrough mode support and `@meta` annotations

## v0.4.18 - 2026-01-26

### fix
- c3f991e prevent potential errors in argument index increment

## v0.4.17 - 2026-01-26

### fix
- 882c1d1 prevent loading external libraries if user lib path is unset

## v0.4.16 - 2026-01-26

### chore
- b87c920 update project dictionary to include "homelabctl"

### docs
- 459863c update IDE integration details in CLAUDE.md
- 7b9175b document IDE integration and completion hints

### refactor
- 4b50415 simplify user library path handling and improve scaffold initialization
- 25ec2f6 reorganize IDE completion hints handling and improve modularity

## v0.4.14 - 2026-01-26

### feat
- 58bf50e enhance IDE completion hints generation and command integration

## v0.4.13 - 2026-01-26

### feat
- 1a449d1 add file transfer and GitHub API utility modules

## v0.4.12 - 2026-01-26

### docs
- 777a047 provide complete configuration reference with examples
- 2e65b27 expand CONTRIBUTING.md and annotations documentation
- 8eea22b add detailed documentation for annotations, API, configuration, and installation
- 1495432 add CONTRIBUTING.md and restructure README files
- 2c219ea add utility libraries and naming conventions sections

### test
- c863485 add comprehensive test suite and helper utilities

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
