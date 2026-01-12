# CHANGELOG

## v0.3.3 - 2026-01-12

### feat
- cf16306 optimize requirements script
- 5880ce4 only log when requirements not satisfied
- 8534067 Bash tarball downloads show progress bar
- 163b365 Add necessary log
- 34d345c support disable/enable log via environment variable
- 090b6a1 auto install unsatified requirements
- 91d6993 auto install bash and yq if not installed

### fix
- 61a0c90 fix cento7 EOL yum
- f7c973b fix __bash_bin unbound variable

### chore
- 5e6f209 remove todo

### refactor
- c644943 rename require_common.sh to preflight_helper.sh
- d9fef4d refator require_xx.sh
- 35e2fd3 refactor common login to require_common.sh in requjire_xx.sh
- 7b4834a Optimize sudo

### other
- 88dc498 format code

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
