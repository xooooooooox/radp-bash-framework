#!/usr/bin/env bash
# @cmd
# @desc Upgrade an existing CLI project to latest scaffold
# @arg dir Target directory (default: current directory)
# @arg components~ Components to upgrade (entry, ide, gitignore, version, workflows, packaging, globals, all)
# @arg-values components entry ide gitignore version workflows packaging globals all
# @option --dry-run Show changes without applying
# @option --force Overwrite user-modified files
# @option --diff Show file differences
# @example upgrade
# @example upgrade ./my-cli --dry-run
# @example upgrade . entry ide

cmd_upgrade() {
  radp_cli_upgrade "$@"
}
