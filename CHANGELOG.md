# CHANGELOG

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
