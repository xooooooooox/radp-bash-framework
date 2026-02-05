#!/usr/bin/env bash
# @cmd
# @desc Print framework path (init|launcher|root)
# @arg name! Path name to print
# @arg-values name init launcher root
# @example path init
# @example path launcher
# @example path root

# Note: This command is handled as fast-path in bin/radp-bf before framework loads
# This file exists only for help and completion metadata
cmd_path() {
  radp_cli_help_command "resolve-root"
  return 1
}

