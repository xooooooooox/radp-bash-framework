#!/usr/bin/env bash
# @cmd
# @desc Resolve project root from entry script path
# @arg script_path! Path to entry script
# @example resolve-root ./bin/myapp
# @example resolve-root /usr/local/bin/myapp

# Note: This command is handled as fast-path in bin/radp-bf before framework loads
# This file exists only for help and completion metadata
cmd_resolve_root() {
  radp_cli_help_command "resolve-root"
  return 1
}
