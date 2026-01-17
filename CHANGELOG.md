# CHANGELOG

## v0.4.0 - 2026-01-17

### feat
- 262087c distro libs optimize func radp_os_get_distro_pm and radp_os_install_pkgs
- 472e402 core libs add func radp_nr_arr_merge_unique
- 3ee2a31 os libs add func radp_os_is_pkg_installed and radp_os_install_pkgs
- 6320eda Optimize os libs func radp_os_get_distro_xx
- 43fb99d Add distro libs
- 320764f Optimize context completion
- efece04 rename func to __fw_os_get_distro_info
- 2259837 dynamic vars add gr_distro_xx and add func radp_os_get_distro_info
- 1a0636d remove pkg toolkit
- cc2697e Add func radp_io_get_path_abs
- e814902 Optimize func __fw_source_scripts
- 2b838aa Create toolkit skeleton

### chore
- 9878f08 format code
- 4730097 del .gitkeep

### docs
- 851b959 Update func comment for radp_io_get_path_abs
- fb9f726 Add func comment for radp_io_get_path_abs
- 7854476 update readme
- 899bdb4 update readme

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
